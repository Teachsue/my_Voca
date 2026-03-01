import 'package:flutter/material.dart';
import 'theme_manager.dart';

class SeasonalBackground extends StatelessWidget {
  final Widget child;

  const SeasonalBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = ThemeManager.bgGradient;
    final icon = ThemeManager.seasonIconData;
    final primaryColor = ThemeManager.pointColor;
    final bool isDark = ThemeManager.isDarkMode;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge, 
        children: [
          // ★ 다크모드에서도 아주 미세하게 아이콘을 배치하여 심심함을 방지
          Positioned(
            top: -60,
            right: -60,
            child: Icon(
              icon,
              size: 300,
              color: isDark 
                  ? Colors.white.withOpacity(0.02) // 아주 살짝 비치는 느낌
                  : primaryColor.withOpacity(0.07),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
