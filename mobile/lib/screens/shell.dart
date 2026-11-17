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
        builder: (context, tab, _) => Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: const LogoTitle(),
            actions: [LangSwitch(key: ValueKey(Lang.current.value)), const SizedBox(width: 12)],
          ),
          drawer: _drawer(context, tab),
          body: IndexedStack(index: tab, children: [
            ExploreScreen(),
            MapScreen(),
            RouteSetupScreen(),
            RecommendScreen(),
            AssistantScreen(),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => AppState.tab.value = i,
            destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.$1), label: tr(t.$2))],
          ),
        ),
      );

  Widget _drawer(BuildContext context, int tab) {
    Widget item(IconData icon, String key, bool active, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Material(
            color: active ? AppColors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(icon, color: active ? AppColors.stone900 : AppColors.stone400),
              title: Text(tr(key),
                  style: TextStyle(
                      color: active ? AppColors.stone900 : AppColors.stone100,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              onTap: onTap,
            ),
          ),
        );
    return Drawer(
      backgroundColor: AppColors.stone900,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(padding: EdgeInsets.all(20), child: LogoTitle()),
          const Divider(color: AppColors.stone800, height: 1),
          const SizedBox(height: 12),
          for (var i = 0; i < _tabs.length; i++)
            item(_tabs[i].$1, _tabs[i].$2, tab == i, () {
              Navigator.pop(context);
              AppState.tab.value = i;
            }),
          item(Icons.star_border, 'nav_reviews', false, () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()));
          }),
          item(Icons.info_outline, 'nav_info', false, () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen()));
          }),
          item(Icons.bar_chart, 'nav_admin', false, () {
            Navigator.pop(context);
            openAdmin(context);
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(tr('tagline'), style: const TextStyle(color: AppColors.stone500, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}
