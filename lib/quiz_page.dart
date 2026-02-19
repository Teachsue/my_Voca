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
      final Set<String> seenNormalized = {};

      for (String spelling in savedSpellings) {
        final normalized = spelling.trim().toLowerCase();
        if (seenNormalized.contains(normalized)) continue;

        try {
          final word = allWords.firstWhere(
            (w) => w.spelling.trim().toLowerCase() == normalized,
          );
          _quizList.add(word);
          seenNormalized.add(normalized);
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

    final Map<String, Word> uniqueQuizMap = {};

    for (var word in allWords) {
      if (word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Quiz') {
        final key = word.spelling.trim().toLowerCase();
        if (!uniqueQuizMap.containsKey(key)) {
          uniqueQuizMap[key] = word;
        }
      }
    }

    List<Word> filteredList = uniqueQuizMap.values.toList();
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
    final allWords = box.values.toList();

    _quizData = [];

    for (var targetQuiz in _quizList) {
      String correctAnswer = targetQuiz.correctAnswer ?? "";
      List<String> options = [];

      if (targetQuiz.options != null && targetQuiz.options!.isNotEmpty) {
        options = targetQuiz.options!.map((o) => o.trim()).toSet().toList();
        options.shuffle();
      } else {
        options = [correctAnswer];
      }

      Map<String, String> optionMeanings = {};

      for (String option in options) {
        final normalizedOption = option.trim().toLowerCase();
        String foundMeaning = "뜻 없음";

        try {
          // 1단계: 정확히 일치하는 Word 타입 검색
          final exactMatch = allWords.firstWhere(
            (w) =>
                w.type == 'Word' &&
                w.spelling.trim().toLowerCase() == normalizedOption,
          );
          foundMeaning = exactMatch.meaning;
        } catch (_) {
          try {
            // 2단계 (중요): 변형어 처리 (follows -> follow, followed -> follow 검색)
            // 선택지 글자가 단어장 단어로 시작하는지 체크 (예: 'follows' startsWith 'follow')
            final stemMatch = allWords.firstWhere(
              (w) =>
                  w.type == 'Word' &&
                  normalizedOption.startsWith(
                    w.spelling.trim().toLowerCase(),
                  ) &&
                  w.spelling.length > 2, // 'a', 'to' 같은 짧은 단어 방지
            );
            foundMeaning = stemMatch.meaning;
          } catch (_) {
            // 3단계: 정답과 같은 경우 퀴즈 데이터 자체의 뜻을 활용
            if (normalizedOption == correctAnswer.trim().toLowerCase()) {
              foundMeaning = targetQuiz.meaning;
            }
          }
        }
        optionMeanings[option] = foundMeaning;
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
    final Map<String, String> optionMeanings = Map<String, String>.from(
      currentQuestion['optionMeanings'] ?? {},
    );

    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);

    if (!correct) {
      if (Hive.isBoxOpen('wrong_answers')) {
        final wrongBox = Hive.box<Word>('wrong_answers');

        if (currentQuestion['word'] != null) {
          final originWord = currentQuestion['word'] as Word;
          final String correctSpelling = currentQuestion['correctAnswer'] ?? "";
          String realWordMeaning =
              optionMeanings[correctSpelling] ?? originWord.meaning;

          try {
            final wordForWrongNote = Word(
              category: originWord.category,
              level: originWord.level,
              type: 'Word',
              spelling: correctSpelling,
              meaning: realWordMeaning,
            );
            wrongBox.put(wordForWrongNote.spelling, wordForWrongNote);
          } catch (e) {}
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
        'userAnswerMeaning': optionMeanings[selectedAnswer] ?? "뜻 없음",
        'correctAnswer': currentQuestion['correctAnswer'],
        'correctAnswerMeaning':
            optionMeanings[currentQuestion['correctAnswer']] ?? "뜻 없음",
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
    final optionMeanings = Map<String, String>.from(
      currentQuestion['optionMeanings'] ?? {},
    );

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
                    if (meaning.isNotEmpty && meaning != "뜻 없음") {
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isCorrect ? Icons.check_circle : Icons.error,
                              color: _isCorrect ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isCorrect
                                    ? "정답입니다!\n${currentQuestion['correctAnswer']} (${optionMeanings[currentQuestion['correctAnswer']] ?? '뜻 없음'})"
                                    : "내가 쓴 답 : $_userSelectedAnswer (${optionMeanings[_userSelectedAnswer] ?? '뜻 없음'})\n정답 : ${currentQuestion['correctAnswer']} (${optionMeanings[currentQuestion['correctAnswer']] ?? '뜻 없음'})",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  height: 1.5,
                                  color: _isCorrect
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "💡 해설",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
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
