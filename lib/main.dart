import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'word_model.dart';
import 'data_loader.dart';
import 'calendar_page.dart';
import 'study_record_service.dart';
import 'wrong_answer_page.dart';
import 'todays_word_list_page.dart';
import 'level_test_page.dart';
import 'day_selection_page.dart';
import 'statistics_page.dart';
import 'scrap_page.dart'; 
import 'theme_manager.dart';
import 'settings_page.dart';
import 'seasonal_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(WordAdapter());
  await Hive.openBox<Word>('words');
  await Hive.openBox('cache');
  await Hive.openBox<Word>('wrong_answers');
  await StudyRecordService.init();
  await initializeDateFormatting();
  await DataLoader.loadData(); 
  await ThemeManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Season>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, season, _) {
        return MaterialApp(
          title: '포켓보카',
          debugShowCheckedModeBanner: false,
          theme: ThemeManager.getThemeData(),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _refresh() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    String? recommendedLevel = cacheBox.get('user_recommended_level');
    final primaryColor = Theme.of(context).colorScheme.primary;
    final List<Color> bannerGradient = ThemeManager.bannerGradient;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildMainBanner(context, isCompleted, bannerGradient),
                const SizedBox(height: 16),
                _buildLevelBanner(context, recommendedLevel, primaryColor),
                const SizedBox(height: 32),
                const Text("TOEIC 난이도별 학습", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                _buildLevelGrid(context),
                const SizedBox(height: 32),
                const Text("나의 학습 도구", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                _buildUtilityRow(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("TOEIC 단어 정복", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), style: TextStyle(fontSize: 13, color: Colors.blueGrey[400], fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconButton(
              icon: Icons.calendar_month_rounded,
              color: primaryColor,
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage())); _refresh(); },
            ),
            const SizedBox(width: 10),
            _buildHeaderIconButton(
              icon: Icons.settings_rounded,
              color: primaryColor,
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())); _refresh(); },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(icon: Icon(icon, color: color, size: 22), onPressed: onTap, padding: EdgeInsets.zero),
    );
  }

  Widget _buildMainBanner(BuildContext context, bool isCompleted, List<Color> gradient) {
    return GestureDetector(
      onTap: () async { await _startTodaysQuiz(); _refresh(); },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted ? [Colors.grey.shade600, Colors.grey.shade700] : gradient,
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: (isCompleted ? Colors.black26 : gradient[0].withOpacity(0.3)), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCompleted ? "학습 완료! ✅" : "오늘의 단어 학습", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(isCompleted ? "정말 고생하셨습니다." : "매일 10개 단어로 실력을 키우세요", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBanner(BuildContext context, String? recommendedLevel, Color pointColor) {
    final bool hasResult = recommendedLevel != null;
    return GestureDetector(
      onTap: () async {
        if (hasResult) await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: recommendedLevel)));
        else _showLevelTestGuide(context);
        _refresh();
      },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: hasResult ? const Color(0xFFF0F7FF) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(hasResult ? Icons.workspace_premium_rounded : Icons.psychology_alt_rounded, color: hasResult ? const Color(0xFF5B86E5) : pointColor, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(hasResult ? "추천 레벨: TOEIC $recommendedLevel" : "실력 진단 테스트 시작하기", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
      children: [
        _buildLevelCard(context, "500", "입문", Colors.teal),
        _buildLevelCard(context, "700", "중급", Colors.indigo),
        _buildLevelCard(context, "900+", "실전", Colors.purple),
      ],
    );
  }

  Widget _buildLevelCard(BuildContext context, String level, String desc, Color color) {
    return GestureDetector(
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: level))); _refresh(); },
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(level, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCategoryCard(context, "오답노트", "틀린 단어", Icons.error_outline_rounded, Colors.redAccent, () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage())); _refresh(); })),
        const SizedBox(width: 12),
        Expanded(child: _buildCategoryCard(context, "중요단어", "스크랩", Icons.star_rounded, Colors.amber, () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScrapPage())); _refresh(); })),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _showLevelTestGuide(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white, surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding: const EdgeInsets.all(24),
          title: const Text("실력 진단 테스트", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("나의 현재 실력을 정확히 진단하고\n맞춤형 단어를 추천받으세요.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.blueGrey, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async { Navigator.pop(dialogContext); await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelTestPage())); _refresh(); },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text("시작하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startTodaysQuiz() async {
    final box = Hive.box<Word>('words');
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String todayKey = "today_list_$todayStr";
    List<Word> todaysWords = [];
    if (cacheBox.containsKey(todayKey)) {
      List<String> savedSpellings = List<String>.from(cacheBox.get(todayKey));
      final Map<String, Word> wordLookup = {for (var w in box.values) w.spelling: w};
      for (String spelling in savedSpellings) {
        final word = wordLookup[spelling];
        if (word != null) todaysWords.add(word);
      }
    }
    if (todaysWords.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      List<Word> reviewWords = box.values.where((w) => w.type == 'Word' && (w.reviewStep ?? 0) > 0 && !w.nextReviewDate.isAfter(today)).toList();
      List<Word> newWords = box.values.where((w) => w.type == 'Word' && (w.reviewStep ?? 0) == 0).toList();
      reviewWords.shuffle(); newWords.shuffle();
      todaysWords.addAll(reviewWords.take(10));
      if (todaysWords.length < 10) todaysWords.addAll(newWords.take(10 - todaysWords.length));
      cacheBox.put(todayKey, todaysWords.map((w) => w.spelling).toList());
    }
    bool isCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => TodaysWordListPage(words: todaysWords, isCompleted: isCompleted)));
  }
}
