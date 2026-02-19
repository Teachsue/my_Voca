import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // ★ 추가: 날짜 저장을 위한 패키지
import 'word_model.dart';

class LevelTestPage extends StatefulWidget {
  const LevelTestPage({super.key});

  @override
  State<LevelTestPage> createState() => _LevelTestPageState();
}

class _LevelTestPageState extends State<LevelTestPage> {
  List<Map<String, dynamic>> _testData = [];
  int _currentIndex = 0;
  int _score = 0;

  Map<String, int> _levelScores = {'500': 0, '700': 0, '900+': 0};

  bool _isChecked = false;
  String? _userSelectedAnswer;
  bool _isCorrect = false;

  final String _cacheKey = "level_test_progress";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProgressAndInitialize();
    });
  }

  void _checkProgressAndInitialize() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);

    if (savedData != null) {
      int savedIndex = savedData['index'] ?? 0;
      if (savedIndex > 0) {
        _showResumeDialog(savedData);
      } else {
        _clearProgress();
        _generateLevelTestData();
      }
    } else {
      _generateLevelTestData();
    }
  }

  void _showResumeDialog(dynamic savedData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "테스트 이어 풀기",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("이전에 진행 중이던 실력 진단 기록이 있습니다.\n이어서 푸시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              _clearProgress();
              Navigator.pop(context);
              _generateLevelTestData();
            },
            child: const Text("새로 풀기", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreFromCache(savedData);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text("이어서 풀기", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _restoreFromCache(dynamic savedData) {
    setState(() {
      _currentIndex = savedData['index'] ?? 0;
      _score = savedData['score'] ?? 0;

      final Map<dynamic, dynamic> rawScores =
          savedData['levelScores'] ?? {'500': 0, '700': 0, '900+': 0};
      _levelScores = rawScores.map((k, v) => MapEntry(k.toString(), v as int));

      _testData = (savedData['testData'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  void _generateLevelTestData() {
    final box = Hive.box<Word>('words');
    final allWords = box.values.where((w) => w.type == 'Word').toList();

    List<Word> testPool = [];
    final levels = ['500', '700', '900+'];

    for (var level in levels) {
      final levelWords = allWords.where((w) => w.level == level).toList();
      levelWords.shuffle();
      testPool.addAll(levelWords.take(5));
    }

    _testData = [];
    for (var word in testPool) {
      String correctAnswer = word.meaning;

      List<Word> distractors = allWords
          .where((w) => w.meaning != correctAnswer)
          .toList();
      distractors.shuffle();
      List<Word> selectedDistractors = distractors.take(3).toList();

      Map<String, String> meaningToSpelling = {correctAnswer: word.spelling};
      for (var d in selectedDistractors) {
        meaningToSpelling[d.meaning] = d.spelling;
      }

      List<String> options = meaningToSpelling.keys.toList();
      options.shuffle();

      _testData.add({
        'question': word.spelling,
        'correctAnswer': correctAnswer,
        'options': options,
        'meaningToSpelling': meaningToSpelling,
        'level': word.level,
      });
    }

    _saveProgress();
    setState(() {});
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;

    final currentQuestion = _testData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);

    if (correct) {
      _score++;
      String level = currentQuestion['level'];
      _levelScores[level] = (_levelScores[level] ?? 0) + 1;
    }

    setState(() {
      _isChecked = true;
      _userSelectedAnswer = selectedAnswer;
      _isCorrect = correct;
    });

    _saveProgress();
  }

  void _nextQuestion() {
    if (_currentIndex < _testData.length - 1) {
      setState(() {
        _currentIndex++;
        _isChecked = false;
        _userSelectedAnswer = null;
      });
      _saveProgress();
    } else {
      _clearProgress();
      _showResultDialog();
    }
  }

  void _saveProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.put(_cacheKey, {
      'index': _currentIndex,
      'score': _score,
      'levelScores': _levelScores,
      'testData': _testData,
    });
  }

  void _clearProgress() {
    Hive.box('cache').delete(_cacheKey);
  }

  void _showResultDialog() {
    String recommendedLevel = '500';

    // ★ 수정된 판정 로직
    // 1순위 (900+): 상급 3개 이상 '동시에' 중급 4개 이상 & 초급 4개 이상 정답
    if (_levelScores['900+']! >= 3 &&
        _levelScores['700']! >= 4 &&
        _levelScores['500']! >= 4) {
      recommendedLevel = '900+';
    }
    // 2순위 (700): 상급 조건은 미달이지만, 중급 3개 이상 '동시에' 초급 3개 이상 정답
    else if (_levelScores['700']! >= 3 && _levelScores['500']! >= 3) {
      recommendedLevel = '700';
    }
    // 그 외: 500 레벨로 배정
    else {
      recommendedLevel = '500';
    }

    // 테스트 완료 날짜와 추천 레벨 저장
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Hive.box('cache').put('user_recommended_level', recommendedLevel);
    Hive.box('cache').put('level_test_completed_date', todayStr);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "테스트 결과 📊",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "총 점수: $_score / ${_testData.length}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 15),
            const Text("분석 결과, 사용자님께 추천하는 레벨은", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              "TOEIC $recommendedLevel", // TOEIC 문구 추가로 가독성 향상
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Text("입니다!", style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "확인",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_testData.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentQuestion = _testData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final Map<dynamic, dynamic> rawMap =
        currentQuestion['meaningToSpelling'] ?? {};
    final Map<String, String> meaningToSpelling = rawMap.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("실력 진단 테스트 (${_currentIndex + 1}/${_testData.length})"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            _saveProgress();
            Navigator.pop(context);
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? Colors.indigo : Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _testData.length - 1 ? "다음 문제" : "결과 확인",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                currentQuestion['question'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ...options.map((option) {
              bool isCorrectOption = option == currentQuestion['correctAnswer'];
              bool isSelected = option == _userSelectedAnswer;

              Color btnColor = Colors.white;
              Color borderCol = Colors.grey[300]!;
              Color textColor = Colors.black87;

              if (_isChecked) {
                if (isCorrectOption) {
                  btnColor = Colors.green[50]!;
                  borderCol = Colors.green;
                  textColor = Colors.green[900]!;
                } else if (isSelected) {
                  btnColor = Colors.red[50]!;
                  borderCol = Colors.red;
                  textColor = Colors.red[900]!;
                } else {
                  textColor = Colors.grey;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Container(
                  width: double.infinity,
                  height: 85,
                  child: OutlinedButton(
                    onPressed: () => _checkAnswer(option),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: btnColor,
                      side: BorderSide(color: borderCol, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                    ),
                    child: Text(
                      _isChecked
                          ? "$option\n(${meaningToSpelling[option]})"
                          : option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isCorrectOption && _isChecked
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
