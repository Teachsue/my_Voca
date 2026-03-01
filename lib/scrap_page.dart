import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'seasonal_background.dart';
import 'theme_manager.dart';

class ScrapPage extends StatefulWidget {
  const ScrapPage({super.key});

  @override
  State<ScrapPage> createState() => _ScrapPageState();
}

class _ScrapPageState extends State<ScrapPage> {
  @override
  Widget build(BuildContext context) {
    final wordBox = Hive.box<Word>('words');
    final scrapWords = wordBox.values.where((word) => word.isScrap).toList();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = ThemeManager.textColor;
    final subTextColor = ThemeManager.subTextColor;
    final isDark = ThemeManager.isDarkMode;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("중요 단어 ⭐", style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: scrapWords.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.star_border_rounded, size: 60, color: Colors.amber[300]),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "아직 스크랩한 단어가 없어요.\n중요한 단어를 별표로 저장해보세요!", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 16, color: subTextColor, fontWeight: FontWeight.bold, height: 1.5)
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: scrapWords.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final word = scrapWords[index];
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(word.spelling, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: textColor)),
                              const SizedBox(height: 4),
                              Text(word.meaning, style: TextStyle(fontSize: 15, color: subTextColor, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? primaryColor.withOpacity(0.1) : primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${word.category} • ${word.level}", 
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900, 
                                    color: isDark ? primaryColor.withOpacity(0.6) : primaryColor.withOpacity(0.8)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                          onPressed: () {
                            setState(() {
                              word.isScrap = false;
                              word.save();
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
