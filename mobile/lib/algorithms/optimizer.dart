import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/attraction.dart';
import '../models/route_plan.dart';
import 'astar.dart';
import 'genetic_algorithm.dart';
import 'haversine.dart';

enum Strategy { shortest, fastest, balanced }

enum Transport { walk, car, taxi }

class RouteOptions {
  final Strategy strategy;
  final Transport transport;
  final double? budget; // kirish chiptalari uchun maksimal $
  final DateTime start;
  final int dayStart, dayEnd; // kun oynasi, yarim tundan beri daqiqalarda

  const RouteOptions({
    this.strategy = Strategy.balanced,
    this.transport = Transport.car,
    this.budget,
    required this.start,
    this.dayStart = 9 * 60,
    this.dayEnd = 20 * 60,
  });

  RouteOptions withStart(DateTime s) =>
      RouteOptions(strategy: strategy, transport: transport, budget: budget, start: s, dayStart: dayStart, dayEnd: dayEnd);
}

const walkMaxKm = 3.0; // undan uzoq bo'lsa piyoda o'rniga taksi
const taxiUsdPerKm = 0.25, carUsdPerKm = 0.08;

/// Tirbandlik modeli (taxminiy): tig'iz soatlarda yo'l sekinlashadi.
double trafficFactor(DateTime t, Transport m) {
  if (m == Transport.walk) return 1.0;
  final h = t.hour;
  if (h >= 7 && h < 10) return 1.5;
  if (h >= 17 && h < 20) return 1.6;
  if (h >= 10 && h < 17) return 1.2;
  return 1.0;
}

class Leg {
  final double km, minutes, cost;
  final Transport by;
  const Leg(this.km, this.minutes, this.cost, this.by);
  static const zero = Leg(0, 0, 0, Transport.walk);
}

/// Haqiqiy yo'llar jadvali (OSRM): nuqtalar orasidagi km va tirbandliksiz daqiqalar.
class RoadMatrix {
  final List<List<double>> km, minutes;
  final Map<String, int> _index;
  RoadMatrix(List<LatLng> pts, this.km, this.minutes)
      : _index = {for (var i = 0; i < pts.length; i++) _key(pts[i].latitude, pts[i].longitude): i};
  static String _key(double lat, double lon) => '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}';

  /// (km, daqiqa) yoki null — agar nuqta jadvalda bo'lmasa yoki yo'l topilmasa.
  (double, double)? lookup(List<double> a, List<double> b) {
    final i = _index[_key(a[0], a[1])], j = _index[_key(b[0], b[1])];
    if (i == null || j == null || km[i][j] < 0 || minutes[i][j] < 0) return null;
    return (km[i][j], minutes[i][j]);
  }
}

Leg legFor(double km, DateTime at, Transport m, {double? baseMinutes}) {
  final by = m == Transport.walk && km > walkMaxKm ? Transport.taxi : m;
  final f = trafficFactor(at, by);
  final double minutes;
  if (baseMinutes != null && by == m) {
    // haqiqiy yo'l vaqti (OSRM) × tig'iz soat koeffitsienti
    minutes = baseMinutes * (km > 60 ? 1 + (f - 1) / 3 : f);
  } else {
    final speed = by == Transport.walk ? 4.5 : (km > 60 ? 70.0 : 40.0);
    minutes = km / speed * 60 * (km > 60 ? 1 + (f - 1) / 3 : f);
  }
  final cost = switch (by) { Transport.taxi => km * taxiUsdPerKm, Transport.car => km * carUsdPerKm, _ => 0.0 };
  return Leg(km, minutes, cost, by);
}

/// Joy ochiq bo'lgan va tashrifga vaqt yetadigan eng yaqin vaqt (7 kun ichida).
DateTime? nextVisitStart(Attraction a, DateTime t, RouteOptions opt) {
  final open = a.isHotel ? 0 : max(a.openMin, opt.dayStart);
  final close = a.isHotel ? 24 * 60 : min(a.closeMin, opt.dayEnd);
  for (var d = 0; d < 7; d++) {
    final date = DateTime(t.year, t.month, t.day + d);
    if (!a.openOnDay(date)) continue;
    final startMin = d == 0 ? max(t.hour * 60 + t.minute, open) : open;
    if (startMin + a.visitMinutes <= close) return date.add(Duration(minutes: startMin));
  }
  return null;
}

DateTime _fitToDay(DateTime t, RouteOptions opt) {
  final m = t.hour * 60 + t.minute;
  if (m < opt.dayStart) return DateTime(t.year, t.month, t.day).add(Duration(minutes: opt.dayStart));
  if (m > opt.dayEnd - 60) return DateTime(t.year, t.month, t.day + 1).add(Duration(minutes: opt.dayStart));
  return t;
}

/// Optimal marshrut: GA tashrif tartibini topadi (strategiya bo'yicha masofa / vaqt / muvozanat),
/// A* har bir bo'g'in yo'lini hisoblaydi, so'ng ish vaqtlari, tirbandlik va kun oynasi
/// hisobga olinib kunlarga bo'linadi. Ochilmaydigan yoki byudjetdan oshgan joylar chetga chiqariladi.
RoutePlan planRoute(List<Attraction> items, RouteOptions opt, {double? startLat, double? startLon, RoadMatrix? roads}) {
  final skipped = <Skipped>[];
  var chosen = [...items];
  if (opt.budget != null) {
    chosen.sort((a, b) => b.score.compareTo(a.score));
    var spent = 0.0;
    final keep = <Attraction>[];
    for (final a in chosen) {
      if (a.isHotel || spent + a.costUsd <= opt.budget!) {
        keep.add(a);
        if (!a.isHotel) spent += a.costUsd;
      } else {
        skipped.add(Skipped(a, 'budget'));
      }
    }
    chosen = keep;
  }
  if (chosen.isEmpty) return RoutePlan([], skipped, opt);

  final hasStart = startLat != null && startLon != null;
  final coords = [
    if (hasStart) [startLat, startLon],
    for (final a in chosen) [a.lat, a.lon],
  ];
  final off = hasStart ? 1 : 0;
  // Yo'l masofasi: internet bo'lsa haqiqiy yo'llar (OSRM), bo'lmasa to'g'ri chiziq × 1.3
  final straight = distanceMatrix(coords);
  final n = coords.length;
  final roadKm = List.generate(n, (i) => List.generate(n, (j) => roads?.lookup(coords[i], coords[j])?.$1 ?? straight[i][j] * roadFactor));
  final roadMin = List.generate(n, (i) => List.generate(n, (j) => roads?.lookup(coords[i], coords[j])?.$2));
  double edgeAt(int i, int j) {
    final km = roadKm[i][j];
    final t = legFor(km, opt.start, opt.transport, baseMinutes: roadMin[i][j]).minutes;
    return switch (opt.strategy) {
      Strategy.shortest => km,
      Strategy.fastest => t,
      Strategy.balanced => 0.5 * km + 0.5 * t * 40 / 60,
    };
  }

  final order = geneticTsp([for (var i = 0; i < n; i++) [for (var j = 0; j < n; j++) edgeAt(i, j)]]);
  final graph = buildGraph(coords);

  /// Berilgan tartib bo'yicha kunlarga bo'lib chiqadi (ish vaqti, kun oynasi, tirbandlik).
  RoutePlan simulate(List<int> order, List<int> deferredLog) {
    final skippedHere = [...skipped];
    final days = <DayPlan>[];
    var clock = _fitToDay(opt.start, opt);
    var day = DayPlan(1, clock);
    int? prev = hasStart ? 0 : null;
    var pending = [for (final i in order) if (!(hasStart && i == 0)) i];
    var deferred = <int>[];
    final attempts = <int, int>{};

    while (pending.isNotEmpty || deferred.isNotEmpty) {
      if (pending.isEmpty) {
        // Yangi kun: bugun sig'magan joylar ertaga birinchi navbatda
        if (day.stops.isNotEmpty) days.add(day);
        clock = DateTime(clock.year, clock.month, clock.day + 1).add(Duration(minutes: opt.dayStart));
        day = DayPlan(days.length + 1, clock);
        pending = deferred;
        deferred = [];
        if (days.length > 14) break;
      }
      final idx = pending.removeAt(0);
      final a = chosen[idx - off];
      var path = [idx];
      var leg = Leg.zero;
      if (prev != null) {
        if (roads != null && roadMin[prev][idx] != null) {
          // haqiqiy yo'l: chiziq keyin RoadRouter.geometry bilan chiziladi
          path = [prev, idx];
          leg = legFor(roadKm[prev][idx], clock, opt.transport, baseMinutes: roadMin[prev][idx]);
        } else {
          final (p, km) = astar(graph, coords, prev, idx);
          path = p;
          leg = legFor(km, clock, opt.transport);
        }
      }
      final arrive = clock.add(Duration(minutes: leg.minutes.round()));
      final start = nextVisitStart(a, arrive, opt);
      final fresh = day.stops.isEmpty;
      final sameDay = start != null && start.day == arrive.day && start.month == arrive.month;
      final ok = start != null && (fresh || (sameDay && start.difference(arrive).inMinutes <= 90));
      if (!ok) {
        attempts[idx] = (attempts[idx] ?? 0) + 1;
        if (start == null || attempts[idx]! > 3) {
          skippedHere.add(Skipped(a, 'closed'));
        } else {
          deferred.add(idx);
          deferredLog.add(idx);
        }
        continue;
      }
      if (fresh && !sameDay) day.date = DateTime(start.year, start.month, start.day);
      final leave = start.add(Duration(minutes: a.visitMinutes));
      final closeMin = a.isHotel ? 24 * 60 : min(a.closeMin, 24 * 60);
      final leaveMin = leave.hour * 60 + leave.minute;
      day.stops.add(Stop(
        place: a,
        travelKm: leg.km,
        travelMinutes: leg.minutes.round(),
        travelCost: leg.cost,
        by: leg.by,
        arrive: arrive,
        start: start,
        leave: leave,
        overnight: !sameDay,
        closingSoon: !a.alwaysOpen && !a.isHotel && closeMin - leaveMin < 30,
      ));
      day.distanceKm += leg.km;
      day.travelMinutes += leg.minutes.round();
      day.costUsd += a.isHotel ? 0 : a.costUsd;
      day.transportUsd += leg.cost;
      day.path.addAll(path.map((i) => LatLng(coords[i][0], coords[i][1])));
      clock = leave;
      prev = idx;
    }
    if (day.stops.isNotEmpty) days.add(day);
    for (var i = 0; i < days.length; i++) {
      days[i].day = i + 1;
    }
      return RoutePlan(days, skippedHere, opt, roadBased: roads != null);
  }

  // Ish vaqti sababli boshqa kunga surilgan joylarni kunning oldinroq qismiga qo'yib ko'ramiz
  // (masalan, faqat tushlikda ochiq osh markazi) va eng kam kun / o'tkazib yuborish / yo'l vaqtini tanlaymiz.
  final log = <int>[];
  var best = simulate(order, log);
  if (log.isNotEmpty) {
    final base = [for (final i in order) if (!(hasStart && i == 0)) i];
    bool better(RoutePlan a, RoutePlan b) {
      if (a.days.length != b.days.length) return a.days.length < b.days.length;
      if (a.skipped.length != b.skipped.length) return a.skipped.length < b.skipped.length;
      return a.travelMinutes < b.travelMinutes;
    }

    for (final d in {...log}) {
      for (var pos = 0; pos < base.length; pos++) {
        final o = [...base]
          ..remove(d)
          ..insert(pos, d);
        final cand = simulate([if (hasStart) 0, ...o], <int>[]);
        if (better(cand, best)) best = cand;
      }
    }
  }
  return best;
}
