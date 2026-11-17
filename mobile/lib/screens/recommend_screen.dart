import 'package:flutter/material.dart';
import '../algorithms/content_filtering.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/place_card.dart';

/// "AI Tavsiyalar": qiziqishlar + byudjet -> shaxsiy reyting, har bir tavsiya sababi bilan.
class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});
  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final interests = <String>{};
  int budget = 1;
  List<Attraction> all = [], result = [];
  bool? feedback;

  @override
  void initState() {
    super.initState();
    DataService().attractions().then((v) => setState(() => all = v));
  }

  void _run() {
    final pos = AppState.position.value;
    final ranked = recommend(all, interests,
        lat: pos?.latitude, lon: pos?.longitude, ratings: LocalStore.i.ratings, budget: budget, limit: 10);
    setState(() {
      result = ranked;
      feedback = null;
    });
  }

  Widget _interest(String g, IconData icon) {
    final on = interests.contains(g);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: on ? AppColors.stone900 : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: BorderSide(color: on ? AppColors.stone900 : AppColors.stone200)),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: on ? AppColors.amber400 : AppColors.stone700),
          title: Text(tr('grp_$g'), style: TextStyle(fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.stone900)),
          subtitle: Text(tr('grp_${g}_desc'), style: TextStyle(fontSize: 12, color: on ? AppColors.stone400 : AppColors.stone500)),
          trailing: on ? const Icon(Icons.check_circle, color: AppColors.amber400) : null,
          onTap: () => setState(() => on ? interests.remove(g) : interests.add(g)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      PageHeader(icon: Icons.auto_awesome, title: tr('rec_title'), subtitle: tr('rec_sub')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
            title: tr('pick_interests'),
            child: Column(children: [
              _interest('ziyorat', Icons.mosque),
              _interest('tarix', Icons.account_balance),
              _interest('tabiat', Icons.landscape),
              _interest('mehmon', Icons.hotel),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '\$ ${tr('budget')}',
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [for (var i = 0; i < 3; i++) ButtonSegment(value: i, label: Text(tr('bd_$i')))],
              selected: {budget},
              onSelectionChanged: (s) => setState(() => budget = s.first),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: interests.isEmpty ? null : _run,
            icon: const Icon(Icons.auto_awesome),
            label: Text(tr('get_recs')),
          ),
          const SizedBox(height: 16),
          if (result.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.stone200)),
              child: Column(children: [
                const Icon(Icons.auto_awesome_outlined, size: 48, color: AppColors.stone400),
                const SizedBox(height: 8),
                Text(tr('rec_empty'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.stone500)),
              ]),
            ),
          for (final a in result)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PlaceCard(a,
                  extra: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('${tr('match')}: ', style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: a.score.clamp(0, 1),
                              minHeight: 6,
                              backgroundColor: AppColors.stone100,
                              color: AppColors.amber),
                        ),
                      ),
                      Text('  ${(a.score * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ]),
                    if (a.reasons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(spacing: 6, runSpacing: 4, children: [
                          for (final r in a.reasons)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: r == 'why_expensive' ? const Color(0xFFFEE2E2) : AppColors.amber50,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(tr(r), style: const TextStyle(fontSize: 11)),
                            ),
                        ]),
                      ),
                  ])),
            ),
          if (result.isNotEmpty)
            SectionCard(
              child: feedback != null
                  ? Text(tr('thanks_feedback'), textAlign: TextAlign.center)
                  : Row(children: [
                      Expanded(child: Text(tr('rec_helpful'))),
                      IconButton(
                          icon: const Icon(Icons.thumb_up_outlined, color: AppColors.green),
                          onPressed: () {
                            LocalStore.i.recordFeedback(true);
                            setState(() => feedback = true);
                          }),
                      IconButton(
                          icon: const Icon(Icons.thumb_down_outlined, color: AppColors.red),
                          onPressed: () {
                            LocalStore.i.recordFeedback(false);
                            setState(() => feedback = false);
                          }),
                    ]),
            ),
        ]),
      ),
    ]);
  }
}
