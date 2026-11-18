import 'package:flutter/material.dart';
import '../algorithms/content_filtering.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../models/tour.dart';
import '../widgets/place_card.dart';
import '../widgets/place_image.dart';
import '../widgets/tour_card.dart';
import 'info_screen.dart';
import '../widgets/location_picker.dart';

/// "Kashf qilish": qahramon banner, qidiruv, toifa filtrlari va obyekt kartalari.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const groups = ['all', 'ziyorat', 'tarix', 'tabiat', 'mehmon'];
  static const types = ['astro', 'etno', 'eko', 'agro', 'ekstrim', 'shifo', 'muzey', 'gastro'];
  String? type;
  String group = 'all', query = '';
  bool openNow = false;
  List<Attraction> all = [];
  List<Tour> tours = [];

  @override
  void initState() {
    super.initState();
    _load();
    AppState.position.addListener(_onPos);
  }

  @override
  void dispose() {
    AppState.position.removeListener(_onPos);
    super.dispose();
  }

  void _onPos() => setState(() {});

  Future<void> _load() async {
    all = await DataService().attractions();
    tours = await DataService().tours();
    if (mounted) setState(() {});
    if (AppState.position.value == null) await AppState.locate();
  }

  List<Attraction> get items {
    final pos = AppState.position.value;
    final lang = Lang.current.value;
    final q = query.toLowerCase();
    final list = recommend(all, group == 'all' ? <String>{} : {group},
        lat: pos?.latitude, lon: pos?.longitude, ratings: LocalStore.i.ratings);
    if (group == 'all') list.sort((a, b) => b.rating.compareTo(a.rating));
    return list
        .where((a) => group == 'all' || a.group == group)
        .where((a) => !openNow || a.isOpenAt(DateTime.now()))
        .where((a) => type == null || a.tags.contains(type))
        .where((a) => q.isEmpty || a.nameIn(lang).toLowerCase().contains(q) || a.descriptionIn(lang).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = items;
    return RefreshIndicator(
      onRefresh: () async {
        DataService.invalidate();
        await _load();
      },
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        _hero(),
        const SizedBox(height: 16),
        if (tours.isNotEmpty) ...[
          Row(children: [
            Text(tr('ready_routes'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${tours.length}', style: const TextStyle(color: AppColors.stone500)),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tours.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => TourCard(tour: tours[i], all: all),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          color: AppColors.stone900,
          child: ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.amber400),
            title: Text(tr('nav_info'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            subtitle: Text(tr('info_short'), style: const TextStyle(color: AppColors.stone400, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.amber400),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen())),
          ),
        ),
        const SizedBox(height: 16),
        if (AppState.position.value == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: const Color(0xFFEFF6FF),
              child: ListTile(
                leading: const Icon(Icons.location_off_outlined, color: Color(0xFF2563EB)),
                title: Text(tr('no_location'), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(tr('no_location_sub'), style: const TextStyle(fontSize: 12)),
                trailing: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                  onPressed: () => pickLocation(context),
                  child: Text(tr('choose')),
                ),
              ),
            ),
          ),
        TextField(
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('search')),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                    label: Text(tr('grp_$g')), selected: group == g, onSelected: (_) => setState(() => group = g)),
              ),
            FilterChip(
              avatar: Icon(Icons.schedule, size: 16, color: openNow ? Colors.white : AppColors.stone700),
              label: Text(tr('open_now_filter')),
              selected: openNow,
              onSelected: (v) => setState(() => openNow = v),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Text('${tr('tourism_type')}: ', style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
            for (final t in types)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(tr('tt_$t'), style: const TextStyle(fontSize: 12)),
                  selected: type == t,
                  onSelected: (v) => setState(() => type = v ? t : null),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Text('${list.length} ${tr('objects')}', style: const TextStyle(color: AppColors.stone500)),
        const SizedBox(height: 8),
        for (final a in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: PlaceCard(a)),
      ]),
    );
  }

  Widget _hero() {
    final cover = all.where((a) => a.id == 5 && a.image != null).firstOrNull;
    return Container(
        height: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              colors: [Color(0xFF0C4A6E), Color(0xFF1E3A8A), AppColors.stone900],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft),
        ),
        child: Stack(fit: StackFit.expand, children: [
          if (cover != null) PlaceImage(cover),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0x221C1917), Color(0xE61C1917)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              const Row(children: [
                Icon(Icons.explore_outlined, color: AppColors.amber400, size: 16),
                SizedBox(width: 6),
                Text('QASHQADARYO',
                    style: TextStyle(color: AppColors.amber400, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              Text(tr('hero_title'),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
              const SizedBox(height: 4),
              Text(tr('hero_sub'), style: const TextStyle(color: Color(0xCCFFFFFF))),
            ]),
          ),
        ]),
      );
  }
}
