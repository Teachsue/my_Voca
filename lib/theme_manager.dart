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

  static Season get systemSeason {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  static Season get effectiveSeason {
    if (selectedSeason == Season.auto) return systemSeason;
    return selectedSeason;
  }

  // ★ Japan App 스타일의 포인트 컬러 (아이콘, 강조 텍스트용)
  static Color get pointColor {
    switch (effectiveSeason) {
      case Season.spring: return const Color(0xFFFF6B81); // 벚꽃 핑크
      case Season.summer: return const Color(0xFF00A8FF); // 시원한 블루
      case Season.autumn: return const Color(0xFFE67E22); // 낙엽 오렌지
      case Season.winter: return const Color(0xFF607D8B); // 차분한 그레이블루
      default: return const Color(0xFF5B86E5);
    }
  }

  // ★ 배너용 그라데이션 컬러 (Japan App 스타일)
  static List<Color> get bannerGradient {
    switch (effectiveSeason) {
      case Season.spring: return [const Color(0xFFFFB7C5), const Color(0xFFF08080)];
      case Season.summer: return [const Color(0xFF4FC3F7), const Color(0xFF1976D2)];
      case Season.autumn: return [const Color(0xFFFBC02D), const Color(0xFFE64A19)];
      case Season.winter: return [const Color(0xFF90A4AE), const Color(0xFF455A64)];
      default: return [const Color(0xFF5B86E5), const Color(0xFF36D1DC)];
    }
  }

  // ★ 배경 그라데이션 (SeasonalBackground에서 사용)
  static List<Color> get bgGradient {
    switch (effectiveSeason) {
      case Season.spring: return [const Color(0xFFFFF0F5), const Color(0xFFFFFFFF)];
      case Season.summer: return [const Color(0xFFE0F7FA), const Color(0xFFFFFFFF)];
      case Season.autumn: return [const Color(0xFFFFF3E0), const Color(0xFFFFFFFF)];
      case Season.winter: return [const Color(0xFFF1F4F8), const Color(0xFFFFFFFF)];
      default: return [const Color(0xFFF8FAFC), const Color(0xFFFFFFFF)];
    }
  }

  static IconData get seasonIconData {
    switch (effectiveSeason) {
      case Season.spring: return Icons.local_florist_rounded;
      case Season.summer: return Icons.wb_sunny_rounded;
      case Season.autumn: return Icons.eco_rounded;
      case Season.winter: return Icons.ac_unit_rounded;
      default: return Icons.auto_awesome_rounded;
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
    final primary = pointColor;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      ),
    );
  }
}
