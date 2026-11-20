import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../algorithms/content_filtering.dart';
import '../algorithms/optimizer.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/location_picker.dart';
import 'route_result_screen.dart';
import '../models/tour.dart';
import '../widgets/tour_card.dart';

/// "Optimal marshrut": joylashuv, strategiya, transport, byudjet, boshlanish vaqti va tanlangan obyektlar.
class RouteSetupScreen extends StatefulWidget {
  const RouteSetupScreen({super.key});
  @override
  State<RouteSetupScreen> createState() => _RouteSetupScreenState();
}

class _RouteSetupScreenState extends State<RouteSetupScreen> {
  Strategy strategy = Strategy.balanced;
  Transport transport = Transport.car;
  int budget = 3; // 0 past, 1 o'rtacha, 2 yuqori, 3 cheklovsiz
  bool tomorrow = false;
  List<Attraction> all = [];
  List<Tour> tours = [];
  static const budgetUsd = [10.0, 30.0, 100.0, null];

  @override
  void initState() {
    super.initState();
    DataService().attractions().then((v) => setState(() => all = v));
    DataService().tours().then((v) => setState(() => tours = v));
  }

  Widget _option(String key, IconData icon, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? AppColors.stone900 : AppColors.stone100,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(icon, color: selected ? Colors.white : AppColors.stone700, size: 20),
            title: Text(tr(key),
                style: TextStyle(color: selected ? Colors.white : AppColors.stone700, fontWeight: FontWeight.w600)),
            subtitle: Text(tr('${key}_desc'),
                style: TextStyle(color: selected ? AppColors.stone400 : AppColors.stone500, fontSize: 12)),
            onTap: onTap,
          ),
        ),
      );

  void _build(List<Attraction> places) {
    final pos = AppState.position.value;
    recommend(all, const {}, lat: pos?.latitude, lon: pos?.longitude, ratings: LocalStore.i.ratings);
    final now = DateTime.now();
    final opt = RouteOptions(
      strategy: strategy,
      transport: transport,
      budget: budgetUsd[budget],
      start: tomorrow ? DateTime(now.year, now.month, now.day + 1, 9) : now,
    );
    LocalStore.i.recordRoute(places.length);
    Navigator.push(context, MaterialPageRoute(builder: (_) => RouteResultScreen(places: places, options: opt)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: AppState.selected,
      builder: (context, sel, _) {
        final places = all.where((a) => sel.contains(a.id)).toList();
        final lang = Lang.current.value;
        return maxWidth(ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          PageHeader(title: tr('route_title'), subtitle: tr('route_sub')),
          if (tours.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(tr('ready_routes'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            SizedBox(
              height: 170,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: tours.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => TourCard(tour: tours[i], all: all),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(tr('own_route'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ValueListenableBuilder<LatLng?>(
                valueListenable: AppState.position,
                builder: (_, me, __) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.near_me_outlined, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(me == null
                            ? tr('locate_hint')
                            : AppState.manualLabel.value != null
                                ? '${tr('start_from')}: ${AppState.manualLabel.value}'
                                : '${tr('located')}: ${me.latitude.toStringAsFixed(4)}, ${me.longitude.toStringAsFixed(4)}')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      onPressed: () async {
                        final ok = await AppState.locate();
                        if (!ok && context.mounted) await pickLocation(context);
                      },
                      child: Text(tr(me == null ? 'locate_btn' : 'change')),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: tr('strategy'),
                child: Column(children: [
                  _option('st_shortest', Icons.place_outlined, strategy == Strategy.shortest,
                      () => setState(() => strategy = Strategy.shortest)),
                  _option('st_fastest', Icons.schedule, strategy == Strategy.fastest,
                      () => setState(() => strategy = Strategy.fastest)),
                  _option('st_balanced', Icons.speed, strategy == Strategy.balanced,
                      () => setState(() => strategy = Strategy.balanced)),
                ]),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: tr('transport'),
                child: SegmentedButton<Transport>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: Transport.walk, icon: const Icon(Icons.directions_walk), label: Text(tr('tr_walk'))),
                    ButtonSegment(value: Transport.car, icon: const Icon(Icons.directions_car), label: Text(tr('tr_car'))),
                    ButtonSegment(value: Transport.taxi, icon: const Icon(Icons.local_taxi), label: Text(tr('tr_taxi'))),
                  ],
                  selected: {transport},
                  onSelectionChanged: (s) => setState(() => transport = s.first),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: '${tr('budget')} (${tr('entry_fees')})',
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < 4; i++)
                    ChoiceChip(
                      label: Text(i == 3 ? tr('bd_any') : '${tr('bd_$i')} ≤\$${budgetUsd[i]!.round()}'),
                      selected: budget == i,
                      onSelected: (_) => setState(() => budget = i),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: tr('start_time'),
                child: Wrap(spacing: 8, children: [
                  ChoiceChip(label: Text(tr('start_now')), selected: !tomorrow, onSelected: (_) => setState(() => tomorrow = false)),
                  ChoiceChip(label: Text(tr('start_tomorrow')), selected: tomorrow, onSelected: (_) => setState(() => tomorrow = true)),
                ]),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: '${tr('selected_objects')} (${places.length})',
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (places.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(tr('none_selected'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.stone400)),
                    ),
                  for (final a in places)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(CatStyle.of(a.category).icon, color: CatStyle.of(a.category).fg),
                      title: Text(a.nameIn(lang)),
                      subtitle: OpenDot(a),
                      trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => AppState.toggle(a.id)),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => AppState.tab.value = 0,
                    icon: const Icon(Icons.add),
                    label: Text(tr('pick_objects')),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: places.isEmpty ? null : () => _build(places),
                icon: const Icon(Icons.alt_route),
                label: Text(tr('build_route')),
              ),
            ]),
          ),
        ]));
      },
    );
  }
}
