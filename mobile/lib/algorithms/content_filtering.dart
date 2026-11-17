import 'dart:math';
import '../models/attraction.dart';
import 'haversine.dart';

double _cosine(List<double> a, List<double> b) {
  double dot = 0, na = 0, nb = 0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return na == 0 || nb == 0 ? 0 : dot / (sqrt(na) * sqrt(nb));
}

Set<String> itemTags(Attraction a) => {...a.tags, a.category, a.group};

/// Turist baholaridan teglar bo'yicha afzallik: 5★ -> +1, 3★ -> 0, 1★ -> -1 (o'rtacha).
Map<String, double> tagPreferences(List<Attraction> items, Map<int, int> ratings) {
  final sum = <String, double>{}, n = <String, int>{};
  for (final a in items) {
    final r = ratings[a.id];
    if (r == null) continue;
    for (final t in itemTags(a)) {
      sum[t] = (sum[t] ?? 0) + (r - 3) / 2;
      n[t] = (n[t] ?? 0) + 1;
    }
  }
  return {for (final t in sum.keys) t: sum[t]! / n[t]!};
}

/// Byudjet darajasi: 0 = past, 1 = o'rtacha, 2 = yuqori.
const budgetLimitUsd = [10.0, 40.0, double.infinity];

/// Kontentga asoslangan filtrlash (sun'iy intellekt tavsiya moduli):
/// qiziqishlar vektori bilan joy teglari orasidagi kosinus o'xshashligi + reyting + yaqinlik
/// + turist baholaridan o'rganilgan afzallik; byudjetdan qimmat joylar pastga tushadi.
List<Attraction> recommend(List<Attraction> items, Set<String> interests,
    {double? lat, double? lon, Map<int, int> ratings = const {}, int? budget, int limit = 100}) {
  final prefs = tagPreferences(items, ratings);
  final vocab = <String>{...interests, for (final a in items) ...itemTags(a)}.toList()..sort();
  List<double> vec(Set<String> tags) => [for (final t in vocab) tags.contains(t) ? 1.0 : 0.0];
  final user = vec(interests);
  for (final a in items) {
    final tags = itemTags(a);
    final sim = _cosine(user, vec(tags));
    var prox = 0.0;
    a.distanceKm = null;
    if (lat != null && lon != null) {
      a.distanceKm = haversineKm(lat, lon, a.lat, a.lon);
      prox = 1 / (1 + a.distanceKm! / 30);
    }
    final known = tags.where(prefs.containsKey).map((t) => prefs[t]!).toList();
    final pref = known.isEmpty ? 0.0 : known.reduce((x, y) => x + y) / known.length;
    final rating = (ratings[a.id] ?? a.rating).toDouble();
    var score = 0.55 * sim + 0.15 * rating / 5 + 0.15 * prox + 0.15 * (pref + 1) / 2;
    final over = budget != null && a.costUsd > budgetLimitUsd[budget];
    if (over) score *= 0.6;
    a.score = score;
    a.reasons = [
      if (sim >= 0.5) 'why_interest',
      if (rating >= 4.6) 'why_rating',
      if (a.distanceKm != null && a.distanceKm! < 15) 'why_near',
      if (pref > 0.2) 'why_liked',
      if (over) 'why_expensive',
    ];
  }
  final ranked = [...items]..sort((x, y) => y.score.compareTo(x.score));
  return ranked.take(limit).toList();
}
