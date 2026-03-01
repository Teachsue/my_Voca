import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'study_record_service.dart';
import 'theme_manager.dart';

class TodaysQuizResultPage extends StatelessWidget {
  final List<Map<String, dynamic>> wrongAnswers;
  final int totalCount;
  final bool isTodaysQuiz;

  const TodaysQuizResultPage({
    super.key,
    required this.wrongAnswers,
    required this.totalCount,
    this.isTodaysQuiz = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isPerfect = wrongAnswers.isEmpty;
    int score = totalCount - wrongAnswers.length;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgGradient = ThemeManager.bgGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: isPerfect
              ? _buildPerfectView(context, primaryColor)
              : _buildWrongAnswerView(context, score, primaryColor),
        ),
      ),
    );
  }

  Widget _buildPerfectView(BuildContext context, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: color,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              "참 잘했어요! 🎉",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTodaysQuiz
                  ? "오늘의 목표를 완벽히 달성했습니다.\n꾸준함이 실력을 만듭니다."
                  : "모든 문제를 맞히셨습니다.\n정말 대단해요!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.6, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () async {
                  if (isTodaysQuiz) {
                    final cacheBox = Hive.box('cache');
                    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    cacheBox.put("today_completed_$todayStr", true);
                    await StudyRecordService.markTodayAsDone();
                  }
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text("완료 (메인으로)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongAnswerView(BuildContext context, int score, Color color) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Text(
                isTodaysQuiz ? "조금 더 힘내볼까요? 💪" : "퀴즈 결과",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$score",
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: color),
                  ),
                  Text(
                    " / $totalCount",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "오답을 확인하고 재도전해 보세요.",
                style: TextStyle(color: Color(0xFF475569), fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: wrongAnswers.length,
            itemBuilder: (context, index) {
              final item = wrongAnswers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['spelling'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("내가 고른 답", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                item['userAnswer'] ?? '',
                                style: const TextStyle(color: Colors.redAccent, decoration: TextDecoration.lineThrough, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFE2E8F0)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("올바른 정답", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                item['correctAnswer'] ?? '',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text("다시 시도하기", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }
}
