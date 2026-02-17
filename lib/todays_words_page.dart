import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'word_model.dart';
import 'todays_quiz_page.dart';

class TodaysWordsPage extends StatefulWidget {
  // ★ 카테고리와 레벨을 외부에서 받아옵니다.
  final String category;
  final String level;

  const TodaysWordsPage({
    super.key,
    required this.category,
    required this.level,
  });

  @override
  State<TodaysWordsPage> createState() => _TodaysWordsPageState();
}

class _TodaysWordsPageState extends State<TodaysWordsPage> {
  List<Word> _todaysWords = [];

  @override
  void initState() {
    super.initState();
    _loadOrGenerateTodaysWords();
  }

  void _loadOrGenerateTodaysWords() {
    final wordBox = Hive.box<Word>('words');
    final cacheBox = Hive.box('cache');

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // ★ 캐시 키(Key)를 난이도별로 다르게 만듭니다.
    // 예: "2024-02-14_TOEIC_700"
    String cacheKey = "${todayStr}_${widget.category}_${widget.level}";

    // 1. 저장된 키 목록 확인
    List<dynamic>? storedKeys = cacheBox.get(cacheKey);

    if (storedKeys != null && storedKeys.isNotEmpty) {
      // CASE A: 오늘 이 난이도로 이미 뽑은 적이 있음 -> 저장된 것 불러오기
      print(
        "📅 [${widget.category} ${widget.level}] 오늘은 이미 뽑았습니다. 저장된 걸 보여줍니다.",
      );

      _todaysWords = storedKeys
          .map((key) => wordBox.get(key))
          .whereType<Word>()
          .toList();
    } else {
      // CASE B: 처음 뽑음 -> 조건에 맞는 단어만 추려서 랜덤 5개
      print("✨ [${widget.category} ${widget.level}] 새로운 단어를 뽑습니다!");

      // ★ 필터링: 타입이 Word이고, 카테고리와 레벨이 맞는 것만!
      final filteredWords = wordBox.values.where((word) {
        return word.type == 'Word' &&
            word.category == widget.category &&
            word.level == widget.level;
      }).toList();

      if (filteredWords.isNotEmpty) {
        filteredWords.shuffle(); // 섞기

        // 10개 뽑기 (데이터가 10개보다 적으면 있는 만큼만)
        _todaysWords = filteredWords.take(10).toList();

        // 키 저장
        List<int> keysToSave = _todaysWords.map((w) => w.key as int).toList();
        cacheBox.put(cacheKey, keysToSave);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // 제목에 난이도 표시
        title: Text("오늘의 ${widget.category} ${widget.level} 🔥"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _todaysWords.isEmpty
          ? Center(
              child: Text(
                "${widget.category} ${widget.level} 단어가\n아직 충분하지 않아요! 😭",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _todaysWords.length,
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final word = _todaysWords[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.spelling,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 16,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _todaysWords.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // 퀴즈 페이지로 이동 (단어 목록 전달)
                    builder: (context) => TodaysQuizPage(words: _todaysWords),
                  ),
                );
              },
              backgroundColor: Colors.indigoAccent,
              icon: const Icon(Icons.quiz),
              label: const Text(
                "퀴즈로 복습하기",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
