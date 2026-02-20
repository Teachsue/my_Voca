import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'study_page.dart';
import 'quiz_page.dart';

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

    // 시드 값을 이용해 고정된 랜덤 순서로 섞기
    int seed = (widget.category + widget.level).hashCode;
    finalPool.shuffle(Random(seed));

    _dayChunks = [];
    for (var i = 0; i < finalPool.length; i += _wordsPerDay) {
      int end = (i + _wordsPerDay < finalPool.length)
          ? i + _wordsPerDay
          : finalPool.length;
      _dayChunks.add(finalPool.sublist(i, end));
    }
    // ==========================================
    // ★ 수정된 로직: 짜투리 단어 합치기 (10개 미만일 때만)
    // ==========================================
    // 청크가 2개 이상이고, 마지막 청크의 단어가 10개 미만일 때만 합칩니다.
    if (_dayChunks.length > 1 && _dayChunks.last.length < 10) {
      // 마지막 짜투리 DAY를 리스트에서 빼옵니다.
      List<Word> leftoverChunk = _dayChunks.removeLast();

      // 그 앞의 DAY(이제 마지막이 된 DAY)에 짜투리 단어들을 전부 더해줍니다.
      List<Word> mergedChunk = List<Word>.from(_dayChunks.last);
      mergedChunk.addAll(leftoverChunk);

      _dayChunks[_dayChunks.length - 1] = mergedChunk;
    }

    setState(() {});
  }

  void _checkSavedQuizAndStart() {
    final cacheBox = Hive.box('cache');
    final String cacheKey = "quiz_match_${widget.category}_${widget.level}";
    final savedData = cacheBox.get(cacheKey);

    if (savedData != null && (savedData['index'] ?? 0) > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            category: widget.category,
            level: widget.level,
            questionCount: 0,
          ),
        ),
      );
    } else {
      cacheBox.delete(cacheKey);
      _showQuestionCountDialog();
    }
  }

  void _showQuestionCountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "문제 수 선택",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [10, 20, 30].map((count) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(
                      category: widget.category,
                      level: widget.level,
                      questionCount: count,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 8.0,
                ),
                child: Text(
                  "$count문제",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
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
        itemCount: _dayChunks.length + 1,
        itemBuilder: (context, index) {
          if (index == _dayChunks.length) {
            return GestureDetector(
              onTap: _checkSavedQuizAndStart,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B86E5).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_alt_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "전체 퀴즈",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final int dayNumber = index + 1;
          final int wordCount = _dayChunks[index].length;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudyPage(
                    category: widget.category,
                    level: widget.level,
                    allDayChunks: _dayChunks,
                    initialDayIndex: index,
                  ),
                ),
              );
            },
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
                    // ★ 이제 20 단어, 25 단어 등 유동적인 숫자가 예쁘게 표시됩니다.
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
