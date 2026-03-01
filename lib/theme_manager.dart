import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum Season { spring, summer, autumn, winter, auto }

class ThemeManager {
  static const String _themeKey = 'user_selected_season';
  static final ValueNotifier<Season> themeNotifier = ValueNotifier(Season.auto);

  static Future<void> init() async {
    final cacheBox = Hive.box('cache');
    final String? savedSeason = cacheBox.get(_themeKey);
    if (savedSeason != null) {
      themeNotifier.value = Season.values.firstWhere(
        (e) => e.toString() == savedSeason,
        orElse: () => Season.auto,
      );
    }
  }

  static Season get selectedSeason => themeNotifier.value;

  static Future<void> updateSeason(Season season) async {
    final cacheBox = Hive.box('cache');
    await cacheBox.put(_themeKey, season.toString());
    themeNotifier.value = season; 
  }

  static Season get effectiveSeason {
    if (selectedSeason == Season.auto) {
      final month = DateTime.now().month;
      if (month >= 3 && month <= 5) return Season.spring;
      if (month >= 6 && month <= 8) return Season.summer;
      if (month >= 9 && month <= 11) return Season.autumn;
      return Season.winter;
    }
    return selectedSeason;
  }

  static Color get seasonColor {
    switch (effectiveSeason) {
      case Season.spring: return const Color(0xFFFF85A1); // 로즈 핑크
      case Season.summer: return const Color(0xFF0077B6); // 딥 오션 네이비
      case Season.autumn: return const Color(0xFFBC6C25); // 어스 브라운
      case Season.winter: return const Color(0xFF4A4E69); // 뮤트 퍼플
      default: return const Color(0xFF6366F1);
    }
  }

  static Color get seasonSecondaryColor {
    switch (effectiveSeason) {
      case Season.spring: return const Color(0xFFFBC2EB);
      case Season.summer: return const Color(0xFF90E0EF); // 시원한 민트블루
      case Season.autumn: return const Color(0xFFDDA15E);
      case Season.winter: return const Color(0xFFC9D6FF);
      default: return const Color(0xFF818CF8);
    }
  }

  static Color get surfaceColor {
    switch (effectiveSeason) {
      case Season.spring: return const Color(0xFFFFF5F6);
      case Season.summer: return const Color(0xFFF0F9FF);
      case Season.autumn: return const Color(0xFFFDF8F2);
      case Season.winter: return const Color(0xFFF4F7FA);
      default: return const Color(0xFFF8FAFC);
    }
  }

  static List<Color> get bgGradient {
    final base = surfaceColor;
    switch (effectiveSeason) {
      case Season.spring: return [base, const Color(0xFFFCE4EC)];
      case Season.summer: return [base, const Color(0xFFE0F2FE)];
      case Season.autumn: return [base, const Color(0xFFF5EBE0)];
      case Season.winter: return [base, const Color(0xFFE2E8F0)];
      default: return [base, Colors.white];
    }
  }

  static List<Color> get seasonGradient => bgGradient;

  static String get seasonBackgroundImage {
    switch (effectiveSeason) {
      case Season.spring: return "https://images.unsplash.com/photo-1490750967868-88aa4486c946?q=80&w=1200&auto=format&fit=crop";
      case Season.summer: return "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1200&auto=format&fit=crop";
      case Season.autumn: return "https://images.unsplash.com/photo-1507181378874-17796030911a?q=80&w=1200&auto=format&fit=crop";
      case Season.winter: return "https://images.unsplash.com/photo-1418985991508-e47386d96a71?q=80&w=1200&auto=format&fit=crop";
      default: return "";
    }
  }

  static String get seasonIcon {
    switch (effectiveSeason) {
      case Season.spring: return "🌸";
      case Season.summer: return "🌊";
      case Season.autumn: return "🍂";
      case Season.winter: return "❄️";
      default: return "✨";
    }
  }

  static ThemeData getThemeData() {
    final primaryColor = seasonColor;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF334155)),
      ),
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
      ),
    );
  }
}
