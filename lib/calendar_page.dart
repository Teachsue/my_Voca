import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'study_record_service.dart'; // 방금 만든 서비스

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    // 공부한 날짜들 가져오기
    final studiedDays = StudyRecordService.getStudiedDays();

    return Scaffold(
      appBar: AppBar(
        title: const Text("나의 공부 기록 📅"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // [달력 위젯]
          TableCalendar(
            locale: 'ko_KR', // 한국어 달력 (main.dart 설정 필요, 일단 영어로 나올 수 있음)
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,

            // 1. 오늘 날짜 선택 로직
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            // 2. ★ 도장 찍기 로직 (이 날짜 공부했니?)
            eventLoader: (day) {
              if (StudyRecordService.isStudied(day)) {
                return ['Studied']; // 뭐라도 리스트를 리턴하면 점이 찍힘
              }
              return [];
            },

            // 3. 달력 스타일 꾸미기
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              // 도장(이벤트) 찍힌 날짜 스타일
              markerDecoration: const BoxDecoration(
                color: Colors.green, // 초록색 점
                shape: BoxShape.circle,
              ),
            ),

            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // '2주', '1주' 보기 버튼 숨김
              titleCentered: true,
            ),
          ),

          const SizedBox(height: 30),

          // [하단 메시지]
          if (StudyRecordService.isStudied(DateTime.now()))
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                  SizedBox(width: 10),
                  Text(
                    "오늘 목표 달성! 참 잘했어요 👏",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            const Text(
              "아직 오늘의 목표를 달성하지 못했어요.\n퀴즈를 풀어보세요! 💪",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
        ],
      ),
    );
  }
}
