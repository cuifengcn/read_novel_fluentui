import 'dart:ui' as ui;
import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:read_novel_fluentui/src/controller.dart';
import 'package:read_novel_fluentui/src/text_page.dart';

import 'config.dart';
import 'const.dart';
import 'memory_cache.dart';

class TextPictureManage {
  late MemoryCache<String, ui.Picture> cache;
  Map<String, dynamic>? config;
  Size? size;
  double? ratio;
  ViewPadding? viewPadding;

  /// 参数
  final ReadingController textController;
  final TextPageManage textPageManage;
  final List<String> chapterNames;

  TextPictureManage({
    required this.textController,
    required this.textPageManage,
    required this.chapterNames,
  }) {
    cache = MemoryCache<String, ui.Picture>(
      cacheSize: 1024,
      onDelete: (key, value) {
        if (value != null) {
          value.dispose();
        }
      },
    );
  }

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
      return true;
    } else {
      return false;
    }
  }

  ui.Picture? getPicture(
    int chapterIndex,
    int pageNum,
    int totalNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    /// 获取某一页
    checkChanged(size, ratio, viewPadding, config);
    try {
      return cache.getValueOrSet('$chapterIndex-$pageNum', () {
        return buildTextPicture(chapterIndex, pageNum, totalNum, size, ratio, viewPadding, config);
      });
    } finally {
      /// 添加1秒的延迟
      Future.delayed(const Duration(seconds: 1), () {
        cache.getValueOrSet('$chapterIndex-${pageNum - 1}', () {
          return buildTextPicture(
              chapterIndex, pageNum - 1, totalNum, size, ratio, viewPadding, config);
        });
        cache.getValueOrSet('$chapterIndex-${pageNum + 1}', () {
          return buildTextPicture(
              chapterIndex, pageNum + 1, totalNum, size, ratio, viewPadding, config);
        });
      });
    }
  }

  ui.Picture? buildTextPicture(
    int chapterIndex,
    int pageNum,
    int totalNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    /// TODO: 可以缓存上下章
    if (pageNum < 1) return null;
    if (pageNum > totalNum) return null;
    TextPage? page = textPageManage.getTextPage(
      chapterIndex,
      pageNum,
      size,
      ratio,
      viewPadding,
      config,
    );
    if (page == null) return null;
    final pic = ui.PictureRecorder();
    final c = Canvas(pic);

    final pageRect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    c.drawRect(pageRect, Paint()..color = config.backgroundColor);
    if (textController.backgroundImage != null) {
      c.drawImage(textController.backgroundImage!, Offset.zero, Paint());
    }
    // if (textController.animationWithImage && textController.animation == AnimationType.curl) {
    //   c.drawImage(textController.backgroundImage!, Offset.zero, Paint());
    // }
    paintText(c, size, page, config);
    return pic.endRecording();
  }

  dispose() {
    cache.clear();
  }
}
