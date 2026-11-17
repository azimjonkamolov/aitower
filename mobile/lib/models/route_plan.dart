import 'package:latlong2/latlong.dart';
import '../algorithms/optimizer.dart';
import 'attraction.dart';

class Stop {
  final Attraction place;
  final double travelKm, travelCost;
  final int travelMinutes;
  final Transport by;
  final DateTime arrive, start, leave;
  final bool overnight, closingSoon;
  Stop({
    required this.place,
    required this.travelKm,
    required this.travelMinutes,
    required this.travelCost,
    required this.by,
    required this.arrive,
    required this.start,
    required this.leave,
    this.overnight = false,
    this.closingSoon = false,
  });
  int get waitMinutes => overnight ? 0 : start.difference(arrive).inMinutes;
}

class Skipped {
  final Attraction place;
  final String reason; // 'budget' | 'closed'
  Skipped(this.place, this.reason);
}

class DayPlan {
  int day;
  DateTime date;
  double distanceKm = 0, costUsd = 0, transportUsd = 0;
  int travelMinutes = 0;
  final stops = <Stop>[];
  final path = <LatLng>[];
  DayPlan(this.day, this.date);
}

class RoutePlan {
  final List<DayPlan> days;
  final List<Skipped> skipped;
  final RouteOptions options;
  final bool roadBased; // true: haqiqiy yo'llar (OSRM), false: taxminiy
  RoutePlan(this.days, this.skipped, this.options, {this.roadBased = false});
  double get totalKm => days.fold(0.0, (s, d) => s + d.distanceKm);
  double get totalCost => days.fold(0.0, (s, d) => s + d.costUsd);
  double get transportCost => days.fold(0.0, (s, d) => s + d.transportUsd);
  int get travelMinutes => days.fold(0, (s, d) => s + d.travelMinutes);
  List<Stop> get allStops => [for (final d in days) ...d.stops];
}
