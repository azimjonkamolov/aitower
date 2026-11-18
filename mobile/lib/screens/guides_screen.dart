import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Gid va tur xizmatlari: Qashqadaryo viloyatidagi litsenziyali turoperator va turagentlar
/// (Turizm qo'mitasi litsenziyalar reyestri, 27.02.2024, faqat ichki va kirish turizmi).
class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});
  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  List<Map<String, dynamic>> all = [];
  String? city;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/guides.json').then((s) => setState(() => all = List<Map<String, dynamic>>.from(jsonDecode(s))));
  }

  @override
  Widget build(BuildContext context) {
    final cities = <String>{for (final g in all) g['city'] as String}.toList();
    final shown = all.where((g) => city == null || g['city'] == city).toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr('guides_title'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        PageHeader(icon: Icons.map_outlined, title: tr('guides_title'), subtitle: tr('guides_sub')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(tr('grp_all')), selected: city == null, onSelected: (_) => setState(() => city = null)),
            ),
            for (final c in cities)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(tr('city_$c')), selected: city == c, onSelected: (_) => setState(() => city = c)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        for (final g in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.business, color: AppColors.amber600),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(g['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${tr('city_${g['city']}')} • ${g['kind'] == 'Turoperator' ? tr('tour_operator') : tr('tour_agent')}',
                            style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, children: [
                    if (g['inbound'] == true) _tag(tr('svc_inbound')),
                    if (g['domestic'] == true) _tag(tr('svc_domestic')),
                  ]),
                  if ((g['address'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(g['address'], style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
                    ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    for (final p in (g['phones'] as List).take(2))
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        onPressed: () => launchUrl(Uri.parse('tel:$p')),
                        icon: const Icon(Icons.call, size: 16),
                        label: Text(p),
                      ),
                    if ((g['web'] as String).isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        onPressed: () => launchUrl(Uri.parse(g['web']), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.public, size: 16),
                        label: Text(tr('website')),
                      ),
                  ]),
                ]),
              ),
            ),
          ),
        Text(tr('guides_note'), style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
      ]),
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.stone100, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(fontSize: 11)),
      );
}
