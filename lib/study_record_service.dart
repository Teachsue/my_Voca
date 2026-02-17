import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class StudyRecordService {
  static const String boxName = 'study_records';

  // 1. DB 열기 (앱 켤 때 한 번 호출)
  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  // 2. 오늘 공부 완료! 도장 찍기
  static Future<void> markTodayAsDone() async {
    final box = Hive.box(boxName);

    // 오늘 날짜를 '2024-02-14' 형태로 변환
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 저장 (Key: 날짜, Value: true)
    await box.put(today, true);
    print("출석 도장 쾅! ($today)");
  }

  // 3. 특정 날짜에 공부했는지 확인하기
  static bool isStudied(DateTime date) {
    final box = Hive.box(boxName);
    final String key = DateFormat('yyyy-MM-dd').format(date);

    // 값이 있으면 true, 없으면 false
    return box.get(key, defaultValue: false);
  }

  // 4. 이번 달 공부한 날짜 싹 다 가져오기 (달력에 점 찍기용)
  static List<DateTime> getStudiedDays() {
    final box = Hive.box(boxName);
    List<DateTime> studiedDays = [];

    for (var key in box.keys) {
      // 저장된 날짜 문자열을 다시 날짜 객체로 변환해서 리스트에 담음
      studiedDays.add(DateTime.parse(key));
    }
    return studiedDays;
  }
}
