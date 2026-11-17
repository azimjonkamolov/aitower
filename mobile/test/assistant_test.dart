import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_smart_tourism/algorithms/optimizer.dart';
import 'package:ai_smart_tourism/models/attraction.dart';
import 'package:ai_smart_tourism/services/assistant.dart';

List<Attraction> load() => (jsonDecode(File('assets/attractions.json').readAsStringSync()) as List)
    .map((e) => Attraction.fromJson(e))
    .toList();

void main() {
  final places = load();
  final bot = Assistant(places, lat: 39.056, lon: 66.83);

  test('opening hours question names the place', () {
    expect(bot.answer('Oqsaroy qachon ochiq?'), contains('Oqsaroy'));
    expect(bot.answer('Когда открыт Ак-Сарай?'), contains('08:00'));
  });
  test('city question lists that city', () {
    final a = bot.answer('Qarshida nima bor?');
    expect(a, contains('Odina'));
  });
  test('nearby restaurants', () {
    final a = bot.answer('Yaqin atrofda restoran bormi?');
    expect(a, contains('Sezam'));
  });
  test('food, transport and festival answers', () {
    expect(bot.answer('Qashqadaryoda qanday milliy taomlar bor?'), contains('tandir'));
    expect(bot.answer('Toshkentdan qanday borish mumkin?'), contains('Afrosiyob'));
    expect(bot.answer('Qanday festivallar bor?'), contains('Anor'));
  });
  test('new places from the presentation are found', () {
    expect(bot.answer('Maydanak rasadxonasi haqida'), contains('2000'));
    expect(bot.answer('Suvtushar haqida ayting'), contains('80'));
  });
  test('route skips nothing in daytime, splits long trips', () {
    final pick = places.where((p) => [1, 2, 5, 16, 9, 14].contains(p.id)).toList();
    final plan = planRoute(pick, RouteOptions(start: DateTime(2026, 11, 10, 9)), startLat: 39.056, startLon: 66.83);
    expect(plan.allStops.length + plan.skipped.length, pick.length);
    for (final s in plan.allStops) {
      expect(s.place.isOpenAt(s.start), isTrue, reason: '${s.place.name['uz']} at ${s.start}');
    }
  });
  test('nearby place is visited first (Qarshi start: Odina before Oqsaroy)', () {
    final pick = places.where((p) => [1, 9].contains(p.id)).toList();
    final plan = planRoute(pick, RouteOptions(start: DateTime(2026, 11, 11, 9)), startLat: 38.86, startLon: 65.799);
    expect(plan.allStops.first.place.id, 9);
  });
  test('ready-made routes fit in their promised number of days', () {
    final tours = (jsonDecode(File('assets/tours.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
    final byId = {for (final p in places) p.id: p};
    for (final t in tours) {
      final pick = [for (final id in t['places'] as List) byId[id]!];
      final mode = Transport.values.byName(t['transport']);
      final plan = planRoute(pick, RouteOptions(start: DateTime(2026, 11, 11, 9), transport: mode));
      expect(plan.skipped, isEmpty, reason: '${t['id']} skipped ${plan.skipped.map((s) => s.place.name['uz'])}');
      expect(plan.days.length, lessThanOrEqualTo(t['days'] as int), reason: '${t['id']} needs ${plan.days.length} days');
    }
  });
  test('Odina is closed on Monday so it moves to another day', () {
    final odina = places.firstWhere((p) => p.id == 9);
    final plan = planRoute([odina], RouteOptions(start: DateTime(2026, 11, 9, 9))); // 9 Nov 2026 = Monday
    expect(plan.allStops.single.start.weekday, isNot(1));
  });
  test('budget drops expensive places', () {
    final pick = places.where((p) => [1, 2, 4, 9].contains(p.id)).toList();
    final plan = planRoute(pick, RouteOptions(start: DateTime(2026, 11, 10, 9), budget: 4));
    expect(plan.skipped.where((s) => s.reason == 'budget'), isNotEmpty);
    expect(plan.totalCost, lessThanOrEqualTo(4));
  });
}
