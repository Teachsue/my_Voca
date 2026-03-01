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
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Icon(
              icon,
              size: 280,
              color: primaryColor.withOpacity(0.06),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
