import 'package:flutter/material.dart';
import 'word_model.dart';
import 'todays_quiz_page.dart';
import 'theme_manager.dart';

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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isCompleted ? "복습 리스트" : "오늘의 단어",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 상단 상태 정보
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isCompleted ? "오늘의 모든 단어를 확인했습니다!" : "새로운 10개의 단어를 확인해 보세요",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // 단어 리스트 (글자 크기 대폭 확대)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 120),
              itemCount: words.length,
              separatorBuilder: (context, index) => Divider(color: Colors.black.withOpacity(0.05), height: 1),
              itemBuilder: (context, index) {
                final word = words[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primaryColor.withOpacity(0.3),
                          fontFamily: 'Monospace',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.spelling,
                              style: const TextStyle(
                                fontSize: 26, // ★ 단어 크기 확대
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              word.meaning,
                              style: const TextStyle(
                                fontSize: 18, // ★ 뜻 크기 확대
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
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
        ],
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: double.infinity,
          height: 68, // ★ 버튼 더 큼직하게
          child: ElevatedButton(
            onPressed: () {
              if (isCompleted) {
                Navigator.pop(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodaysQuizPage(words: words),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCompleted ? "확인 완료" : "암기 완료! 퀴즈 시작",
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
