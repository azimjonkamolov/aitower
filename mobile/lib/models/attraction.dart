class Attraction {
  final int id;
  String city, category;
  List<String> tags;
  Map<String, String> name, description;
  double lat, lon, rating, costUsd;
  int visitMinutes;
  String hours; // "09:00-18:00", "00:00-24:00" = kun bo'yi ochiq
  List<int> closedDays; // 1 = dushanba ... 7 = yakshanba
  double score = 0;
  double? distanceKm;
  List<String> reasons = [];
  String? image, credit; // assets/photos.json dan: fayl nomi va muallif/litsenziya

  Attraction.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        city = j['city'],
        category = j['category'],
        tags = List<String>.from(j['tags'] ?? const []),
        name = Map<String, String>.from(j['name']),
        description = Map<String, String>.from(j['description'] ?? const {}),
        lat = (j['lat'] as num).toDouble(),
        lon = (j['lon'] as num).toDouble(),
        rating = (j['rating'] as num).toDouble(),
        costUsd = (j['cost_usd'] as num).toDouble(),
        visitMinutes = (j['visit_minutes'] as num).toInt(),
        hours = j['hours'] ?? '00:00-24:00',
        closedDays = List<int>.from(j['closed_days'] ?? const []);

  Map<String, dynamic> toJson() => {
        'id': id,
        'city': city,
        'category': category,
        'tags': tags,
        'name': name,
        'description': description,
        'lat': lat,
        'lon': lon,
        'rating': rating,
        'cost_usd': costUsd,
        'visit_minutes': visitMinutes,
        'hours': hours,
        'closed_days': closedDays,
      };

  String nameIn(String lang) => (name[lang]?.isNotEmpty ?? false) ? name[lang]! : (name['uz'] ?? name.values.first);
  String descriptionIn(String lang) =>
      (description[lang]?.isNotEmpty ?? false) ? description[lang]! : (description['uz'] ?? '');

  /// Saytdagi to'rtta guruh: ziyorat, tarix, tabiat, mehmon (mehmonxona + taom + dam olish).
  String get group => const {'mehmonxona', 'taom', 'dam'}.contains(category) ? 'mehmon' : category;
  bool get isHotel => category == 'mehmonxona';

  static int parseHm(String s) {
    final p = s.trim().split(':');
    return int.parse(p[0]) * 60 + (p.length > 1 ? int.parse(p[1]) : 0);
  }

  static bool validHours(String h) => RegExp(r'^\d{1,2}:\d{2}-\d{1,2}:\d{2}$').hasMatch(h.trim());

  int get openMin => parseHm(hours.split('-')[0]);
  int get closeMin => parseHm(hours.split('-')[1]);
  bool get alwaysOpen => openMin == 0 && closeMin >= 1440 && closedDays.isEmpty;
  bool openOnDay(DateTime d) => !closedDays.contains(d.weekday);

  bool isOpenAt(DateTime t) {
    if (!openOnDay(t)) return false;
    final m = t.hour * 60 + t.minute;
    return m >= openMin && m < closeMin;
  }
}
