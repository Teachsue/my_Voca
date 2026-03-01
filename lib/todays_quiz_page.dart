import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'word_model.dart';
import 'theme_manager.dart';
import 'todays_quiz_result_page.dart';

class TodaysQuizPage extends StatefulWidget {
  final List<Word> words;

  const TodaysQuizPage({super.key, required this.words});

  @override
  State<TodaysQuizPage> createState() => _TodaysQuizPageState();
}

class _TodaysQuizPageState extends State<TodaysQuizPage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _quizData = [];
  List<Map<String, dynamic>> _wrongAnswersList = [];

  bool _isChecked = false;
  bool _isCorrect = false;
  String? _userSelectedAnswer;
  late String _cacheKey;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    _generateQuiz();
    if (widget.words.isNotEmpty) {
      String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Word firstWord = widget.words.first;
      _cacheKey = "quiz_progress_${dateStr}_${firstWord.category}_${firstWord.level}";
    } else {
      _cacheKey = "quiz_progress_temp";
    }
    _loadProgress();
  }

  void _loadProgress() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);
    if (savedData != null) {
      setState(() {
        _currentIndex = savedData['index'] ?? 0;
        List<dynamic> savedWrong = savedData['wrongAnswers'] ?? [];
        _wrongAnswersList = savedWrong.map((e) => Map<String, dynamic>.from(e)).toList();
      });
      if (_currentIndex >= _quizData.length) {
        _currentIndex = 0;
        _wrongAnswersList.clear();
      }
    }
  }

  void _saveProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.put(_cacheKey, {'index': _currentIndex, 'wrongAnswers': _wrongAnswersList});
  }

  void _clearProgress() {
    Hive.box('cache').delete(_cacheKey);
  }

  void _generateQuiz() {
    final box = Hive.box<Word>('words');
    final allWordCandidates = box.values.where((w) => w.type == 'Word').toList();
    String dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    int dateSeed = int.parse(dateStr);
    Random randomSeed = Random(dateSeed);
    List<Word> shuffledWords = List<Word>.from(widget.words);
    shuffledWords.shuffle(randomSeed);

    for (var targetWord in shuffledWords) {
      bool isSpellingToMeaning = randomSeed.nextBool();
      String question;
      String correctAnswer;
      Map<String, String> optionInfos = {};
      List<String> options = [];

      if (isSpellingToMeaning) {
        question = targetWord.spelling;
        correctAnswer = targetWord.meaning;
        List<String> distractors = allWordCandidates.where((w) => w.meaning != correctAnswer).map((w) => w.meaning).toSet().toList();
        distractors.shuffle(randomSeed);
        options = distractors.take(3).toList();
        options.add(correctAnswer);
        options.shuffle(randomSeed);
        for (String opt in options) {
          if (opt == correctAnswer) {
            optionInfos[opt] = targetWord.spelling;
          } else {
            try {
              final matchingWord = allWordCandidates.firstWhere((w) => w.meaning == opt);
              optionInfos[opt] = matchingWord.spelling;
            } catch (e) {
              optionInfos[opt] = "";
            }
          }
        }
      } else {
        question = targetWord.meaning;
        correctAnswer = targetWord.spelling;
        List<String> distractors = allWordCandidates.where((w) => w.spelling != correctAnswer).map((w) => w.spelling).toSet().toList();
        distractors.shuffle(randomSeed);
        options = distractors.take(3).toList();
        options.add(correctAnswer);
        options.shuffle(randomSeed);
        for (String opt in options) {
          if (opt == correctAnswer) {
            optionInfos[opt] = targetWord.meaning;
          } else {
            try {
              final matchingWord = allWordCandidates.firstWhere((w) => w.spelling == opt);
              optionInfos[opt] = matchingWord.meaning;
            } catch (e) {
              optionInfos[opt] = "";
            }
          }
        }
      }
      _quizData.add({'question': question, 'correctAnswer': correctAnswer, 'options': options, 'word': targetWord, 'optionInfos': optionInfos, 'isSpellingToMeaning': isSpellingToMeaning});
    }
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;
    final currentQuestion = _quizData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);
    final word = currentQuestion['word'] as Word;
    word.updateReviewStep(correct);
    word.save();

    if (!correct) {
      final wrongBox = Hive.box<Word>('wrong_answers');
      if (currentQuestion['word'] != null) {
        final originWord = currentQuestion['word'] as Word;
        final newWord = Word(category: originWord.category, level: originWord.level, spelling: originWord.spelling, meaning: originWord.meaning, type: originWord.type, isScrap: originWord.isScrap, nextReviewDate: originWord.nextReviewDate, reviewStep: originWord.reviewStep);
        wrongBox.put(newWord.spelling, newWord);
      }
    }

    setState(() { _isChecked = true; _userSelectedAnswer = selectedAnswer; _isCorrect = correct; });
    if (!correct) {
      final String userInfo = currentQuestion['optionInfos'][selectedAnswer] ?? "";
      final String correctInfo = currentQuestion['optionInfos'][currentQuestion['correctAnswer']] ?? "";
      _wrongAnswersList.add({'spelling': (currentQuestion['word'] as Word).spelling, 'userAnswer': selectedAnswer, 'userAnswerInfo': userInfo, 'correctAnswer': currentQuestion['correctAnswer'], 'correctAnswerInfo': correctInfo});
    }
  }

  void _nextQuestion() async {
    if (_currentIndex < _quizData.length - 1) {
      setState(() { _currentIndex++; _isChecked = false; _userSelectedAnswer = null; });
      _saveProgress();
    } else {
      _clearProgress();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TodaysQuizResultPage(wrongAnswers: _wrongAnswersList, totalCount: widget.words.length, isTodaysQuiz: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgGradient = ThemeManager.bgGradient;
    if (_quizData.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentQuestion = _quizData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final optionInfos = currentQuestion['optionInfos'] as Map<String, String>;
    final bool isSpellingToMeaning = currentQuestion['isSpellingToMeaning'] ?? true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("오늘의 퀴즈 (${_currentIndex + 1}/${_quizData.length})", style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () { _saveProgress(); Navigator.pop(context); },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? (_isCorrect ? Colors.green[400] : primaryColor) : Colors.blueGrey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                _isChecked ? ((_currentIndex < _quizData.length - 1) ? "다음 문제" : "결과 보기") : "정답을 선택하세요",
                style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      Text(isSpellingToMeaning ? "단어의 뜻은?" : "뜻에 맞는 단어는?", style: TextStyle(color: Colors.blueGrey[400], fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      Text(currentQuestion['question'], textAlign: TextAlign.center, style: TextStyle(fontSize: isSpellingToMeaning ? 32 : 26, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: -0.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ...options.map((option) {
                  bool isCorrectOption = option == currentQuestion['correctAnswer'];
                  bool isSelected = option == _userSelectedAnswer;
                  Color btnColor = Colors.white.withOpacity(0.8);
                  Color textColor = const Color(0xFF1E293B);
                  String buttonText = option;
                  if (_isChecked) {
                    String info = optionInfos[option] ?? "";
                    if (info.isNotEmpty) buttonText += "\n($info)";
                    if (isCorrectOption) { btnColor = Colors.green[50]!.withOpacity(0.9); textColor = Colors.green[900]!; }
                    else if (isSelected) { btnColor = Colors.red[50]!.withOpacity(0.9); textColor = Colors.red[900]!; }
                    else { textColor = Colors.blueGrey[200]!; }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 75),
                      child: OutlinedButton(
                        onPressed: () => _checkAnswer(option),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: btnColor,
                          side: BorderSide(color: _isChecked && (isCorrectOption || isSelected) ? (isCorrectOption ? Colors.green : Colors.red) : Colors.black.withOpacity(0.03), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        ),
                        child: Text(buttonText, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textColor, fontWeight: isCorrectOption && _isChecked ? FontWeight.w900 : FontWeight.w700)),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
