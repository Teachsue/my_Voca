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
    final bgGradient = ThemeManager.bgGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bgGradient)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 36),
                _buildMainBanner(context, isCompleted),
                const SizedBox(height: 20),
                _buildLevelBanner(context, recommendedLevel),
                const SizedBox(height: 48),
                const Text("난이도별 단어 학습", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.8)),
                const SizedBox(height: 20),
                _buildLevelSelectionRow(),
                const SizedBox(height: 44),
                const Text("학습 도구", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.8)),
                const SizedBox(height: 20),
                _buildUtilityRow(),
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
            Row(
              children: [
                Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), style: TextStyle(fontSize: 15, color: primaryColor, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Text(ThemeManager.seasonIcon, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const Text("POKET VOCA", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.5)),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconButton(
              icon: Icons.calendar_today_rounded,
              color: primaryColor,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
                _refresh();
              },
            ),
            const SizedBox(width: 12),
            _buildHeaderIconButton(
              icon: Icons.settings_rounded,
              color: const Color(0xFF1E293B),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                _refresh();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54, height: 54,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildMainBanner(BuildContext context, bool isCompleted) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () async { await _startTodaysQuiz(); _refresh(); },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF1E293B) : primaryColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: (isCompleted ? const Color(0xFF1E293B) : primaryColor).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCompleted ? "학습 완료! ✅" : "오늘의 단어 학습", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(isCompleted ? "정말 고생하셨습니다." : "매일 10개 단어의 기적", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBanner(BuildContext context, String? recommendedLevel) {
    return GestureDetector(
      onTap: () async {
        if (recommendedLevel != null) {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: recommendedLevel)));
          _refresh();
        } else {
          _showLevelTestGuide(context);
        }
      },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(recommendedLevel != null ? "추천 레벨: TOEIC $recommendedLevel" : "나의 단어 실력 진단하기", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF475569)))),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelectionRow() {
    return Row(children: [_buildLevelMiniCard("500", "입문"), const SizedBox(width: 14), _buildLevelMiniCard("700", "중급"), const SizedBox(width: 14), _buildLevelMiniCard("900+", "실전")]);
  }

  Widget _buildLevelMiniCard(String level, String desc) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: level))); _refresh(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(28)),
          child: Column(
            children: [
              Text(level, style: TextStyle(color: primaryColor, fontSize: 26, fontWeight: FontWeight.w900)),
              Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityRow() {
    return Row(
      children: [
        _buildUtilityCard("오답노트", Icons.edit_document, const Color(0xFFF59E0B)),
        const SizedBox(width: 14),
        _buildUtilityCard("중요단어", Icons.star_rounded, const Color(0xFFFACC15)),
      ],
    );
  }

  Widget _buildUtilityCard(String title, IconData icon, Color iconColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (title == "오답노트") await Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage()));
          else await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScrapPage()));
          _refresh();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(28)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("실력 진단 테스트", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async { Navigator.pop(dialogContext); await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelTestPage())); _refresh(); },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
