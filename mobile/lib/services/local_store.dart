import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attraction.dart';

/// Telefondagi ma'lumotlar: baholar, sharhlar, statistika va administrator o'zgartirishlari.
/// Server ulanganda shu ma'lumotlar serverga yuboriladi.
class LocalStore {
  static final LocalStore i = LocalStore._();
  LocalStore._();

  late SharedPreferences _p;
  Map<String, dynamic> _d = {};

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final s = _p.getString('store_v1');
    _d = s == null ? {} : Map<String, dynamic>.from(jsonDecode(s));
  }

  void _save() => _p.setString('store_v1', jsonEncode(_d));
  Map<String, dynamic> _map(String k) => (_d[k] ??= <String, dynamic>{}) as Map<String, dynamic>;
  List _list(String k) => (_d[k] ??= []) as List;
  void _inc(String k, String key, [int by = 1]) {
    final m = _map(k);
    m[key] = ((m[key] ?? 0) as num).toInt() + by;
  }

  // --- Baholar va sharhlar ---
  int? ratingOf(int id) => (_map('ratings')['$id'] as num?)?.toInt();
  Map<int, int> get ratings => _map('ratings').map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
  void rate(int id, int stars) {
    _map('ratings')['$id'] = stars;
    _save();
  }

  List<Map<String, dynamic>> commentsOf(int id) =>
      List<Map<String, dynamic>>.from((_map('comments')['$id'] ?? const []) as List);
  void addComment(int id, String text) {
    final m = _map('comments');
    m['$id'] = [...(m['$id'] ?? const []) as List, {'text': text, 'date': DateTime.now().toIso8601String()}];
    _save();
  }

  /// Barcha sharhlar: (joy id, matn, sana), eng yangisi birinchi.
  List<(int, String, DateTime)> get allComments {
    final out = <(int, String, DateTime)>[];
    _map('comments').forEach((k, l) {
      for (final c in l as List) {
        out.add((int.parse(k), c['text'] as String, DateTime.parse(c['date'] as String)));
      }
    });
    out.sort((a, b) => b.$3.compareTo(a.$3));
    return out;
  }

  // --- Statistika ---
  void recordSession() {
    _inc('stats', 'sessions');
    _inc('usage_hours', '${DateTime.now().hour}');
    _save();
  }

  void recordView(int id) {
    _inc('views', '$id');
    _save();
  }

  void recordRoute(int stops) {
    _inc('stats', 'routes');
    _inc('stats', 'route_stops', stops);
    _save();
  }

  void recordVisit(int id) {
    _inc('visits', '$id');
    _save();
  }

  void recordReroute() {
    _inc('stats', 'reroutes');
    _save();
  }

  void recordQuestion() {
    _inc('stats', 'questions');
    _save();
  }

  void recordFeedback(bool good) {
    _inc('stats', good ? 'rec_up' : 'rec_down');
    _save();
  }

  int stat(String k) => ((_map('stats')[k] ?? 0) as num).toInt();
  Map<int, int> counts(String k) => _map(k).map((key, v) => MapEntry(int.parse(key), (v as num).toInt()));

  void clearStats() {
    for (final k in ['stats', 'usage_hours', 'views', 'visits']) {
      _d.remove(k);
    }
    _save();
  }

  // --- Administrator ---
  String get pin => (_d['pin'] ?? '1234') as String;
  set pin(String v) {
    _d['pin'] = v;
    _save();
  }

  Map<String, dynamic> get overrides => _map('overrides');
  List<int> get deleted => List<int>.from(_list('deleted'));

  void savePlace(Attraction a) {
    overrides['${a.id}'] = a.toJson();
    _list('deleted').remove(a.id);
    _save();
  }

  void deletePlace(int id) {
    overrides.remove('$id');
    final l = _list('deleted');
    if (!l.contains(id)) l.add(id);
    _save();
  }

  int nextId(Iterable<int> used) => [999, ...used].reduce(max) + 1;
}
