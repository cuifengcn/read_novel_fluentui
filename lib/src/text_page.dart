import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:read_novel_fluentui/src/chapter_content.dart';
import 'package:read_novel_fluentui/src/config.dart';

import '../read_novel_fluentui.dart';
import 'memory_cache.dart';

class TextPage {
  /// page页
  double percent; // 占文章的百分比
  int pageNum; // 当前页是本章的第几页
  int totalPage; // 本章总共多少页
  int chapterIndex; //当前章的索引
  String info; //章节的名称
  final double height; // 页的总高度，除去padding
  final double width; //页的总宽度，除去padding
  final List<TextLine> lines; // 多少行
  final int columns; //多少列

  TextPage({
    this.percent = 0.0,
    this.totalPage = 1,
    this.chapterIndex = 0,
    this.info = '',
    required this.width,
    required this.pageNum, //从1开始
    required this.height,
    required this.lines,
    required this.columns,
  });

  @override
  bool operator ==(Object other) {
    return other is TextPage &&
        percent == other.percent &&
        pageNum == other.pageNum &&
        totalPage == other.totalPage &&
        chapterIndex == other.chapterIndex &&
        info == other.info &&
        height == other.height &&
        width == other.width &&
        lines.length == other.lines.length &&
        columns == other.columns;
  }

  @override
  String toString() {
    return 'chapterIndex:$chapterIndex;pageNum:$pageNum;totalPage:$totalPage;'
        'percent:$percent;info:$info;columns:$columns';
  }
}

class TextLine {
  final String text; //内容
  double dx; // 起始点x坐标
  double _dy;

  double get dy => _dy; // 起始点y坐标
  final double? letterSpacing; //字间距
  final bool isTitle; //是不是标题

  TextLine(
    this.text,
    this.dx,
    double dy, [
    this.letterSpacing = 0,
    this.isTitle = false,
  ]) : _dy = dy;

  justifyDy(double offsetDy) {
    /// 为了使列对齐,需要加一个偏移量
    _dy += offsetDy;
  }
}

class TextPageManage {
  late MemoryCache<String, TextPage> cache;
  late ChapterContentManage chapterContentManage;
  Map<String, dynamic>? config;
  Size? size;
  double? ratio;
  ViewPadding? viewPadding;
  String indentation = ' ';
  final Map<int, int> chapterTotalPageNumMapping = {};

  /// params
  final List<String> chapterNames;
  final Future<String> Function(int index, String chapterName) onLoadChapter;
  final ReadingController readingController;

  TextPageManage({
    required this.chapterNames,
    required this.onLoadChapter,
    required this.readingController,
  }) {
    cache = MemoryCache<String, TextPage>(cacheSize: 128);
    chapterContentManage = ChapterContentManage(
      chapterNames: chapterNames,
      onLoadChapter: onLoadChapter,
      readingController: readingController,
    );
  }

  Map<int, int> chapterPageNumbers = {};

  bool checkChanged(
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    bool changed = false;
    if (!mapEquals(config.toJSON(), this.config)) {
      changed = true;
      this.config = config.toJSON();
    }
    if (size.width != this.size?.width || size.height != this.size?.height) {
      changed = true;
      this.size = size;
    }
    if (ratio != this.ratio) {
      changed = true;
      this.ratio = ratio;
    }
    if (viewPadding.top != this.viewPadding?.top) {
      changed = true;
      this.viewPadding = viewPadding;
    }
    if (changed) {
      cache.clear();
      chapterTotalPageNumMapping.clear();
      return true;
    } else {
      return false;
    }
  }

  TextPage? getTextPage(
    int chapterIndex,
    int pageNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig textConfig, {
    preLoad = true,
  }) {
    checkChanged(size, ratio, viewPadding, textConfig);
    if (chapterIndex >= chapterNames.length) return null;
    String key = '$chapterIndex-$pageNum';
    if (!cache.containsKey(key)) {
      List<String>? paragraphs = chapterContentManage.getChapterParagraphs(chapterIndex);
      if (paragraphs == null) return null;
      List<TextPage> pages = buildTextPages(paragraphs, chapterIndex);
      for (var page in pages) {
        chapterPageNumbers[chapterIndex] = page.totalPage;

        /// 重新布局后，当前pageNum可能过大
        if (pageNum > page.totalPage) {
          pageNum = page.totalPage;
          key = '$chapterIndex-$pageNum';
        }
        String newKey = '$chapterIndex-${page.pageNum}';
        cache.setValue(newKey, page);
      }
    }
    if (cache.containsKey(key)) {
      if (preLoad) {
        TextPage value = cache.getValue(key)!;
        if (value.pageNum == value.totalPage) {
          ///预加载下一章的第一个textpage
          getNextTextPage(value, size, ratio, viewPadding, textConfig);
        }
        if (value.pageNum == 1) {
          ///预加载上一章的第一个textpage
          getPreviousTextPage(value, size, ratio, viewPadding, textConfig);
        }
      }
      return cache.getValue(key);
    } else {
      return null;
    }
  }

  TextPage? getNextTextPage(
    TextPage textPage,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    checkChanged(size, ratio, viewPadding, config);
    if (textPage.pageNum < textPage.totalPage) {
      return getTextPage(
        textPage.chapterIndex,
        textPage.pageNum + 1,
        size,
        ratio,
        viewPadding,
        config,
        preLoad: false,
      );
    } else {
      /// 需要去下一章
      if (textPage.chapterIndex >= chapterNames.length - 1) return null;
      int newChapterIndex = textPage.chapterIndex + 1;
      if (cache.containsKey('$newChapterIndex-1')) {
        return cache.getValue('$newChapterIndex-1');
      }
      List<String>? paragraphs = chapterContentManage.getChapterParagraphs(newChapterIndex);
      if (paragraphs == null) return null;
      List<TextPage> pages = buildTextPages(paragraphs, newChapterIndex);
      for (var page in pages) {
        chapterPageNumbers[newChapterIndex] = page.totalPage;
        String key = '$newChapterIndex-${page.pageNum}';
        cache.setValue(key, page);
      }
      String key = '$newChapterIndex-1';
      if (cache.containsKey(key)) {
        return cache.getValue(key);
      } else {
        return null;
      }
    }
  }

  TextPage? getPreviousTextPage(
    TextPage textPage,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    checkChanged(size, ratio, viewPadding, config);
    if (textPage.pageNum > 1) {
      return getTextPage(
        textPage.chapterIndex,
        textPage.pageNum - 1,
        size,
        ratio,
        viewPadding,
        config,
        preLoad: false,
      );
    } else {
      if (textPage.chapterIndex <= 0) return null;
      int newChapterIndex = textPage.chapterIndex - 1;
      if (chapterTotalPageNumMapping.containsKey(newChapterIndex) &&
          cache.containsKey('$newChapterIndex-${chapterTotalPageNumMapping[newChapterIndex]}')) {
        return cache.getValue('$newChapterIndex-${chapterTotalPageNumMapping[newChapterIndex]}');
      }
      List<String>? paragraphs = chapterContentManage.getChapterParagraphs(newChapterIndex);
      if (paragraphs == null) return null;
      List<TextPage> pages = buildTextPages(paragraphs, newChapterIndex);
      if (pages.isEmpty) return null;
      for (var page in pages) {
        chapterPageNumbers[newChapterIndex] = page.totalPage;
        String key = '$newChapterIndex-${page.pageNum}';
        cache.setValue(key, page);
      }
      String key = '$newChapterIndex-${pages.first.totalPage}';
      if (cache.containsKey(key)) {
        return cache.getValue(key);
      } else {
        return null;
      }
    }
  }

  List<TextPage> buildTextPages(List<String> paragraphs, int chapterIndex) {
    TextConfig config = TextConfig.fromJSON(this.config!);
    Size size = this.size!;
    ViewPadding viewPadding = this.viewPadding!;
    double ratio = this.ratio!;

    final List<TextPage> pages = [];

    /// 列数
    final columns = config.columns > 0
        ? config.columns
        : size.width > 580
            ? 2
            : 1;

    ///宽度
    final columnWidth = (size.width -
            config.leftPadding -
            config.rightPadding -
            (columns - 1) * config.columnPadding) /
        columns;

    /// 当宽度达到此宽度时，说明该换行了
    final nearlyColumnWidth = columnWidth - config.fontSize;

    ///高度
    final columnHeight = size.height - (config.showInfo ? 24 : 0) - config.bottomPadding;

    /// 当高度达到此高度时，说明该换页了
    final nearlyColumnHeight = columnHeight - config.fontSize * config.fontHeight;

    ///使用此画笔来计算宽高
    TextPainter tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final offset = Offset(columnWidth, 1);
    final startPointDx = config.leftPadding;
    final startPointDy = config.topPadding + (config.showStatus ? viewPadding.top / ratio : 0);

    final List<TextLine> lines = [];

    var columnNum = 1;

    ///经过paint，dx会不断向右
    var dx = startPointDx;

    ///经过paint，dy会不断向下
    var dy = startPointDy;
    var startLine = 0;

    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: config.fontSize + 2,
      fontFamily: config.fontFamily,
      color: config.fontColor,
      height: config.fontHeight,
    );
    final style = TextStyle(
      fontSize: config.fontSize,
      fontFamily: config.fontFamily,
      color: config.fontColor,
      height: config.fontHeight,
    );

    String chapterName =
        chapterNames[chapterIndex].isEmpty ? "第$chapterIndex章" : chapterNames[chapterIndex];
    bool drawTitle = true;
    while (drawTitle) {
      tp.text = TextSpan(text: chapterName, style: titleStyle);
      tp.layout(maxWidth: columnWidth);
      final textCount = tp.getPositionForOffset(offset).offset;
      final text = chapterName.substring(0, textCount);
      double? spacing;
      if (tp.width > nearlyColumnWidth) {
        /// 需要起新行
        tp.text = TextSpan(text: text, style: titleStyle);
        tp.layout();

        /// 当前行字之间的空隙
        double spacing = (columnWidth - tp.width) / textCount;
        if (spacing < -0.1 || spacing > 0.1) {
          spacing = spacing;
        }
      }
      lines.add(TextLine(text, dx, dy, spacing, true));
      dy += tp.height;
      if (chapterName.length == textCount) {
        drawTitle = false;
        break;
      } else {
        chapterName = chapterName.substring(textCount);
      }
    }
    dy += config.titlePadding;

    int pageIndex = 1;

    /// 下一页 判断分页 依据: `_boxHeight` `_boxHeight2`是否可以容纳下一行
    void toNewPage([bool shouldJustifyHeight = true, bool lastPage = false]) {
      if (shouldJustifyHeight && config.justifyHeight) {
        final len = lines.length - startLine;
        double justify = (columnHeight - dy) / (len - 1);
        for (var i = 0; i < len; i++) {
          lines[i + startLine].justifyDy(justify * i);
        }
      }
      if (columnNum == columns || lastPage) {
        pages.add(TextPage(
            lines: [...lines],
            height: dy,
            pageNum: pageIndex++,
            info: chapterName,
            chapterIndex: chapterIndex,
            width: columnWidth,
            columns: columns));
        lines.clear();
        columnNum = 1;
        dx = startPointDx;
      } else {
        /// 分栏
        columnNum++;
        dx += columnWidth + config.columnPadding;
      }
      dy = startPointDy;
      startLine = lines.length;
    }

    /// 现在是第一页
    for (var p in paragraphs) {
      p = indentation * config.indentation + p;
      while (true) {
        tp.text = TextSpan(text: p, style: style);
        tp.layout(maxWidth: columnWidth);
        final textCount = tp.getPositionForOffset(offset).offset;
        double? spacing;
        final text = p.substring(0, textCount);
        if (tp.width > nearlyColumnWidth) {
          // 换行
          tp.text = TextSpan(text: text, style: style);
          tp.layout();

          ///字间隙
          spacing = (columnWidth - tp.width) / textCount;
        }
        lines.add(TextLine(text, dx, dy, spacing));
        dy += tp.height;
        if (p.length == textCount) {
          if (dy > nearlyColumnHeight) {
            toNewPage();
          } else {
            dy += config.paragraphPadding;
          }
          break;
        } else {
          p = p.substring(textCount);
          if (dy > nearlyColumnHeight) {
            toNewPage();
          }
        }
      }
    }

    if (lines.isNotEmpty) {
      /// 添加空白页
      toNewPage(false, true);
    }
    if (pages.isEmpty) {
      pages.add(TextPage(
        lines: [],
        height: config.topPadding + config.bottomPadding,
        pageNum: 1,
        info: chapterName,
        chapterIndex: chapterIndex,
        width: columnWidth,
        columns: columns,
      ));
    }
    double chapterPercent = chapterIndex / chapterNames.length;
    int totalPage = pages.length;
    for (var page in pages) {
      page.totalPage = totalPage;
      page.percent = page.pageNum / totalPage / chapterNames.length + chapterPercent;
    }
    tp.dispose();
    //把每一章有多少页保存一下
    chapterTotalPageNumMapping[chapterIndex] = pages.length;
    return pages;
  }

  dispose() {
    cache.clear();
  }
}
