import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../services/app_state.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/map_links.dart';
import '../widgets/osm.dart';
import '../widgets/place_image.dart';
import '../widgets/rating_dialog.dart';

class DetailScreen extends StatefulWidget {
  final Attraction a;
  const DetailScreen({super.key, required this.a});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    LocalStore.i.recordView(widget.a.id);
  }

  Widget _row(IconData icon, String label, String value, {Color? color}) => ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.stone500),
        title: Text(label),
        trailing: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      );

  String _days(List<int> d) => d.map((i) => tr('wd$i')).join(', ');

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final lang = Lang.current.value;
    final point = LatLng(a.lat, a.lon);
    final (status, open) = openStatus(a);
    final my = LocalStore.i.ratingOf(a.id) ?? 0;
    final comments = LocalStore.i.commentsOf(a.id).reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text(a.nameIn(lang))),
      body: maxWidth(ListView(children: [
        if (a.image != null) ...[
          SizedBox(height: 240, child: Hero(tag: 'img-${a.id}', child: PlaceImage(a))),
          if (a.credit != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('📷 ${a.credit}', style: const TextStyle(fontSize: 10, color: AppColors.stone400)),
            ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(16, a.image != null ? 12 : 0, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(a.image != null ? 16 : 0),
            child: SizedBox(
          height: a.image != null ? 170 : 220,
          child: FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 15),
            children: [
              osmTiles(),
              MarkerLayer(markers: [
                Marker(point: point, width: 40, height: 40, child: const Icon(Icons.place, color: AppColors.amber600, size: 40))
              ]),
              osmAttribution(),
            ],
          ),
        ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [CategoryBadge(a.category), const Spacer(), RatingPill(a.rating)]),
            const SizedBox(height: 12),
            Text(a.descriptionIn(lang), style: const TextStyle(fontSize: 16, height: 1.4)),
          ]),
        ),
        _row(Icons.place_outlined, tr('address'), '${tr('region')}, ${tr('city_${a.city}')}'),
        _row(Icons.schedule, tr('hours'), a.alwaysOpen ? tr('open_24h') : a.hours.replaceAll('-', ' – ')),
        if (a.closedDays.isNotEmpty) _row(Icons.event_busy, tr('closed_days'), _days(a.closedDays)),
        _row(open ? Icons.check_circle_outline : Icons.cancel_outlined, tr('now'), status,
            color: open ? AppColors.green : AppColors.red),
        _row(Icons.timer_outlined, tr('visit_time'), '${a.visitMinutes} ${tr('min')}'),
        _row(Icons.payments_outlined, a.isHotel ? tr('per_night') : tr('ticket'), money(a.costUsd)),
        if (a.distanceKm != null) _row(Icons.near_me_outlined, tr('distance'), '${a.distanceKm!.round()} ${tr('km')}'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ValueListenableBuilder<Set<int>>(
              valueListenable: AppState.selected,
              builder: (_, sel, __) => FilledButton.icon(
                onPressed: () => AppState.toggle(a.id),
                icon: Icon(sel.contains(a.id) ? Icons.remove_circle_outline : Icons.add_circle_outline),
                label: Text(tr(sel.contains(a.id) ? 'remove_from_route' : 'add_to_route')),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => openPlace(a), icon: const Icon(Icons.map_outlined), label: Text(tr('open_maps'))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: SectionCard(
            title: tr('reviews_title'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('your_rating'), style: const TextStyle(color: AppColors.stone500)),
              StarPicker(
                  value: my,
                  onChanged: (v) {
                    LocalStore.i.rate(a.id, v);
                    setState(() {});
                  }),
              TextField(
                controller: comment,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: tr('comment_hint'),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.amber600),
                    onPressed: () {
                      if (comment.text.trim().isEmpty) return;
                      LocalStore.i.addComment(a.id, comment.text.trim());
                      comment.clear();
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (comments.isEmpty) Text(tr('no_reviews'), style: const TextStyle(color: AppColors.stone500)),
              for (final c in comments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                      backgroundColor: AppColors.amber50, child: Icon(Icons.person_outline, color: AppColors.amber600)),
                  title: Text(c['text'] as String),
                  subtitle: Text((c['date'] as String).substring(0, 10)),
                ),
            ]),
          ),
        ),
      ])),
    );
  }
}
