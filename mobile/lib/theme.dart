import 'package:flutter/material.dart';

/// Ranglar "AI Smart Tourism Qashqadaryo" veb-sayti dizaynidan olingan (stone + amber).
class AppColors {
  static const stone900 = Color(0xFF1C1917);
  static const stone800 = Color(0xFF292524);
  static const stone700 = Color(0xFF44403C);
  static const stone500 = Color(0xFF78716C);
  static const stone400 = Color(0xFFA8A29E);
  static const stone200 = Color(0xFFE7E5E4);
  static const stone100 = Color(0xFFF5F5F4);
  static const stone50 = Color(0xFFFAFAF9);
  static const amber = Color(0xFFF59E0B);
  static const amber400 = Color(0xFFFBBF24);
  static const amber600 = Color(0xFFD97706);
  static const amber50 = Color(0xFFFFFBEB);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFDC2626);
}

ThemeData appTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.amber,
    onPrimary: AppColors.stone900,
    secondary: AppColors.stone900,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.stone900,
    outline: AppColors.stone200,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.stone50,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.stone900,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.stone200)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.stone900,
      labelStyle: const TextStyle(color: AppColors.stone700, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      checkmarkColor: Colors.white,
      side: const BorderSide(color: AppColors.stone200),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.stone900,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.stone900,
            side: const BorderSide(color: AppColors.stone200),
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.stone100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.stone900,
      indicatorColor: AppColors.amber,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 11,
          color: s.contains(WidgetState.selected) ? AppColors.amber400 : AppColors.stone400,
          fontWeight: FontWeight.w600)),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.stone900 : AppColors.stone400)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.stone900 : Colors.white),
        foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.stone700),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.stone200)),
      ),
    ),
  );
}

/// Toifa nishonlari (saytdagidek: tabiat – yashil, ziyorat – sariq, tarix – qizil, mehmondo'stlik – ko'k).
class CatStyle {
  final Color bg, fg;
  final IconData icon;
  const CatStyle(this.bg, this.fg, this.icon);

  static CatStyle of(String category) => switch (category) {
        'ziyorat' => const CatStyle(Color(0xFFFEF3C7), Color(0xFF92400E), Icons.mosque),
        'tarix' => const CatStyle(Color(0xFFFEE2E2), Color(0xFF991B1B), Icons.account_balance),
        'tabiat' => const CatStyle(Color(0xFFDCFCE7), Color(0xFF166534), Icons.landscape),
        'mehmonxona' => const CatStyle(Color(0xFFDBEAFE), Color(0xFF1E40AF), Icons.hotel),
        'taom' => const CatStyle(Color(0xFFDBEAFE), Color(0xFF1E40AF), Icons.restaurant),
        _ => const CatStyle(Color(0xFFDBEAFE), Color(0xFF1E40AF), Icons.park),
      };
}
