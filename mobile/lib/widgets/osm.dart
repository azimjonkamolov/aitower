import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// OpenStreetMap xarita qatlami va majburiy "© OpenStreetMap contributors" yozuvi.
Widget osmTiles() => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'uz.tourism.ai_smart_tourism');

Widget osmAttribution() => RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      attributions: [
        TextSourceAttribution('OpenStreetMap contributors',
            onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'))),
      ],
    );
