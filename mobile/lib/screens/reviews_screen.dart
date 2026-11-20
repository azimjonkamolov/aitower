import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../services/data_service.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/rating_dialog.dart';

/// "Sharhlar": foydalanuvchi baholash moduli — baholar, izohlar va tavsiyalar sifati.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Attraction> all = [];

  @override
  void initState() {
    super.initState();
    DataService().attractions().then((v) => setState(() => all = v));
  }

  Future<void> _new() async {
    final lang = Lang.current.value;
    final a = await showModalBottomSheet<Attraction>(
      context: context,
      builder: (c) => ListView(children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(tr('pick_place'), style: const TextStyle(fontWeight: FontWeight.w700))),
        for (final p in all) ListTile(leading: Icon(CatStyle.of(p.category).icon), title: Text(p.nameIn(lang)), onTap: () => Navigator.pop(c, p)),
      ]),
    );
    if (a != null && mounted && await showRatingDialog(context, a)) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.current.value;
    final byId = {for (final a in all) a.id: a};
    final ratings = LocalStore.i.ratings;
    final comments = LocalStore.i.allComments;
    final up = LocalStore.i.stat('rec_up'), down = LocalStore.i.stat('rec_down');
    final avg = ratings.isEmpty ? 0.0 : ratings.values.reduce((a, b) => a + b) / ratings.length;
    return Scaffold(
      appBar: AppBar(title: Text(tr('nav_reviews'))),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _new, icon: const Icon(Icons.rate_review_outlined), label: Text(tr('write_review'))),
      body: maxWidth(ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
        PageHeader(icon: Icons.star_border, title: tr('reviews_title'), subtitle: tr('reviews_sub')),
        Row(children: [
          Expanded(child: _kpi('${ratings.length}', tr('ratings_given'))),
          const SizedBox(width: 8),
          Expanded(child: _kpi(ratings.isEmpty ? '–' : avg.toStringAsFixed(1), tr('avg_rating'))),
          const SizedBox(width: 8),
          Expanded(child: _kpi(up + down == 0 ? '–' : '${(up * 100 / (up + down)).round()}%', tr('rec_quality'))),
        ]),
        const SizedBox(height: 16),
        if (comments.isEmpty && ratings.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Text(tr('no_reviews'), textAlign: TextAlign.center)),
        for (final e in ratings.entries)
          if (byId[e.key] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Icon(CatStyle.of(byId[e.key]!.category).icon, color: CatStyle.of(byId[e.key]!.category).fg),
                  title: Text(byId[e.key]!.nameIn(lang), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [for (var i = 1; i <= 5; i++) Icon(i <= e.value ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: AppColors.amber)]),
                    for (final c in comments.where((c) => c.$1 == e.key)) Padding(padding: const EdgeInsets.only(top: 4), child: Text('“${c.$2}”')),
                  ]),
                  onTap: () async {
                    if (await showRatingDialog(context, byId[e.key]!)) setState(() {});
                  },
                ),
              ),
            ),
      ])),
    );
  }

  Widget _kpi(String value, String label) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.stone500)),
          ]),
        ),
      );
}
