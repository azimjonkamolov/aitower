import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../screens/detail_screen.dart';
import '../services/app_state.dart';
import '../services/local_store.dart';
import '../theme.dart';
import 'common.dart';
import 'place_image.dart';

/// Saytdagi obyekt kartasi: rangli sarlavha, toifa nishoni, reyting, tavsif, manzil, ish vaqti.
class PlaceCard extends StatelessWidget {
  final Attraction a;
  final Widget? extra;
  const PlaceCard(this.a, {super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    final lang = Lang.current.value;
    final reviews = LocalStore.i.commentsOf(a.id).length;
    final myRating = LocalStore.i.ratingOf(a.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(a: a))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 150,
            child: Stack(fit: StackFit.expand, children: [
              Hero(tag: 'img-${a.id}', child: PlaceImage(a)),
              if (a.image != null)
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0x55000000), Color(0x00000000), Color(0x66000000)],
                            stops: [0, 0.45, 1],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter))),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(children: [
              Align(alignment: Alignment.topLeft, child: CategoryBadge(a.category)),
              Align(alignment: Alignment.topRight, child: RatingPill(a.rating)),
              Align(
                alignment: Alignment.bottomRight,
                child: ValueListenableBuilder<Set<int>>(
                  valueListenable: AppState.selected,
                  builder: (_, sel, __) => Material(
                    color: sel.contains(a.id) ? AppColors.stone900 : Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => AppState.toggle(a.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(sel.contains(a.id) ? Icons.check : Icons.add,
                            size: 20, color: sel.contains(a.id) ? AppColors.amber400 : AppColors.stone900),
                      ),
                    ),
                  ),
                ),
              ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.nameIn(lang), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(a.descriptionIn(lang),
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.stone500, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.place_outlined, size: 14, color: AppColors.stone500),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(
                        '${tr('city_${a.city}')}${a.distanceKm != null ? ' • ${a.distanceKm!.round()} ${tr('km')}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.stone500))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: OpenDot(a)),
                if (myRating != null) ...[
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                  Text(' $myRating ', style: const TextStyle(fontSize: 12)),
                ],
                if (reviews > 0)
                  Text('$reviews ${tr('reviews_short')}', style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
              ]),
              if (extra != null) ...[const SizedBox(height: 8), extra!],
            ]),
          ),
        ]),
      ),
    );
  }
}
