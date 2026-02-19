import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';

class StudyPage extends StatefulWidget {
  final String category;
  final String level;

  const StudyPage({super.key, required this.category, required this.level});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  List<Word> _allWords = [];
  List<Word> _currentWords = [];

  int _currentPage = 1;
  final int _itemsPerPage = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ★ 추가: 페이지 이동 다이얼로그 함수
  void _showJumpToPageDialog() {
    final int totalPages = (_allWords.length / _itemsPerPage).ceil();
    final TextEditingController pageEditingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("페이지 이동"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("이동할 페이지를 입력하세요. (1 ~ $totalPages)"),
              TextField(
                controller: pageEditingController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(hintText: "페이지 번호"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                final int? targetPage = int.tryParse(
                  pageEditingController.text,
                );
                if (targetPage != null &&
                    targetPage >= 1 &&
                    targetPage <= totalPages) {
                  _changePage(targetPage); // 기존에 만든 페이지 변경 함수 호출
                  Navigator.pop(context);
                } else {
                  // 범위를 벗어난 경우 스낵바 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("1에서 $totalPages 사이의 숫자를 입력해주세요.")),
                  );
                }
              },
              child: const Text("이동"),
            ),
          ],
        );
      },
    );
  }

  void _loadData() {
    final box = Hive.box<Word>('words');

    _allWords = box.values.where((word) {
      return word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Word';
    }).toList();

    _updatePageData();
  }

  void _updatePageData() {
    if (_allWords.isEmpty) {
      _currentWords = [];
      return;
    }

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = min(startIndex + _itemsPerPage, _allWords.length);

    setState(() {
      _currentWords = _allWords.sublist(startIndex, endIndex);
    });
  }

  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
      _updatePageData();
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_allWords.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("${widget.category} ${widget.level}"), // 제목 간소화
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        // ★ 추가: AppBar 우측에 검색 아이콘 추가
        actions: [
          IconButton(
            icon: const Icon(Icons.find_in_page_outlined),
            onPressed: _showJumpToPageDialog, // 다이얼로그 호출
            tooltip: "페이지 이동",
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              "총 ${_allWords.length}개 단어 중 ${_currentWords.length}개 표시",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),

          Expanded(
            child: _currentWords.isEmpty
                ? const Center(child: Text("등록된 단어가 없습니다."))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _currentWords.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final word = _currentWords[index];
                      int globalIndex =
                          ((_currentPage - 1) * _itemsPerPage) + index + 1;

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$globalIndex",
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word.spelling,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    word.meaning,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 1
                      ? () => _changePage(_currentPage - 1)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.chevron_left),
                ),

                // ★ 추가 기능: 하단 페이지 번호를 눌러도 이동 다이얼로그가 뜨게 하면 더 편리합니다.
                GestureDetector(
                  onTap: _showJumpToPageDialog,
                  child: Text(
                    "$_currentPage / $totalPages",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline, // 클릭 가능하다는 표시
                    ),
                  ),
                ),

                ElevatedButton(
                  onPressed: _currentPage < totalPages
                      ? () => _changePage(_currentPage + 1)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
