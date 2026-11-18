import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attraction.dart';
import '../models/roadside_stop.dart';
import '../models/tour.dart';
import 'local_store.dart';

/// Ilova serversiz ishlaydi: joylar APK ichidagi assets/attractions.json dan o'qiladi,
/// administrator o'zgartirishlari (LocalStore) ustidan qo'llanadi.
class DataService {
  static List<Attraction>? _cache;
  static void invalidate() => _cache = null;

  Future<List<Attraction>> attractions() async {
    if (_cache != null) return _cache!;
    final base = (jsonDecode(await rootBundle.loadString('assets/attractions.json')) as List)
        .cast<Map<String, dynamic>>();
    final byId = {for (final j in base) j['id'] as int: j};
    LocalStore.i.overrides.forEach((k, v) => byId[int.parse(k)] = Map<String, dynamic>.from(v));
    for (final id in LocalStore.i.deleted) {
      byId.remove(id);
    }
    final photos = Map<String, dynamic>.from(jsonDecode(await rootBundle.loadString('assets/photos.json')));
    // Demo rasmlar (faqat shu kompyuterda, GitHubga yuklanmaydi): bo'lsa ustidan qo'shiladi
    try {
      photos.addAll(Map<String, dynamic>.from(jsonDecode(await rootBundle.loadString('assets/photos_local/photos.json'))));
    } catch (_) {}
    final list = byId.values.map(Attraction.fromJson).toList()..sort((a, b) => a.id.compareTo(b.id));
    for (final a in list) {
      final p = photos['${a.id}'];
      if (p != null) {
        a.image = p['file'];
        a.credit = [p['author'], p['license'], p['source_name'] ?? 'Wikimedia Commons']
            .where((x) => x != null && '$x'.isNotEmpty)
            .join(' · ');
      }
    }
    return _cache = list;
  }

  static List<RoadsideStop>? _stops;
  static List<Tour>? _tours;

  Future<List<Tour>> tours() async => _tours ??=
      (jsonDecode(await rootBundle.loadString('assets/tours.json')) as List).map((e) => Tour.fromJson(e)).toList();

  /// Yoqilg'i quyish shoxobchalari, ovqatlanish joylari va bozorlar (assets/stops.json, OSM).
  Future<List<RoadsideStop>> roadsideStops() async => _stops ??=
      (jsonDecode(await rootBundle.loadString('assets/stops.json')) as List).map((e) => RoadsideStop.fromJson(e)).toList();

  Future<Position?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
      // Avval telefon eslab qolgan oxirgi joylashuv (darhol), bo'lmasa yangi o'lchov.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && DateTime.now().difference(last.timestamp).inMinutes < 2) return last;
      return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)));
    } catch (_) {
      return null;
    }
  }
}
