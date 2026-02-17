import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'study_record_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late final AnimationController _animationController;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    setState(() {
      _isControllerInitialized = true;
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 총 공부한 일수 계산
    final totalStudiedDays = StudyRecordService.getStudiedDays().length;
    final isTodayDone = StudyRecordService.isStudied(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "나의 공부 기록 📅",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              eventLoader: (day) {
                if (StudyRecordService.isStudied(day)) {
                  return ['Studied'];
                }
                return [];
              },

              // ★ 도장 위치 및 디자인 수정 ★
              calendarBuilders: CalendarBuilders(
                // markerBuilder에서 도장과 숫자를 Stack으로 겹쳐서 중앙에 배치합니다.
                markerBuilder: (context, date, events) {
                  if (!_isControllerInitialized || events.isEmpty) return null;

                  return Center(
                    child: Stack(
                      alignment: Alignment.center, // 자식들을 정중앙에 겹침
                      children: [
                        // 1. 하단 레이어: 별 도장 애니메이션
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.elasticOut,
                          ),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ),
                        ),
                        // 2. 상단 레이어: 날짜 숫자
                        // (Stack에서 나중에 쓴 위젯이 위로 올라옵니다.)
                        Text(
                          "${date.day}",
                          style: const TextStyle(
                            color: Colors.brown, // 도장 위에서 잘 보이는 색상
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },

                // defaultBuilder와 prioritiyBuilder 등은 markerBuilder가
                // 해당 칸을 덮어쓰므로 따로 구현하지 않아도 됩니다.
              ),

              calendarStyle: const CalendarStyle(
                markersMaxCount: 0,
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // [총 공부 일수 및 성취 배너 영역]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // 총 공부 일수 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "지금까지",
                          style: TextStyle(color: Colors.indigo, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "총 $totalStudiedDays일 공부했어요!",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 오늘 완료 여부 배너
                  isTodayDone ? _buildSuccessBanner() : _buildPendingBanner(),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 30),
          SizedBox(width: 15),
          Text(
            "오늘도 목표 달성 완료! ✨",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.orangeAccent,
            size: 28,
          ),
          SizedBox(width: 15),
          Text(
            "퀴즈를 풀고\n오늘의 별을 획득하세요!",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
