import 'package:hive/hive.dart';

part 'word_model.g.dart';

@HiveType(typeId: 0)
class Word extends HiveObject {
  @HiveField(0)
  String spelling;

  @HiveField(1)
  String meaning;

  @HiveField(2)
  DateTime nextReviewDate; // 복습 날짜

  @HiveField(3)
  int reviewInterval; // 복습 간격

  @HiveField(4)
  double easeFactor; // 난이도 계수

  @HiveField(5)
  String category;

  @HiveField(6)
  String level;

  @HiveField(7)
  String type; // 'Word' 또는 'Quiz'

  @HiveField(8)
  String? correctAnswer; // 정답 (퀴즈용)

  @HiveField(9)
  List<String>? options; // 보기 (퀴즈용)

  @HiveField(10)
  String? explanation; // 해설 (퀴즈용)

  // 생성자
  Word({
    required this.spelling,
    required this.meaning,
    DateTime? nextReviewDate, // 선택 사항 (없으면 현재 시간)
    this.reviewInterval = 0,
    this.easeFactor = 2.5,
    required this.category,
    required this.level,
    required this.type,
    this.correctAnswer,
    this.options,
    this.explanation,
  }) : this.nextReviewDate = nextReviewDate ?? DateTime.now();

  // ★ HiveError 방지용 복제 함수 (이걸 쓰면 코드가 훨씬 깔끔해져요!)
  Word copy() {
    return Word(
      spelling: this.spelling,
      meaning: this.meaning,
      nextReviewDate: this.nextReviewDate,
      reviewInterval: this.reviewInterval,
      easeFactor: this.easeFactor,
      category: this.category,
      level: this.level,
      type: this.type,
      correctAnswer: this.correctAnswer,
      options: this.options != null ? List<String>.from(this.options!) : null,
      explanation: this.explanation,
    );
  }
}
