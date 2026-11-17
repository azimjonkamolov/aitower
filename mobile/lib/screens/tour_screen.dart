import 'package:flutter/material.dart';
import '../algorithms/optimizer.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../models/tour.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/place_image.dart';
import '../widgets/tour_card.dart';
import 'detail_screen.dart';
import 'route_result_screen.dart';

/// Tayyor marshrut sahifasi: tavsif, joylar ro'yxati va "Marshrutni ko'rsatish".
class TourScreen extends StatefulWidget {
  final Tour tour;
  final List<Attraction> all;
  const TourScreen({super.key, required this.tour, required this.all});
  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  bool tomorrow = true;

  @override
  Widget build(BuildContext context) {
    final lang = Lang.current.value;
    final t = widget.tour;
    final byId = {for (final a in widget.all) a.id: a};
    final places = [for (final id in t.places) if (byId[id] != null) byId[id]!];
    final cost = places.where((a) => !a.isHotel).fold(0.0, (s, a) => s + a.costUsd);
    final minutes = places.fold(0, (s, a) => s + a.visitMinutes);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(t.nameIn(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
            background: Stack(fit: StackFit.expand, children: [
              if (places.isNotEmpty) PlaceImage(places.first, fit: BoxFit.cover),
              const DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0x331C1917), Color(0xEE1C1917)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            Row(children: [
              Icon(tourIcons[t.icon] ?? Icons.route, color: AppColors.amber600),
              const SizedBox(width: 8),
              Expanded(child: Text(t.descIn(lang), style: const TextStyle(fontSize: 15, height: 1.4))),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _pill(Icons.place_outlined, '${places.length} ${tr('objects')}'),
              _pill(Icons.calendar_today_outlined, '${t.days} ${tr('days_short')}'),
              _pill(Icons.timer_outlined, '${(minutes / 60).toStringAsFixed(1)} ${tr('h_visits')}'),
              _pill(Icons.confirmation_number_outlined, '${tr('tickets')} ${money(cost)}'),
              _pill(t.transport == Transport.walk ? Icons.directions_walk : Icons.directions_car,
                  tr(t.transport == Transport.walk ? 'tr_walk' : 'tr_car')),
            ]),
            const SizedBox(height: 16),
            for (var i = 0; i < places.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.only(right: 12),
                  leading: SizedBox(width: 72, height: 72, child: PlaceImage(places[i], fit: BoxFit.cover)),
                  title: Text('${i + 1}. ${places[i].nameIn(lang)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${tr('city_${places[i].city}')} • ${places[i].visitMinutes} ${tr('min')}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(a: places[i]))),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: Text(tr('start_now')), selected: !tomorrow, onSelected: (_) => setState(() => tomorrow = false)),
              ChoiceChip(label: Text(tr('start_tomorrow')), selected: tomorrow, onSelected: (_) => setState(() => tomorrow = true)),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.alt_route),
              label: Text(tr('show_route')),
              onPressed: () {
                final now = DateTime.now();
                LocalStore.i.recordRoute(places.length);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RouteResultScreen(
                              places: places,
                              fromMyLocation: false,
                              options: RouteOptions(
                                  strategy: Strategy.balanced,
                                  transport: t.transport,
                                  start: tomorrow ? DateTime(now.year, now.month, now.day + 1, 9) : now),
                            )));
              },
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: AppColors.stone200), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppColors.amber600),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
}
