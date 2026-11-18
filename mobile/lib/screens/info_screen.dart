import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'guides_screen.dart';

/// "Foydali ma'lumot": favqulodda raqamlar, transport, pul, xavfsizlik, kiyinish, mavsum, iboralar.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  static const _emergency = [
    ('112', 'em_112', Icons.sos),
    ('101', 'em_101', Icons.local_fire_department),
    ('102', 'em_102', Icons.local_police),
    ('103', 'em_103', Icons.local_hospital),
    ('104', 'em_104', Icons.gas_meter),
  ];

  static const _sections = [
    (Icons.directions_bus_outlined, 'inf_transport_t', 'inf_transport'),
    (Icons.payments_outlined, 'inf_money_t', 'inf_money'),
    (Icons.sim_card_outlined, 'inf_sim_t', 'inf_sim'),
    (Icons.checkroom_outlined, 'inf_dress_t', 'inf_dress'),
    (Icons.health_and_safety_outlined, 'inf_safety_t', 'inf_safety'),
    (Icons.wb_sunny_outlined, 'inf_season_t', 'inf_season'),
    (Icons.restaurant_menu, 'inf_food_t', 'as_food'),
    (Icons.celebration_outlined, 'inf_fest_t', 'as_festival'),
  ];

  static const _phrases = [
    ('Assalomu alaykum', 'ph_hello'),
    ('Rahmat', 'ph_thanks'),
    ('Qancha turadi?', 'ph_price'),
    ('… qayerda?', 'ph_where'),
    ('Yordam bering!', 'ph_help'),
    ('Mazali!', 'ph_tasty'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('nav_info'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        PageHeader(icon: Icons.info_outline, title: tr('info_title'), subtitle: tr('info_sub')),
        Card(
          color: const Color(0xFFFEF2F2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFECACA))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('emergency'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.red)),
              const SizedBox(height: 8),
              for (final e in _emergency)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(e.$3, color: AppColors.red),
                  title: Text(tr(e.$2)),
                  trailing: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14)),
                    onPressed: () => launchUrl(Uri.parse('tel:${e.$1}')),
                    icon: const Icon(Icons.call, size: 16),
                    label: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFFEFF6FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFBFDBFE))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.local_police, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 8),
                Expanded(child: Text(tr('tpolice_title'), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)))),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: () => launchUrl(Uri.parse('tel:1173')),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('1173', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(tr('tpolice_text'), style: const TextStyle(height: 1.4)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.map_outlined, color: AppColors.amber600),
            ),
            title: Text(tr('guides_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(tr('guides_short'), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidesScreen())),
          ),
        ),
        const SizedBox(height: 10),
        for (final s in _sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(s.$1, color: AppColors.amber600),
                  ),
                  title: Text(tr(s.$2), style: const TextStyle(fontWeight: FontWeight.w700)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(tr(s.$3), style: const TextStyle(height: 1.45))],
                ),
              ),
            ),
          ),
        SectionCard(
          title: tr('phrases'),
          child: Column(children: [
            for (final p in _phrases)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(child: Text(tr(p.$2), style: const TextStyle(color: AppColors.stone500))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(tr('info_note'), style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
      ]),
    );
  }
}
