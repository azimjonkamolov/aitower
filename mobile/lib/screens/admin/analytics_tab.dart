import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/strings.dart';
import '../../models/attraction.dart';
import '../../services/data_service.dart';
import '../../services/local_store.dart';
import '../../theme.dart';

/// Turistlar oqimi tahlili va statistik hisobotlar (hozircha shu qurilma ma'lumotlari).
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});
  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  List<Attraction> all = [];

  @override
  void initState() {
    super.initState();
    DataService().attractions().then((v) => setState(() => all = v));
  }

  Map<String, int> _group(Map<int, int> counts, String Function(Attraction) key) {
    final byId = {for (final a in all) a.id: a};
    final out = <String, int>{};
    counts.forEach((id, n) {
      final a = byId[id];
      if (a != null) out[key(a)] = (out[key(a)] ?? 0) + n;
    });
    return out;
  }

  String _report() {
    final s = LocalStore.i;
    final lang = Lang.current.value;
    final views = s.counts('views');
    final byId = {for (final a in all) a.id: a};
    final top = views.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final up = s.stat('rec_up'), down = s.stat('rec_down');
    final b = StringBuffer()
      ..writeln('AI Smart Tourism — ${tr('report')} (${DateTime.now().toString().substring(0, 16)})')
      ..writeln('${tr('k_sessions')}: ${s.stat('sessions')}')
      ..writeln('${tr('k_routes')}: ${s.stat('routes')}')
      ..writeln('${tr('k_visits')}: ${s.counts('visits').values.fold(0, (a, b) => a + b)}')
      ..writeln('${tr('k_reroutes')}: ${s.stat('reroutes')}')
      ..writeln('${tr('k_questions')}: ${s.stat('questions')}')
      ..writeln('${tr('ratings_given')}: ${s.ratings.length}, ${tr('k_comments')}: ${s.allComments.length}')
      ..writeln('${tr('rec_quality')}: ${up + down == 0 ? '-' : '${(up * 100 / (up + down)).round()}%'} ($up/${up + down})')
      ..writeln('\n${tr('top_places')}:');
    for (final e in top.take(10)) {
      if (byId[e.key] != null) b.writeln('  ${byId[e.key]!.nameIn(lang)}: ${e.value}');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = LocalStore.i;
    final lang = Lang.current.value;
    final views = s.counts('views');
    final byId = {for (final a in all) a.id: a};
    final top = views.entries.where((e) => byId[e.key] != null).toList()..sort((a, b) => b.value.compareTo(a.value));
    final byCity = _group(views, (a) => tr('city_${a.city}'));
    final byCat = _group(views, (a) => tr('cat_${a.category}'));
    final hours = s.counts('usage_hours');
    final up = s.stat('rec_up'), down = s.stat('rec_down');
    final routes = s.stat('routes');
    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _kpi(Icons.people_outline, '${s.stat('sessions')}', tr('k_sessions')),
          _kpi(Icons.alt_route, '$routes', tr('k_routes')),
          _kpi(Icons.place_outlined, routes == 0 ? '–' : (s.stat('route_stops') / routes).toStringAsFixed(1), tr('k_avg_stops')),
          _kpi(Icons.flag_outlined, '${s.counts('visits').values.fold(0, (a, b) => a + b)}', tr('k_visits')),
          _kpi(Icons.sync_alt, '${s.stat('reroutes')}', tr('k_reroutes')),
          _kpi(Icons.chat_bubble_outline, '${s.stat('questions')}', tr('k_questions')),
          _kpi(Icons.star_border, '${s.ratings.length}', tr('ratings_given')),
          _kpi(Icons.thumb_up_alt_outlined, up + down == 0 ? '–' : '${(up * 100 / (up + down)).round()}%', tr('rec_quality')),
        ],
      ),
      const SizedBox(height: 16),
      _bars(tr('top_places'), {for (final e in top.take(7)) byId[e.key]!.nameIn(lang): e.value}),
      _bars(tr('by_district'), byCity),
      _bars(tr('by_category'), byCat),
      _hours(hours),
      const SizedBox(height: 8),
      Text(tr('analytics_note'), style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: _report()));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('report_copied'))));
        },
        icon: const Icon(Icons.copy_all_outlined),
        label: Text(tr('copy_report')),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(title: Text(tr('clear_stats_q')), actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('clear'))),
                  ]));
          if (ok == true) setState(LocalStore.i.clearStats);
        },
        icon: const Icon(Icons.restart_alt),
        label: Text(tr('clear_stats')),
      ),
    ]);
  }

  Widget _kpi(IconData icon, String value, String label) => Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.amber600, size: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.stone500)),
              ]),
            ),
          ]),
        ),
      );

  Widget _bars(String title, Map<String, int> data) {
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.isEmpty ? 1 : entries.first.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (entries.isEmpty) Text(tr('no_data'), style: const TextStyle(color: AppColors.stone400)),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(width: 120, child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: e.value / maxV, minHeight: 10, backgroundColor: AppColors.stone100, color: AppColors.amber),
                    ),
                  ),
                  SizedBox(width: 32, child: Text('${e.value}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _hours(Map<int, int> h) {
    final maxV = h.values.isEmpty ? 1 : h.values.reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('by_hour'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 24; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 4 + 76 * (h[i] ?? 0) / maxV,
                    decoration: BoxDecoration(
                        color: (h[i] ?? 0) > 0 ? AppColors.amber : AppColors.stone100, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ]),
          ),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('00', style: TextStyle(fontSize: 10)),
            Text('06', style: TextStyle(fontSize: 10)),
            Text('12', style: TextStyle(fontSize: 10)),
            Text('18', style: TextStyle(fontSize: 10)),
            Text('23', style: TextStyle(fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}
