import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'word_model.dart';

class DataLoader {
  // 메인 함수: 앱 켜질 때 호출됨
  static Future<void> loadData() async {
    final box = Hive.box<Word>('words');

    // 1. 이미 데이터가 있으면 로딩하지 않음 (중복 방지)
    // 개발 중에는 데이터를 싹 지우고 다시 로딩하고 싶을 때 아래 주석을 풀고 실행하세요.
    // await box.clear();

    if (box.isNotEmpty) {
      print("이미 데이터가 있습니다. 로딩 건너뜀.");
      return;
    }

    print("데이터 로딩 시작...");

    // 2. 단어 파일 읽기 (word_data.json)
    await _loadFromFile(box, 'assets/json/word_data.json');

    // 3. 퀴즈 파일 읽기 (quiz_data.json)
    await _loadFromFile(box, 'assets/json/quiz_data.json');

    print("모든 데이터 로딩 완료! 총 ${box.length}개");
  }

  // 내부 함수: 파일 하나를 읽어서 DB에 넣는 기계
  static Future<void> _loadFromFile(Box<Word> box, String filePath) async {
    try {
      final String jsonString = await rootBundle.loadString(filePath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      for (var item in jsonList) {
        final word = Word(
          category: item['category'] ?? 'Etc',
          level: item['level'] ?? 'Basic',
          spelling: item['spelling'] ?? '',
          meaning: item['meaning'] ?? '',
          type: item['type'] ?? 'Word', // JSON에 적힌 타입 그대로 사용
          // 퀴즈용 데이터 처리
          correctAnswer: item['correctAnswer'],
          options: item['options'] != null
              ? List<String>.from(item['options'])
              : null,
          explanation: item['explanation'],

          nextReviewDate: DateTime.now(),
        );
        await box.add(word);
      }
      print("-> $filePath 로딩 성공 (${jsonList.length}개)");
    } catch (e) {
      print("-> $filePath 로딩 실패: $e");
      // 파일이 없거나 오타가 있어도 앱이 꺼지지 않게 방지
    }
  }
}
