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
  // _quizList는 순수 단어 리스트, _quizData는 보기가 포함된 퀴즈 데이터
  List<Word> _quizList = [];
  int _currentIndex = 0;
  List<Map<String, dynamic>> _quizData = [];
  List<Map<String, dynamic>> _wrongAnswersList = []; // final 제거

  bool _isChecked = false;
  bool _isCorrect = false;
  String? _userSelectedAnswer;

  // 저장소 키 (카테고리+레벨별로 따로 저장)
  late String _cacheKey;

  @override
  void initState() {
    super.initState();
    // 키 생성: quiz_general_TOEIC_500
    _cacheKey = "quiz_general_${widget.category}_${widget.level}";

    // 데이터 로드 시작
    _initializeQuiz();
  }

  void _initializeQuiz() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);

    if (savedData != null) {
      // 1. 저장된 데이터가 있으면 이어풀기 모드
      print("💾 저장된 퀴즈 불러오는 중...");

      // 저장된 단어 스펠링 리스트 가져오기
      List<String> savedSpellings = List<String>.from(
        savedData['spellings'] ?? [],
      );

      // 스펠링으로 실제 단어 객체 찾아서 _quizList 복구
      final wordBox = Hive.box<Word>('words');
      final allWords = wordBox.values.toList();

      _quizList = [];
      for (String spelling in savedSpellings) {
        try {
          final word = allWords.firstWhere((w) => w.spelling == spelling);
          _quizList.add(word);
        } catch (e) {
          print("단어 찾기 실패: $spelling");
        }
      }

      // 진행 상황 복구
      _currentIndex = savedData['index'] ?? 0;
      List<dynamic> savedWrong = savedData['wrongAnswers'] ?? [];
      _wrongAnswersList = savedWrong
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // 퀴즈 데이터 생성 (보기 생성 등)
      if (_quizList.isNotEmpty) {
        _generateQuizQuestions();
      }

      // 안내 메시지
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_currentIndex + 1}번 문제부터 이어 풉니다! ▶️")),
        );
      });
    } else {
      // 2. 저장된 게 없으면 새로 만들기 (기존 로직)
      print("✨ 새 퀴즈 생성 중...");
      _loadNewQuizData();
    }
  }

  // ★ 진행 상황 저장 (문제 목록 + 현재 위치 + 오답)
  void _saveProgress() {
    final cacheBox = Hive.box('cache');

    // 현재 풀고 있는 단어들의 스펠링 리스트 저장 (순서 유지)
    List<String> currentSpellings = _quizList.map((w) => w.spelling).toList();

    cacheBox.put(_cacheKey, {
      'spellings': currentSpellings, // 문제 목록
      'index': _currentIndex, // 현재 번호
      'wrongAnswers': _wrongAnswersList, // 틀린 목록
    });
  }

  // ★ 완료 시 데이터 삭제
  void _clearProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.delete(_cacheKey);
  }

  // 기존의 랜덤 퀴즈 생성 로직
  void _loadNewQuizData() {
    final box = Hive.box<Word>('words');
    final allWords = box.values.toList();

    List<Word> filteredList = allWords.where((word) {
      return word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Quiz';
    }).toList();

    filteredList.shuffle(); // 랜덤 섞기

    if (filteredList.length > widget.questionCount) {
      _quizList = filteredList.take(widget.questionCount).toList();
    } else {
      _quizList = filteredList;
    }

    if (_quizList.isNotEmpty) {
      _generateQuizQuestions();
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
        'word': targetQuiz, // 원본 객체 (필요 시 사용)
      });
    }
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;

    final currentQuestion = _quizData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);

    // [참고] 일반 퀴즈는 오답노트 자동 저장 안 함 (요청사항 반영)

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
      // ★ 다음 문제 넘어갈 때 저장
      _saveProgress();
    } else {
      // ★ 다 풀었으면 저장된 기록 삭제
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
    // 1. 데이터 로딩 중이거나 리스트가 비어있을 때의 예외 처리 (매우 중요!)
    if (_quizList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("퀴즈")),
        body: const Center(child: Text("이 레벨에 해당하는 퀴즈 데이터가 부족해요 😭")),
      );
    }

    if (_quizData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. 현재 문제 및 옵션 데이터 가져오기
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("진행 상황이 저장되었습니다!")));
            Navigator.pop(context);
          },
        ),
      ),

      // 하단 버튼 영역 (SafeArea 적용으로 삼성 폰 겹침 방지)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                // _isCorrect 변수가 State에 정의되어 있는지 확인하세요.
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // 체크 전엔 회색 텍스트가 가독성이 좋으면 수정 가능
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
                        currentQuestion['spelling'] ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "이 단어의 뜻은 무엇일까요?",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 선택지 버튼 리스트
                ...options.map((option) {
                  Color btnColor = Colors.white;
                  Color textColor = Colors.black;
                  Color borderColor = Colors.grey.withOpacity(0.2);

                  if (_isChecked) {
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
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () => _checkAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          foregroundColor: textColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: borderColor, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isChecked &&
                                  optionMeanings[option] != null &&
                                  optionMeanings[option]!.isNotEmpty
                              ? "$option\n(${optionMeanings[option]})"
                              : option,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // 해설 박스
                if (_isChecked)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _isCorrect ? Colors.green : Colors.red,
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
                                    : "아쉬워요! 정답은 '${currentQuestion['correctAnswer']}'",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                          if (currentQuestion['explanation'] != null) ...[
                            const SizedBox(height: 10),
                            Text(currentQuestion['explanation']),
                          ],
                        ],
                      ),
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
