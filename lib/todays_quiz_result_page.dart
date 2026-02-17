import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 추가
import 'package:intl/intl.dart'; // 추가
import 'study_record_service.dart'; // 추가

class TodaysQuizResultPage extends StatelessWidget {
  final List<Map<String, dynamic>> wrongAnswers;
  final int totalCount;

  const TodaysQuizResultPage({
    super.key,
    required this.wrongAnswers,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    bool isPerfect = wrongAnswers.isEmpty;
    int score = totalCount - wrongAnswers.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: isPerfect
            ? _buildPerfectView(context)
            : _buildWrongAnswerView(context, score),
      ),
    );
  }

  // 1. 만점 화면 (여기서만 '완료' 처리를 합니다)
  Widget _buildPerfectView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 100,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "만점이에요! 🎉",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "틀린 문제가 하나도 없네요.\n오늘 학습 목표를 완벽하게 달성했어요!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // ★ [핵심] 만점일 때만 완료 데이터 저장
                  final cacheBox = Hive.box('cache');
                  final String todayStr = DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.now());

                  // 오늘 완료 여부 저장
                  cacheBox.put("today_completed_$todayStr", true);

                  // 학습 기록 서비스에 완료 보고 (배너 색상 변경용)
                  await StudyRecordService.markTodayAsDone();

                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "학습 완료 (메인으로)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. 오답 화면 (저장 로직 없이 메인으로 돌아갑니다)
  Widget _buildWrongAnswerView(BuildContext context, int score) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "아쉬워요! 조금만 더 힘내세요 💪",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                "$score / $totalCount",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${wrongAnswers.length}개를 틀렸어요. 다시 도전해볼까요?",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: wrongAnswers.length,
            itemBuilder: (context, index) {
              final item = wrongAnswers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['spelling'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "내가 쓴 답: ${item['userAnswer']}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "정답: ${item['correctAnswer']}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // 저장 로직 없이 메인으로 돌아감 -> 배너는 여전히 파란색(미완료)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              child: const Text(
                "다시 도전하기",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
