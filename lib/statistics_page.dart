import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'word_model.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _totalWordsCount = 0;
  int _wrongAnswersCount = 0;
  int _learnedWordsCount = 0;

  bool _isTodayCompleted = false;
  String _recommendedLevel = "미응시";

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    final wordBox = Hive.box<Word>('words');

    final Map<String, Word> uniqueMap = {};
    for (var w in wordBox.values.where((w) => w.type == 'Word')) {
      uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
    }
    _totalWordsCount = uniqueMap.length;

    if (Hive.isBoxOpen('wrong_answers')) {
      final wrongBox = Hive.box<Word>('wrong_answers');
      _wrongAnswersCount = wrongBox.length;
    }

    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _isTodayCompleted = cacheBox.get(
      "today_completed_$todayStr",
      defaultValue: false,
    );
    _recommendedLevel = cacheBox.get(
      'user_recommended_level',
      defaultValue: "미응시",
    );

    List<String> learnedWords = List<String>.from(
      cacheBox.get('learned_words', defaultValue: []),
    );
    _learnedWordsCount = learnedWords.length;

    setState(() {});
  }

  void _resetLevelTest() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "실력 진단 초기화",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "기존 레벨 테스트 결과가 삭제되며\n메인 화면에서 다시 응시할 수 있습니다.\n진행하시겠습니까?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final cacheBox = Hive.box('cache');
                cacheBox.delete('user_recommended_level');
                cacheBox.delete('level_test_progress');

                setState(() {
                  _recommendedLevel = "미응시";
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("레벨 테스트가 초기화되었습니다. 다시 도전해보세요! ✨"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "초기화",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetAllRecords() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                "전체 기록 초기화",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: const Text(
            "학습한 단어장, 오답 노트, 오늘의 퀴즈 완료 현황, 레벨 테스트 등 모든 개인 학습 데이터가 영구적으로 삭제됩니다.\n\n정말 처음부터 다시 시작하시겠습니까?",
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "취소",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // 1. 오답 노트 비우기
                if (Hive.isBoxOpen('wrong_answers')) {
                  await Hive.box<Word>('wrong_answers').clear();
                }

                // 2. 캐시 데이터 비우기 (학습 기록, 레벨테스트 결과, 진행상황 등 전부 날아감)
                await Hive.box('cache').clear();

                // ★ 3. 캘린더 학습 기록 비우기 (StudyRecordService에서 사용하는 박스)
                try {
                  if (Hive.isBoxOpen('study_records')) {
                    await Hive.box('study_records').clear();
                  } else {
                    // 혹시 박스가 닫혀있다면 열어서 지우기
                    final recordBox = await Hive.openBox('study_records');
                    await recordBox.clear();
                  }
                } catch (e) {
                  print("캘린더 데이터 초기화 실패: $e");
                }

                // 4. 현재 화면의 상태 업데이트
                setState(() {
                  _wrongAnswersCount = 0;
                  _learnedWordsCount = 0;
                  _isTodayCompleted = false;
                  _recommendedLevel = "미응시";
                });

                if (!mounted) return;
                Navigator.pop(dialogContext); // 팝업 닫기

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("모든 학습 기록 및 캘린더가 깔끔하게 초기화되었습니다! 🧹"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "전체 초기화",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double progressRatio = _totalWordsCount > 0
        ? (_learnedWordsCount / _totalWordsCount)
        : 0.0;
    String percentString = (progressRatio * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "학습 통계 및 설정 📊",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "나의 학습 현황",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "추천 레벨",
                      value: _recommendedLevel == "미응시"
                          ? "평가 필요"
                          : "TOEIC $_recommendedLevel",
                      icon: Icons.psychology_alt_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      title: "오늘의 목표",
                      value: _isTodayCompleted ? "달성 완료" : "진행 중",
                      icon: _isTodayCompleted
                          ? Icons.check_circle_rounded
                          : Icons.directions_run_rounded,
                      color: _isTodayCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            _buildWideStatCard(
              title: "전체 학습 진도율 ($percentString%)",
              subtitle: "퀴즈에서 한 번 이상 정답을 맞춘 단어의 비율입니다. 꾸준히 게이지를 채워보세요!",
              value: "$_learnedWordsCount / $_totalWordsCount",
              icon: Icons.trending_up_rounded,
              color: Colors.blueAccent,
              progressValue: progressRatio,
            ),
            const SizedBox(height: 15),

            _buildWideStatCard(
              title: "현재 복습이 필요한 단어",
              subtitle: "오답 노트에 쌓인 단어 수입니다. 틈틈이 복습해주세요!",
              value: "$_wrongAnswersCount개",
              icon: Icons.note_alt_rounded,
              color: Colors.redAccent,
              progressValue: _totalWordsCount > 0
                  ? (_wrongAnswersCount / _totalWordsCount)
                  : 0.0,
            ),

            const SizedBox(height: 40),

            const Text(
              "데이터 관리",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _recommendedLevel != "미응시" ? _resetLevelTest : null,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  "레벨 테스트 초기화",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _resetAllRecords,
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text(
                  "모든 학습 기록 초기화",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  backgroundColor: Colors.red[50],
                  side: BorderSide(
                    color: Colors.redAccent.withOpacity(0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 30),

            Center(
              child: Text(
                "꾸준함이 실력을 만듭니다!\n오늘도 파이팅하세요 🔥",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideStatCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
