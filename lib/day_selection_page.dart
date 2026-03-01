import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'study_page.dart';
import 'quiz_page.dart';
import 'theme_manager.dart';

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
  List<List<Word>> _dayChunks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  void _loadWords() {
    final box = Hive.box<Word>('words');
    final allWords = box.values
        .where((w) =>
            w.type == 'Word' &&
            w.category == widget.category &&
            w.level == widget.level)
        .toList();

    _dayChunks = [];
    for (var i = 0; i < allWords.length; i += 20) {
      _dayChunks.add(allWords.sublist(i, min(i + 20, allWords.length)));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _checkSavedQuizAndStart() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get("quiz_progress_all_${widget.category}_${widget.level}");

    if (savedData != null) {
      _showResumeDialog(savedData);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            dayWords: _dayChunks.expand((x) => x).toList(),
            category: widget.category,
            level: widget.level,
          ),
        ),
      );
    }
  }

  void _showResumeDialog(dynamic savedData) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("퀴즈 이어 풀기", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("이전에 풀던 기록이 있습니다. 이어서 푸시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              Hive.box('cache').delete("quiz_progress_all_${widget.category}_${widget.level}");
              Navigator.pop(context);
              _checkSavedQuizAndStart();
            },
            child: Text("새로 풀기", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPage(
                    dayWords: _dayChunks.expand((x) => x).toList(),
                    category: widget.category,
                    level: widget.level,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text("이어서 풀기"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "${widget.category} ${widget.level}",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContinueBanner(context),
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 32, 28, 16),
                  child: Text(
                    "학습 리스트",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _dayChunks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _dayChunks.length) return _buildTotalQuizCard(context);
                      return _buildDayCard(context, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildContinueBanner(BuildContext context) {
    final cacheBox = Hive.box('cache');
    final int lastStudiedDay = cacheBox.get('last_studied_day_${widget.category}_${widget.level}', defaultValue: 1);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyPage(
                category: widget.category,
                level: widget.level,
                allDayChunks: _dayChunks,
                initialDayIndex: lastStudiedDay - 1,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DAY $lastStudiedDay 이어하기",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "멈췄던 부분부터 바로 시작",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int index) {
    final int dayNumber = index + 1;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cacheBox = Hive.box('cache');
    final int lastDay = cacheBox.get('last_studied_day_${widget.category}_${widget.level}', defaultValue: 1);
    final bool isCurrent = lastDay == dayNumber;

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
          color: isCurrent ? primaryColor.withOpacity(0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrent ? primaryColor : const Color(0xFFF1F5F9),
            width: isCurrent ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$dayNumber",
              style: TextStyle(
                fontSize: 34, // ★ 숫자 크기 확대
                fontWeight: FontWeight.w900, 
                color: isCurrent ? primaryColor : const Color(0xFF1E293B),
                letterSpacing: -1.0
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "DAY",
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w900, 
                color: isCurrent ? primaryColor : const Color(0xFF94A3B8),
                letterSpacing: 1.0
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalQuizCard(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: _checkSavedQuizAndStart,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 30),
            SizedBox(height: 8),
            Text(
              "전체 퀴즈",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
