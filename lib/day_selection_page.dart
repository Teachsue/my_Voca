import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'study_page.dart';
import 'quiz_page.dart'; // ★ 추가: 퀴즈 페이지로 가기 위해 import

class DaySelectionPage extends StatefulWidget {
  final String category;
  final String level;

  const DaySelectionPage({
    super.key,
    required this.category,
    required this.level,
  });

  @override
  State<DaySelectionPage> createState() => _DaySelectionPageState();
}

class _DaySelectionPageState extends State<DaySelectionPage> {
  final int _wordsPerDay = 20;
  List<List<Word>> _dayChunks = [];

  @override
  void initState() {
    super.initState();
    _loadAndChunkDays();
  }

  void _loadAndChunkDays() {
    final box = Hive.box<Word>('words');

    List<Word> filteredList = box.values.where((word) {
      return word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Word';
    }).toList();

    final Map<String, Word> uniqueMap = {};
    for (var w in filteredList) {
      uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
    }

    List<Word> finalPool = uniqueMap.values.toList();
    // 알파벳 순으로 정렬하여 DAY 구성이 항상 일정하도록 고정
    finalPool.sort(
      (a, b) => a.spelling.toLowerCase().compareTo(b.spelling.toLowerCase()),
    );

    _dayChunks = [];
    for (var i = 0; i < finalPool.length; i += _wordsPerDay) {
      int end = (i + _wordsPerDay < finalPool.length)
          ? i + _wordsPerDay
          : finalPool.length;
      _dayChunks.add(finalPool.sublist(i, end));
    }

    setState(() {});
  }

  // ★ 추가: DAY 클릭 시 뜨는 모드 선택 팝업
  void _showDayActionDialog(int dayNumber, List<Word> dayWords) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "DAY $dayNumber",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("어떤 학습을 진행할까요?"),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext); // 다이얼로그 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudyPage(
                      category: widget.category,
                      level: widget.level,
                      dayNumber: dayNumber,
                      dayWords: dayWords, // 단어장으로 데이터 전달
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: const Text("단어장"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext); // 다이얼로그 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(
                      category: widget.category,
                      level: widget.level,
                      questionCount: 0, // DAY 퀴즈는 개수가 아닌 dayWords 기준으로 작동
                      dayNumber: dayNumber, // DAY 번호 전달 (캐시 분리용)
                      dayWords: dayWords, // ★ 핵심: 해당 DAY의 단어만 퀴즈로 던짐
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text("단어시험"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dayChunks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("${widget.category} ${widget.level}")),
        body: const Center(child: Text("학습할 단어가 없습니다.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${widget.category} ${widget.level} 학습하기"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.0,
        ),
        itemCount: _dayChunks.length,
        itemBuilder: (context, index) {
          final int dayNumber = index + 1;
          final int wordCount = _dayChunks[index].length;

          return GestureDetector(
            // ★ 변경: 카드를 누르면 다이얼로그 호출
            onTap: () => _showDayActionDialog(dayNumber, _dayChunks[index]),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "DAY",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$dayNumber",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$wordCount 단어",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
