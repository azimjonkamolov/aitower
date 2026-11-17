/// Yo'l bo'yidagi foydali joy (OpenStreetMap'dan): yoqilg'i quyish, ovqatlanish yoki bozor.
class RoadsideStop {
  final String kind; // 'fuel' | 'food' | 'bazaar'
  final String? name, hours;
  final double lat, lon;
  final List<String> fuels; // metan, propan, benzin, dizel
  double alongKm = 0, offKm = 0; // marshrut bo'ylab qayerda va undan qancha uzoqda
  int afterStop = 0;

  RoadsideStop.fromJson(Map<String, dynamic> j)
      : kind = j['k'],
        name = j['n'],
        hours = j['h'],
        lat = (j['lat'] as num).toDouble(),
        lon = (j['lon'] as num).toDouble(),
        fuels = List<String>.from(j['f'] ?? const []);
}
