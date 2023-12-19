import 'dart:async';

import 'package:read_novel_fluentui/src/memory_cache.dart';

import '../read_novel_fluentui.dart';
import 'const.dart';

class ChapterContentManage {
  late MemoryCache<int, List<String>> cache;
  final List<String> chapterNames;
  final Future<String> Function(int index, String chapterName) onLoadChapter;
  final ReadingController readingController;

  ChapterContentManage({
    required this.chapterNames,
    required this.onLoadChapter,
    required this.readingController,
  }) {
    cache = MemoryCache<int, List<String>>();
  }

  List<String>? getChapterParagraphs(int index, [autoPreLoad = true]) {
    if (chapterNames.isEmpty) return [];
    if (index < 0 || index >= chapterNames.length) return [];
    try {
      if (cache.containsKey(index)) {
        return cache.getValue(index)!;
      } else {
        onLoadChapter(index, chapterNames[index]).then((content) {
          if (content == '') {
            content = '本章内容为空';
          }
          cache.setValue(index, parseParagraphs(content));
          readingController.buildEffects();
        });
        return null;
      }
    } finally {
      if (autoPreLoad) {
        ///自动加载本章的前后两章
        getChapterParagraphs(index + 1, false);
        getChapterParagraphs(index - 1, false);
      }
    }
  }
}
