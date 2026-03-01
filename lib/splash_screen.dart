import 'package:flutter/material.dart';
import 'theme_manager.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 애니메이션 지속 시간 연장
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    // ★ 미세하게 커지는 효과로 고급스러움 추가
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    // 2.8초 후 홈 화면으로 아주 부드럽게 이동
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // ★ 심리스 페이드 트랜지션
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800), // 전환 속도 최적화
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final primaryColor = ThemeManager.pointColor;
    final textColor = ThemeManager.textColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "포켓",
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -2.0,
                        ),
                      ),
                      TextSpan(
                        text: "보카",
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w200,
                          color: primaryColor,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "EVERY MOMENT, EVERY VOCA",
                  style: TextStyle(
                    fontSize: 11,
                    color: ThemeManager.subTextColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 80),
                // ★ 미니멀한 테마색 로딩 바
                SizedBox(
                  width: 30,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor.withOpacity(0.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
