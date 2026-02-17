import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'todays_quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  final String category;
  final String level;
  final int questionCount;

  const QuizPage({
    super.key,
    required this.category,
    required this.level,
    required this.questionCount,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Word> _quizList = [];
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
    _cacheKey = "quiz_general_${widget.category}_${widget.level}";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuiz();
    });
  }

  void _initializeQuiz() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);

    if (savedData != null) {
      List<String> savedSpellings = List<String>.from(
        savedData['spellings'] ?? [],
      );

      final wordBox = Hive.box<Word>('words');
      final allWords = wordBox.values.toList();

      _quizList = [];
      for (String spelling in savedSpellings) {
        try {
          final word = allWords.firstWhere((w) => w.spelling == spelling);
          _quizList.add(word);
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          _currentIndex = savedData['index'] ?? 0;
          List<dynamic> savedWrong = savedData['wrongAnswers'] ?? [];
          _wrongAnswersList = savedWrong
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }

      if (_quizList.isNotEmpty) {
        _generateQuizQuestions();
      }
    } else {
      _loadNewQuizData();
    }
  }

  void _saveProgress() {
    final cacheBox = Hive.box('cache');
    List<String> currentSpellings = _quizList.map((w) => w.spelling).toList();

    cacheBox.put(_cacheKey, {
      'spellings': currentSpellings,
      'index': _currentIndex,
      'wrongAnswers': _wrongAnswersList,
    });
  }

  void _clearProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.delete(_cacheKey);
  }

  void _loadNewQuizData() {
    final box = Hive.box<Word>('words');
    final allWords = box.values.toList();

    List<Word> filteredList = allWords.where((word) {
      return word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Quiz';
    }).toList();

    filteredList.shuffle();

    if (filteredList.length > widget.questionCount) {
      _quizList = filteredList.take(widget.questionCount).toList();
    } else {
      _quizList = filteredList;
    }

    if (_quizList.isNotEmpty) {
      _generateQuizQuestions();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _generateQuizQuestions() {
    final box = Hive.box<Word>('words');
    final allWordCandidates = box.values
        .where((w) => w.type == 'Word')
        .toList();

    for (var targetQuiz in _quizList) {
      String correctAnswer = targetQuiz.correctAnswer ?? "";

      List<String> distractors = allWordCandidates
          .where(
            (w) =>
                w.meaning != targetQuiz.meaning &&
                w.spelling != targetQuiz.correctAnswer,
          )
          .map((w) => w.meaning)
          .toList();

      List<String> options = [];

      if (targetQuiz.options != null && targetQuiz.options!.isNotEmpty) {
        options = List.from(targetQuiz.options!);
        options.shuffle();
      } else {
        options = [correctAnswer];
      }

      Map<String, String> optionMeanings = {};

      for (String option in options) {
        try {
          final matchingWord = allWordCandidates.firstWhere(
            (w) => w.spelling.toLowerCase() == option.toLowerCase(),
          );
          optionMeanings[option] = matchingWord.meaning;
        } catch (e) {
          optionMeanings[option] = "";
        }
      }

      _quizData.add({
        'spelling': targetQuiz.spelling,
        'correctAnswer': correctAnswer,
        'options': options,
        'meaning': targetQuiz.meaning,
        'explanation': targetQuiz.explanation,
        'optionMeanings': optionMeanings,
        'word': targetQuiz,
      });
    }
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;

    final currentQuestion = _quizData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);

    // [수정됨] 틀렸을 경우 안전하게 복사해서 저장
    if (!correct) {
      // 1. 박스가 열려있는지 확인 (안전장치)
      if (Hive.isBoxOpen('wrong_answers')) {
        final wrongBox = Hive.box<Word>('wrong_answers');

        if (currentQuestion['word'] != null) {
          final originWord = currentQuestion['word'] as Word;

          try {
            // ★ 핵심: .copy()를 사용하여 새로운 객체로 저장!
            // (Hive 충돌 방지)
            final newWord = originWord.copy();

            wrongBox.put(newWord.spelling, newWord);
            print("📝 오답노트 저장 성공: ${newWord.spelling}");
          } catch (e) {
            print("❌ 오답 저장 실패: $e");
          }
        }
      }
    }

    setState(() {
      _isChecked = true;
      _userSelectedAnswer = selectedAnswer;
      _isCorrect = correct;
    });

    if (!correct) {
      _wrongAnswersList.add({
        'spelling': currentQuestion['spelling'],
        'userAnswer': selectedAnswer,
        'correctAnswer': currentQuestion['correctAnswer'],
      });
    }
  }

  void _nextQuestion() async {
    if (_currentIndex < _quizData.length - 1) {
      setState(() {
        _currentIndex++;
        _isChecked = false;
        _userSelectedAnswer = null;
      });
      _saveProgress();
    } else {
      _clearProgress();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TodaysQuizResultPage(
            wrongAnswers: _wrongAnswersList,
            totalCount: _quizData.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("퀴즈")),
        body: const Center(child: Text("이 레벨에 해당하는 퀴즈 데이터가 부족해요 😭")),
      );
    }

    if (_quizData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = _quizData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final optionMeanings =
        currentQuestion['optionMeanings'] as Map<String, String>;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "${widget.category} ${widget.level} (${_currentIndex + 1}/${_quizList.length})",
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            _saveProgress();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("진행 상황이 저장되었습니다! 다음에 이어푸세요."),
                  duration: Duration(seconds: 1),
                ),
              );
              Navigator.pop(context);
            }
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked
                    ? (_isCorrect ? Colors.green : Colors.indigo)
                    : Colors.grey[300],
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _isChecked
                    ? ((_currentIndex < _quizData.length - 1)
                          ? "다음 문제"
                          : "결과 보기")
                    : "정답을 선택하세요",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isChecked ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 문제 카드
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentQuestion['spelling'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentQuestion['meaning'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...options.map((option) {
                  Color btnColor = Colors.white;
                  Color textColor = Colors.black;
                  Color borderColor = Colors.transparent;

                  String buttonText = option;

                  if (_isChecked) {
                    String meaning = optionMeanings[option] ?? "";
                    if (meaning.isNotEmpty) {
                      buttonText += "\n($meaning)";
                    }

                    if (option == currentQuestion['correctAnswer']) {
                      btnColor = Colors.green[100]!;
                      textColor = Colors.green[900]!;
                      borderColor = Colors.green;
                    } else if (option == _userSelectedAnswer) {
                      btnColor = Colors.red[100]!;
                      textColor = Colors.red[900]!;
                      borderColor = Colors.red;
                    } else {
                      textColor = Colors.grey;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 75,
                      child: ElevatedButton(
                        onPressed: () => _checkAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: _isChecked
                                  ? borderColor
                                  : Colors.grey.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(
                          buttonText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                if (_isChecked)
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isCorrect ? Icons.check_circle : Icons.error,
                              color: _isCorrect ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isCorrect
                                  ? "정답입니다!"
                                  : "틀렸어요! 정답: ${currentQuestion['correctAnswer']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _isCorrect
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentQuestion['explanation'] ?? "해설이 없습니다.",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
