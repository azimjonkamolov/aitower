import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'admin/admin_screen.dart';
import 'assistant_screen.dart';
import 'explore_screen.dart';
import 'info_screen.dart';
import 'map_screen.dart';
import 'recommend_screen.dart';
import 'reviews_screen.dart';
import 'route_setup_screen.dart';

/// Asosiy oyna: saytdagi yon menyu -> pastki menyu (5 bo'lim) + chap tortma menyu (barcha 7 bo'lim).
class Shell extends StatelessWidget {
  const Shell({super.key});

  static const _tabs = [
    (Icons.explore_outlined, 'nav_explore'),
    (Icons.map_outlined, 'nav_map'),
    (Icons.alt_route, 'nav_routes'),
    (Icons.auto_awesome_outlined, 'nav_recommend'),
    (Icons.chat_bubble_outline, 'nav_assistant'),
  ];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: AppState.tab,
        builder: (context, tab, _) => LayoutBuilder(builder: (context, c) {
          // Planshet (keng ekran): saytdagidek chap yon menyu; telefon: pastki menyu
          final wide = c.maxWidth >= 720;
          final body = IndexedStack(index: tab, children: [
            ExploreScreen(),
            MapScreen(),
            RouteSetupScreen(),
            RecommendScreen(),
            AssistantScreen(),
          ]);
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: !wide,
              titleSpacing: wide ? 16 : 0,
              title: const LogoTitle(),
              actions: [LangSwitch(key: ValueKey(Lang.current.value)), const SizedBox(width: 12)],
            ),
            drawer: wide ? null : _drawer(context, tab),
            body: wide
                ? Row(children: [
                    Container(
                      width: c.maxWidth >= 1100 ? 240 : 84,
                      color: AppColors.stone900,
                      child: _menu(context, tab, inDrawer: false, compact: c.maxWidth < 1100),
                    ),
                    Expanded(child: body),
                  ])
                : body,
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected: (i) => AppState.tab.value = i,
                    destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.$1), label: tr(t.$2))],
                  ),
          );
        }),
      );

  Widget _drawer(BuildContext context, int tab) => Drawer(
        backgroundColor: AppColors.stone900,
        child: SafeArea(child: _menu(context, tab, inDrawer: true)),
      );

  /// Menyu bandlari: telefonda chap tortma menyuda, planshetda doimiy yon panelda (compact = faqat belgilar).
  Widget _menu(BuildContext context, int tab, {required bool inDrawer, bool compact = false}) {
    void go(VoidCallback f) {
      if (inDrawer) Navigator.pop(context);
      f();
    }

    Widget item(IconData icon, String key, bool active, VoidCallback onTap) => Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 2),
          child: Tooltip(
            message: compact ? tr(key) : '',
            child: Material(
              color: active ? AppColors.amber : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: compact
                  ? InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => go(onTap),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Icon(icon, color: active ? AppColors.stone900 : AppColors.stone400),
                      ),
                    )
                  : ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: Icon(icon, color: active ? AppColors.stone900 : AppColors.stone400),
                      title: Text(tr(key),
                          style: TextStyle(
                              color: active ? AppColors.stone900 : AppColors.stone100,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                      onTap: () => go(onTap),
                    ),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (inDrawer) ...[
        const Padding(padding: EdgeInsets.all(20), child: LogoTitle()),
        const Divider(color: AppColors.stone800, height: 1),
      ],
      const SizedBox(height: 12),
      for (var i = 0; i < _tabs.length; i++) item(_tabs[i].$1, _tabs[i].$2, tab == i, () => AppState.tab.value = i),
      item(Icons.star_border, 'nav_reviews', false,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()))),
      item(Icons.info_outline, 'nav_info', false,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen()))),
      item(Icons.bar_chart, 'nav_admin', false, () => openAdmin(context)),
      const Spacer(),
      if (!compact)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(tr('tagline'), style: const TextStyle(color: AppColors.stone500, fontSize: 12)),
        ),
    ]);
  }
}
