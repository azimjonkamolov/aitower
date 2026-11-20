import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../algorithms/optimizer.dart';

/// Haqiqiy yo'llar bo'yicha masofa, vaqt va yo'l chizig'i — bepul OpenStreetMap (OSRM) xizmati orqali.
/// Internet bo'lmasa null qaytaradi va ilova taxminiy (to'g'ri chiziq + A*) hisobga qaytadi.
class RoadRouter {
  static const _ua = {'User-Agent': 'AISmartTourism/2.2 (uz.tourism.ai_smart_tourism)'};
  static const _timeout = Duration(seconds: 10);
  static final _geomCache = <String, List<LatLng>>{};

  static String _base(Transport t) =>
      'https://routing.openstreetmap.de/${t == Transport.walk ? 'routed-foot' : 'routed-car'}';
  static String _coords(List<LatLng> p) =>
      p.map((e) => '${e.longitude.toStringAsFixed(5)},${e.latitude.toStringAsFixed(5)}').join(';');

  /// Barcha nuqtalar orasidagi yo'l masofasi (km) va vaqti (daq, tirbandliksiz).
  static Future<RoadMatrix?> table(List<LatLng> pts, Transport t) async {
    if (pts.length < 2) return null;
    try {
      final r = await http
          .get(Uri.parse('${_base(t)}/table/v1/driving/${_coords(pts)}?annotations=distance,duration'), headers: _ua)
          .timeout(_timeout);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      if (j['code'] != 'Ok') return null;
      List<List<double>> m(String k, double scale) =>
          [for (final row in j[k] as List) [for (final v in row as List) v == null ? -1.0 : (v as num) / scale]];
      return RoadMatrix(pts, m('distances', 1000), m('durations', 60));
    } catch (_) {
      return null;
    }
  }

  /// Ikki nuqta orasidagi yo'l chizig'i.
  static Future<List<LatLng>?> geometry(LatLng a, LatLng b, Transport t) async {
    final key = '${t.name}|${_coords([a, b])}';
    if (_geomCache.containsKey(key)) return _geomCache[key];
    try {
      final r = await http
          .get(Uri.parse('${_base(t)}/route/v1/driving/${_coords([a, b])}?overview=full&geometries=polyline'), headers: _ua)
          .timeout(_timeout);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      if (j['code'] != 'Ok') return null;
      return _geomCache[key] = decodePolyline(j['routes'][0]['geometry'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Google "encoded polyline" formatini nuqtalarga aylantiradi (aniqlik 1e-5).
  static List<LatLng> decodePolyline(String s) {
    final out = <LatLng>[];
    var i = 0, lat = 0, lon = 0;
    int next() {
      var result = 0, shift = 0, b = 0;
      do {
        b = s.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      // ~x o'rniga -x-1: web (JavaScript) versiyada ~ ishorasiz son qaytaradi va nuqtalar "uchib ketadi"
      return (result & 1) != 0 ? -(result >> 1) - 1 : result >> 1;
    }

    while (i < s.length) {
      lat += next();
      lon += next();
      out.add(LatLng(lat / 1e5, lon / 1e5));
    }
    return out;
  }
}
