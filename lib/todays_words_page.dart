import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'word_model.dart';
import 'todays_quiz_page.dart';
import 'theme_manager.dart';

class TodaysWordsPage extends StatefulWidget {
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
    String cacheKey = "${todayStr}_${widget.category}_${widget.level}";
    List<dynamic>? storedKeys = cacheBox.get(cacheKey);

    if (storedKeys != null && storedKeys.isNotEmpty) {
      _todaysWords = storedKeys.map((key) => wordBox.get(key)).whereType<Word>().toList();
    } else {
      final filteredWords = wordBox.values.where((word) {
        return word.type == 'Word' && word.category == widget.category && word.level == widget.level;
      }).toList();

      if (filteredWords.isNotEmpty) {
        filteredWords.shuffle();
        _todaysWords = filteredWords.take(10).toList();
        List<int> keysToSave = _todaysWords.map((w) => w.key as int).toList();
        cacheBox.put(cacheKey, keysToSave);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgGradient = ThemeManager.bgGradient;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("오늘의 ${widget.category} ${widget.level}", style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: _todaysWords.isEmpty
            ? const Center(child: Text("학습할 단어가 아직 충분하지 않아요! 😭", style: TextStyle(fontSize: 18, color: Colors.grey)))
            : SafeArea(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: _todaysWords.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final word = _todaysWords[index];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: primaryColor.withOpacity(0.4),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
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
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  word.meaning,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.blueGrey[500],
                                    fontWeight: FontWeight.w600,
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _todaysWords.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TodaysQuizPage(words: _todaysWords)));
              },
              backgroundColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.quiz_rounded, color: Colors.white),
              label: const Text("퀴즈로 복습하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              elevation: 4,
            ),
    );
  }
}
