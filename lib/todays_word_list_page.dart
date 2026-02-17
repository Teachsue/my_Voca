import 'package:flutter/material.dart';
import 'word_model.dart';
import 'todays_quiz_page.dart';

class TodaysWordListPage extends StatelessWidget {
  final List<Word> words;
  final bool isCompleted;

  const TodaysWordListPage({
    super.key,
    required this.words,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(isCompleted ? "오늘의 단어 복습" : "오늘의 단어 학습"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 상단 안내 메시지
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: isCompleted
                ? Colors.green.withOpacity(0.05)
                : Colors.indigo.withOpacity(0.05),
            child: Column(
              children: [
                Text(
                  isCompleted ? "오늘의 학습을 완료했습니다! 🎉" : "오늘 암기할 단어들입니다! 🧐",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted ? "가볍게 훑어보며 복습해보세요." : "가볍게 훑어본 뒤 퀴즈에 도전하세요.",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),

          // 단어 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade50
                              : Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green.shade700
                                : Colors.indigo.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.spelling,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
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

          // 하단 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (isCompleted) {
                      // 완료된 상태면 그냥 닫기
                      Navigator.pop(context);
                    } else {
                      // 퀴즈 시작 (기다리지 않고 이동만 함)
                      // ★ [중요 수정] await와 pop을 제거했습니다.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TodaysQuizPage(words: words),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.green : Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isCompleted ? "복습 완료 (메인으로)" : "다 외웠어요! 퀴즈 시작",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
