import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../models/tour.dart';
import '../screens/tour_screen.dart';
import '../theme.dart';
import 'place_image.dart';

const tourIcons = <String, IconData>{
  'account_balance': Icons.account_balance,
  'mosque': Icons.mosque,
  'landscape': Icons.landscape,
  'location_city': Icons.location_city,
  'auto_awesome': Icons.auto_awesome,
  'history_edu': Icons.history_edu,
};

/// Gorizontal karuseldagi tayyor marshrut kartasi: rasm, nom, joylar soni, kunlar.
class TourCard extends StatelessWidget {
  final Tour tour;
  final List<Attraction> all;
  const TourCard({super.key, required this.tour, required this.all});

  @override
  Widget build(BuildContext context) {
    final lang = Lang.current.value;
    final first = all.where((a) => a.id == tour.places.first).firstOrNull;
    return SizedBox(
      width: 230,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TourScreen(tour: tour, all: all))),
          child: Stack(fit: StackFit.expand, children: [
            if (first != null) PlaceImage(first, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0x00000000), Color(0xDD1C1917)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(10)),
                  child: Icon(tourIcons[tour.icon] ?? Icons.route, size: 18, color: AppColors.stone900),
                ),
                const Spacer(),
                Text(tour.nameIn(lang),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.15)),
                const SizedBox(height: 4),
                Text('${tour.places.length} ${tr('objects')} • ${tour.days} ${tr('days_short')}',
                    style: const TextStyle(color: AppColors.amber400, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
