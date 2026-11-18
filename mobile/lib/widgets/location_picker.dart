import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'osm.dart';

/// GPS bo'lmasa (planshet, brauzer, o'chiq GPS) joylashuvni qo'lda tanlash:
/// shahar markazlaridan biri yoki xaritada belgilash.
const _cities = <(String, double, double)>[
  ('qarshi', 38.8610, 65.7960),
  ('shahrisabz', 39.0560, 66.8300),
  ('kitob', 39.1220, 66.8820),
  ('guzor', 38.6200, 66.2480),
  ('yakkabog', 38.9770, 66.6880),
  ('chiroqchi', 39.0330, 66.5720),
  ('muborak', 39.2550, 65.1530),
];

Future<void> pickLocation(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('pick_location'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(tr('pick_location_sub'), style: const TextStyle(color: AppColors.stone500)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final ok = await AppState.locate();
              if (c.mounted) Navigator.pop(c);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('locate_failed'))));
              }
            },
            icon: const Icon(Icons.my_location),
            label: Text(tr('use_gps')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(c);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const _MapPick()));
            },
            icon: const Icon(Icons.touch_app_outlined),
            label: Text(tr('pick_on_map')),
          ),
          const SizedBox(height: 12),
          Text(tr('or_city'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final city in _cities)
              ActionChip(
                avatar: const Icon(Icons.location_city, size: 16),
                label: Text(tr('city_${city.$1}')),
                onPressed: () {
                  AppState.setManual(LatLng(city.$2, city.$3), tr('city_${city.$1}'));
                  Navigator.pop(c);
                },
              ),
          ]),
        ]),
      ),
    ),
  );
}

class _MapPick extends StatefulWidget {
  const _MapPick();
  @override
  State<_MapPick> createState() => _MapPickState();
}

class _MapPickState extends State<_MapPick> {
  LatLng? point = AppState.position.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('pick_on_map'))),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: point ?? const LatLng(38.95, 66.3),
            initialZoom: point == null ? 8 : 12,
            onTap: (_, p) => setState(() => point = p),
          ),
          children: [
            osmTiles(),
            if (point != null)
              MarkerLayer(markers: [
                Marker(point: point!, width: 44, height: 44, child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 44)),
              ]),
            osmAttribution(),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Card(
            child: Padding(padding: const EdgeInsets.all(12), child: Text(tr('tap_map_hint'), textAlign: TextAlign.center)),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: point == null
                ? null
                : () {
                    AppState.setManual(point!, tr('picked_point'));
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.check),
            label: Text(tr('confirm_location')),
          ),
        ),
      ),
    );
  }
}
