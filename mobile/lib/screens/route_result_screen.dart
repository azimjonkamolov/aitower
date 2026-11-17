import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../algorithms/astar.dart';
import '../algorithms/haversine.dart';
import '../algorithms/optimizer.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../models/roadside_stop.dart';
import '../models/route_plan.dart';
import '../services/data_service.dart';
import '../services/road_router.dart';
import '../services/app_state.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/map_links.dart';
import '../widgets/osm.dart';
import '../widgets/rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// Marshrut natijasi + "Sayohat rejimi" (real vaqt monitoringi):
/// harakat kuzatiladi, joyga yetib kelinganda belgilanadi, yo'ldan chiqilsa yoki joy yopilib
/// qolsa marshrut avtomatik qayta tuziladi.
class RouteResultScreen extends StatefulWidget {
  final List<Attraction> places;
  final RouteOptions options;
  final bool fromMyLocation; // tayyor marshrutlar birinchi joydan boshlanadi
  const RouteResultScreen({super.key, required this.places, required this.options, this.fromMyLocation = true});
  @override
  State<RouteResultScreen> createState() => _RouteResultScreenState();
}

class _RouteResultScreenState extends State<RouteResultScreen> {
  late RoutePlan plan;
  int day = 0;
  StreamSubscription<Position>? _sub;
  LatLng? me;
  final visited = <int>{};
  DateTime _lastReroute = DateTime(2000);
  String? banner;
  List<RoadsideStop> roadside = [];
  bool roadsLoading = false;
  final _alongCache = <String, List<RoadsideStop>>{};
  final shownKinds = <String>{};

  @override
  void initState() {
    super.initState();
    final p = widget.fromMyLocation ? AppState.position.value : null;
    me = AppState.position.value;
    plan = planRoute(widget.places, widget.options, startLat: p?.latitude, startLon: p?.longitude);
    DataService().roadsideStops().then((v) => setState(() => roadside = v));
    _upgradeWithRoads(widget.places, widget.options, p);
  }

  /// Avval taxminiy marshrut darhol ko'rsatiladi, so'ng internet bo'lsa haqiqiy yo'llar bo'yicha
  /// qayta hisoblanadi: masofa/vaqt OSRM jadvalidan, chiziq esa har bir bo'g'in yo'lidan.
  Future<void> _upgradeWithRoads(List<Attraction> places, RouteOptions opt, LatLng? start) async {
    setState(() => roadsLoading = true);
    final pts = [if (start != null) start, for (final a in places) LatLng(a.lat, a.lon)];
    final matrix = await RoadRouter.table(pts, opt.transport);
    if (matrix == null || !mounted) {
      if (mounted) setState(() => roadsLoading = false);
      return;
    }
    final next = planRoute(places, opt, startLat: start?.latitude, startLon: start?.longitude, roads: matrix);
    for (final d in next.days) {
      final wp = <LatLng>[];
      for (final p in d.path) {
        if (wp.isEmpty || wp.last != p) wp.add(p);
      }
      if (wp.length < 2) continue;
      final legs = await Future.wait([
        for (var i = 0; i + 1 < wp.length; i++)
          RoadRouter.geometry(wp[i], wp[i + 1], opt.transport == Transport.walk && d.stops.isNotEmpty ? Transport.walk : Transport.car)
      ]);
      final road = <LatLng>[];
      for (var i = 0; i < legs.length; i++) {
        road.addAll(legs[i] ?? [wp[i], wp[i + 1]]);
      }
      d.path
        ..clear()
        ..addAll(road);
    }
    if (!mounted) return;
    setState(() {
      plan = next;
      roadsLoading = false;
      _alongCache.clear();
    });
  }

  /// Kun marshruti yo'lagida (piyoda 0.5 km, mashinada 1.5 km) joylashgan yoqilg'i / ovqat / bozor joylari,
  /// yo'l bo'ylab tartibda.
  List<RoadsideStop> _along(DayPlan d, String kind) =>
      _alongCache['${identityHashCode(d)}-${d.path.length}-$kind-${roadside.length}'] ??= _computeAlong(d, kind);

  List<RoadsideStop> _computeAlong(DayPlan d, String kind) {
    if (d.path.length < 2) return [];
    // haqiqiy yo'l chizig'i bo'lsa yo'lak tor (1 km), taxminiy chiziqda kengroq (3 km)
    final limit = widget.options.transport == Transport.walk ? 0.5 : (plan.roadBased ? 1.0 : 3.0);
    final k = cos(d.path.first.latitude * pi / 180);
    (double, double) xy(double lat, double lon) => (lon * 111.32 * k, lat * 110.57);
    final out = <RoadsideStop>[];
    for (final r in roadside.where((r) => r.kind == kind)) {
      final (px, py) = xy(r.lat, r.lon);
      var best = double.infinity, along = 0.0, bestAlong = 0.0;
      var seg = 0;
      for (var i = 0; i + 1 < d.path.length; i++) {
        final (ax, ay) = xy(d.path[i].latitude, d.path[i].longitude);
        final (bx, by) = xy(d.path[i + 1].latitude, d.path[i + 1].longitude);
        final dx = bx - ax, dy = by - ay, len2 = dx * dx + dy * dy, len = sqrt(len2);
        final t = len2 == 0 ? 0.0 : (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
        final dist = sqrt(pow(px - (ax + t * dx), 2) + pow(py - (ay + t * dy), 2));
        if (dist < best) {
          best = dist;
          bestAlong = along + t * len;
          seg = i;
        }
        along += len;
      }
      if (best <= limit) {
        r
          ..offKm = best
          ..alongKm = bestAlong * (plan.roadBased ? 1 : roadFactor);
        // qaysi to'xtash joyidan keyin: yo'l nuqtasini kun to'xtash joylariga moslash
        final p = d.path[seg];
        r.afterStop = d.stops.lastIndexWhere((s) => s.place.lat == p.latitude && s.place.lon == p.longitude) + 1;
        out.add(r);
      }
    }
    out.sort((a, b) => a.alongKm.compareTo(b.alongKm));
    return out;
  }

  static const _kindIcon = {'fuel': Icons.local_gas_station, 'food': Icons.restaurant, 'bazaar': Icons.storefront};
  static const _kindColor = {'fuel': Color(0xFF0E7490), 'food': Color(0xFFB45309), 'bazaar': Color(0xFF7C3AED)};

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get tripOn => _sub != null;
  List<Stop> get remaining => [for (final s in plan.allStops) if (!visited.contains(s.place.id)) s];

  Future<void> _toggleTrip() async {
    if (tripOn) {
      await _sub!.cancel();
      setState(() => _sub = null);
      return;
    }
    if (!await AppState.locate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('locate_failed'))));
      return;
    }
    _sub = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen(_onPosition);
    setState(() => banner = tr('trip_started'));
  }

  void _onPosition(Position p) {
    me = LatLng(p.latitude, p.longitude);
    AppState.position.value = me;
    final rem = remaining;
    if (rem.isEmpty) {
      setState(() => banner = tr('trip_done'));
      return;
    }
    final next = rem.first;
    final dKm = haversineKm(p.latitude, p.longitude, next.place.lat, next.place.lon);
    if (dKm < 0.15) {
      visited.add(next.place.id);
      LocalStore.i.recordVisit(next.place.id);
      banner = '${tr('arrived')}: ${next.place.nameIn(Lang.current.value)}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(banner!),
        action: SnackBarAction(label: tr('rate'), onPressed: () => showRatingDialog(context, next.place)),
      ));
    } else {
      final dayIdx = plan.days.indexWhere((d) => d.stops.contains(next));
      final off = _distToPathKm(me!, plan.days[max(dayIdx, 0)].path);
      final limit = widget.options.transport == Transport.walk ? 0.5 : 2.0;
      String? reason;
      if (off > limit) {
        reason = tr('reason_off_route');
      } else if (!next.place.alwaysOpen) {
        final eta = DateTime.now().add(Duration(
            minutes: legFor(dKm * roadFactor, DateTime.now(), widget.options.transport).minutes.round()));
        // Faqat reja buzilsa: joy rejadagidan kechroq ochiladigan bo'lib qolsa (masalan, kechikdik va yopildi)
        final start = nextVisitStart(next.place, eta, widget.options);
        if (start == null || start.isAfter(next.start.add(const Duration(minutes: 30)))) reason = tr('reason_closed');
      }
      if (reason != null && DateTime.now().difference(_lastReroute).inSeconds > 60) _reroute(reason);
    }
    if (mounted) setState(() {});
  }

  void _reroute(String reason) {
    final places = remaining.map((s) => s.place).toList();
    plan = planRoute(places, widget.options.withStart(DateTime.now()), startLat: me?.latitude, startLon: me?.longitude);
    _alongCache.clear();
    _upgradeWithRoads(places, widget.options.withStart(DateTime.now()), me);
    day = 0;
    _lastReroute = DateTime.now();
    LocalStore.i.recordReroute();
    banner = '${tr('rerouted')}: $reason';
  }

  /// Nuqtadan marshrut chizig'igacha eng qisqa masofa (km), tekis proyeksiyada.
  double _distToPathKm(LatLng p, List<LatLng> path) {
    if (path.isEmpty) return 0;
    final k = cos(p.latitude * pi / 180);
    (double, double) xy(LatLng q) => (q.longitude * 111.32 * k, q.latitude * 110.57);
    final (px, py) = xy(p);
    var best = double.infinity;
    for (var i = 0; i < path.length; i++) {
      final (ax, ay) = xy(path[i]);
      final (bx, by) = xy(path[min(i + 1, path.length - 1)]);
      final dx = bx - ax, dy = by - ay;
      final len = dx * dx + dy * dy;
      final t = len == 0 ? 0.0 : (((px - ax) * dx + (py - ay) * dy) / len).clamp(0.0, 1.0);
      final cx = ax + t * dx, cy = ay + t * dy;
      best = min(best, sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy)));
    }
    return best;
  }

  IconData _icon(Transport t) => switch (t) {
        Transport.walk => Icons.directions_walk,
        Transport.car => Icons.directions_car,
        Transport.taxi => Icons.local_taxi,
      };

  @override
  Widget build(BuildContext context) {
    final lang = Lang.current.value;
    return Scaffold(
      appBar: AppBar(title: Text(tr('route_title'))),
      body: plan.days.isEmpty ? _empty() : _body(lang),
      bottomNavigationBar: plan.days.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  style: tripOn ? FilledButton.styleFrom(backgroundColor: AppColors.stone900, foregroundColor: Colors.white) : null,
                  onPressed: _toggleTrip,
                  icon: Icon(tripOn ? Icons.stop_circle_outlined : Icons.play_arrow_rounded),
                  label: Text(tr(tripOn ? 'trip_stop' : 'trip_start')),
                ),
              ),
            ),
    );
  }

  Widget _empty() => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.route, size: 56, color: AppColors.stone400),
            const SizedBox(height: 12),
            Text(tr('route_empty'), textAlign: TextAlign.center),
            ..._skippedList(),
          ])));

  List<Widget> _skippedList() => [
        if (plan.skipped.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final s in plan.skipped)
            ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline, color: AppColors.red),
              title: Text(s.place.nameIn(Lang.current.value)),
              subtitle: Text(tr('skip_${s.reason}')),
            ),
        ]
      ];

  Widget _body(String lang) {
    final d = plan.days[min(day, plan.days.length - 1)];
    final pts = d.path.isEmpty ? [LatLng(d.stops.first.place.lat, d.stops.first.place.lon)] : d.path;
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
      if (banner != null)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.campaign_outlined, color: AppColors.amber600),
            const SizedBox(width: 8),
            Expanded(child: Text(banner!)),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _stat(plan.roadBased ? Icons.add_road : Icons.straighten,
              roadsLoading ? tr('roads_loading') : tr(plan.roadBased ? 'roads_real' : 'roads_estimate')),
          _stat(Icons.straighten, '${plan.totalKm.toStringAsFixed(1)} ${tr('km')}'),
          _stat(Icons.schedule, '${(plan.travelMinutes / 60).toStringAsFixed(1)} ${tr('h_on_road')}'),
          _stat(Icons.confirmation_number_outlined, '${tr('tickets')} ${money(plan.totalCost)}'),
          _stat(_icon(widget.options.transport), '${tr('transport_cost')} ${money(plan.transportCost)}'),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          for (var i = 0; i < plan.days.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${dayLabel(i + 1)} · ${plan.days[i].date.day}.${plan.days[i].date.month.toString().padLeft(2, '0')}'),
                selected: day == i,
                onSelected: (_) => setState(() => day = i),
              ),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(tr('on_the_way'), style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
          for (final k in ['fuel', 'food', 'bazaar'])
            FilterChip(
              avatar: Icon(_kindIcon[k], size: 16, color: shownKinds.contains(k) ? Colors.white : _kindColor[k]),
              label: Text('${tr('kind_$k')} (${_along(d, k).length})'),
              selected: shownKinds.contains(k),
              onSelected: (v) => setState(() => v ? shownKinds.add(k) : shownKinds.remove(k)),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 260,
        child: FlutterMap(
          key: ValueKey('$day-${plan.hashCode}'),
          options: pts.length > 1
              ? MapOptions(initialCameraFit: CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(40), maxZoom: 15))
              : MapOptions(initialCenter: pts.first, initialZoom: 14),
          children: [
            osmTiles(),
            PolylineLayer(polylines: [Polyline(points: pts, strokeWidth: 4, color: AppColors.amber600)]),
            MarkerLayer(markers: [
              for (final k in shownKinds)
                for (final r in _along(d, k))
                  Marker(
                    point: LatLng(r.lat, r.lon),
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                          color: _kindColor[k], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(_kindIcon[k], size: 13, color: Colors.white),
                    ),
                  ),
              for (var i = 0; i < d.stops.length; i++)
                Marker(
                  point: LatLng(d.stops[i].place.lat, d.stops[i].place.lon),
                  width: 28,
                  height: 28,
                  child: CircleAvatar(
                    backgroundColor: visited.contains(d.stops[i].place.id) ? AppColors.green : AppColors.stone900,
                    child: visited.contains(d.stops[i].place.id)
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text('${i + 1}', style: const TextStyle(color: AppColors.amber400, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              if (me != null)
                Marker(
                    point: me!,
                    width: 20,
                    height: 20,
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)))),
            ]),
            osmAttribution(),
          ],
        ),
      ),
      for (var i = 0; i < d.stops.length; i++) _stopTile(d.stops[i], i, lang),
      for (final k in shownKinds) ..._roadsideList(d, k),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: OutlinedButton.icon(
          onPressed: () => openDirections(d.stops.map((s) => s.place).toList()),
          icon: const Icon(Icons.navigation_outlined),
          label: Text(tr('navigate_day')),
        ),
      ),
      ..._skippedList(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(tr('how_it_works'), style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
      ),
    ]);
  }

  List<Widget> _roadsideList(DayPlan d, String k) {
    final list = _along(d, k);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Icon(_kindIcon[k], color: _kindColor[k], size: 20),
          const SizedBox(width: 6),
          Text('${tr('kind_$k')} — ${tr('on_the_way').toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
      if (list.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(tr('none_on_way'), style: const TextStyle(color: AppColors.stone500))),
      for (final r in list.take(15))
        ListTile(
          dense: true,
          leading: CircleAvatar(radius: 14, backgroundColor: _kindColor[k], child: Icon(_kindIcon[k], size: 15, color: Colors.white)),
          title: Text(r.name ?? tr('unnamed_$k')),
          subtitle: Text([
            tr('after_km').replaceAll('{km}', r.alongKm.toStringAsFixed(0)),
            if (r.afterStop > 0) tr('after_stop').replaceAll('{n}', '${r.afterStop}'),
            '${(r.offKm * 1000).round()} m ${tr('off_road')}',
            if (r.fuels.isNotEmpty) r.fuels.map((f) => tr('fuel_$f')).join(', '),
            if (r.hours != null) r.hours!,
          ].join(' • ')),
          trailing: IconButton(
            icon: const Icon(Icons.directions, color: AppColors.amber600),
            onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${r.lat},${r.lon}'),
                mode: LaunchMode.externalApplication),
          ),
        ),
    ];
  }

  Widget _stat(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.stone200), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppColors.amber600),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );

  Widget _stopTile(Stop s, int i, String lang) {
    final done = visited.contains(s.place.id);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: done ? AppColors.green : AppColors.stone900,
        child: done ? const Icon(Icons.check, color: Colors.white) : Text('${i + 1}', style: const TextStyle(color: AppColors.amber400)),
      ),
      title: Text(s.place.nameIn(lang), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${hm(s.start)}–${hm(s.leave)} • ${s.place.visitMinutes} ${tr('min')} • ${money(s.place.isHotel ? 0 : s.place.costUsd)}'),
        if (s.travelKm > 0)
          Row(children: [
            Icon(_icon(s.by), size: 14, color: AppColors.stone500),
            Text(' ${s.travelKm.toStringAsFixed(1)} ${tr('km')}, ${s.travelMinutes} ${tr('min')}'
                '${s.travelCost > 0 ? ', ${money(s.travelCost)}' : ''}'),
          ]),
        if (s.waitMinutes > 5) Text('⏳ ${tr('wait_open').replaceAll('{m}', '${s.waitMinutes}')}', style: const TextStyle(color: AppColors.amber600)),
        if (s.overnight) Text('🌙 ${tr('overnight')}', style: const TextStyle(color: AppColors.amber600)),
        if (s.closingSoon) Text('⚠ ${tr('closing_soon')}', style: const TextStyle(color: AppColors.red)),
      ]),
      isThreeLine: true,
    );
  }
}
