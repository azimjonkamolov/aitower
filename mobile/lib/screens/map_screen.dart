import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/osm.dart';
import 'detail_screen.dart';

/// "Xarita": barcha obyektlar toifa ranglarida + turistning joylashuvi.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final map = MapController();
  List<Attraction> all = [];
  Attraction? picked;
  String group = 'all';

  @override
  void initState() {
    super.initState();
    DataService().attractions().then((v) => setState(() => all = v));
  }

  @override
  Widget build(BuildContext context) {
    final shown = all.where((a) => group == 'all' || a.group == group).toList();
    return ValueListenableBuilder<LatLng?>(
      valueListenable: AppState.position,
      builder: (context, me, _) => Stack(children: [
        FlutterMap(
          mapController: map,
          options: MapOptions(
            initialCenter: const LatLng(38.95, 66.3),
            initialZoom: 8,
            onTap: (_, __) => setState(() => picked = null),
          ),
          children: [
            osmTiles(),
            MarkerLayer(markers: [
              for (final a in shown)
                Marker(
                  point: LatLng(a.lat, a.lon),
                  width: 36,
                  height: 36,
                  child: GestureDetector(
                    onTap: () => setState(() => picked = a),
                    child: Container(
                      decoration: BoxDecoration(
                          color: CatStyle.of(a.category).fg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(CatStyle.of(a.category).icon, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              if (me != null)
                Marker(
                  point: me,
                  width: 22,
                  height: 22,
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
                ),
            ]),
            osmAttribution(),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final g in ['all', 'ziyorat', 'tarix', 'tabiat', 'mehmon'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: Text(tr('grp_$g')), selected: group == g, onSelected: (_) => setState(() => group = g)),
                ),
            ]),
          ),
        ),
        Positioned(
          right: 12,
          bottom: picked == null ? 24 : 170,
          child: FloatingActionButton.small(
            heroTag: 'locate',
            backgroundColor: Colors.white,
            onPressed: () async {
              if (await AppState.locate()) map.move(AppState.position.value!, 13);
            },
            child: const Icon(Icons.my_location, color: AppColors.stone900),
          ),
        ),
        if (picked != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(picked!.nameIn(Lang.current.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 6),
                  Row(children: [CategoryBadge(picked!.category), const SizedBox(width: 8), RatingPill(picked!.rating)]),
                  const SizedBox(height: 6),
                  OpenDot(picked!),
                ]),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(a: picked!))),
              ),
            ),
          ),
      ]),
    );
  }
}
