import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:read_novel_fluentui/read_novel_fluentui.dart';
import 'package:read_novel_fluentui/src/page_effect.dart';
import 'package:read_novel_fluentui/src/text_page.dart';
import 'package:read_novel_fluentui/src/text_picture.dart';

import 'const.dart';

class ScreenParams {
  Size? _size;
  double? _ratio;
  ViewPadding? _viewPadding;

  ScreenParams();

  Size get size => _size ?? ui.window.physicalSize;

  double get ratio => _ratio ?? ui.window.devicePixelRatio;

  ViewPadding get viewPadding {
    if (isDesktop) return ViewPadding.zero;
    return _viewPadding ?? ui.window.viewPadding;
  }

  update(
    Size size,
    double ratio,
    ViewPadding viewPadding,
  ) {
    _size = size;
    _ratio = ratio;
    _viewPadding = viewPadding;
  }
}

class ReadingController extends ChangeNotifier {
  /// params
  final TextConfig textConfig;

  /// 获取章节内容
  final Future<String> Function(int index, String chapterName) onLoadChapter;

  /// 保存配置文件的回调
  final Function(ReadingController controller, int currChapterIndex, int currPageNum)? onSave;

  ///显示/隐藏menu回调
  final Function(bool isShowMenu)? onToggleMenu;

  /// 构建menu
  Widget Function(ReadingController textController)? menuBuilder;

  /// 章节名称列表
  final List<String> chapterNames;

  /// 初始章节索引
  final int initChapterIndex;

  /// 初始页号，1开始
  final int initPageNum;

  final Duration duration;

  ReadingController({
    required this.textConfig,
    required this.onLoadChapter,
    this.onSave,
    this.onToggleMenu,
    this.menuBuilder,
    required this.chapterNames,
    this.initChapterIndex = 0,
    this.initPageNum = 1,
    this.disposed = false,
    this.isShowMenu = false,
    this.cutoffPrevious = 8,
    this.cutoffNext = 92,
  }) : duration = Duration(milliseconds: textConfig.animationDuration) {
    assert(initPageNum >= 1);
    menuBuilder ??= (controller) => DefaultMenu(readingController: this);
    currentChapterIndex = initChapterIndex;
    currentPageNum = initPageNum;
    textPageManage = TextPageManage(
      chapterNames: chapterNames,
      onLoadChapter: onLoadChapter,
      readingController: this,
    );
    textEffectManage = TextEffectManage(
      textController: this,
      textPageManage: textPageManage,
      chapterNames: chapterNames,
      getAnimationController: () {
        if (getController == null) {
          throw '请先调用setControllerMethod进行方法初始化';
        }
        return getController!();
      },
    );
    textPictureManage = TextPictureManage(
      textController: this,
      textPageManage: textPageManage,
      chapterNames: chapterNames,
    );
  }

  ///other
  AnimationController Function()? getController;
  final ScreenParams screenParams = ScreenParams();
  late TextPageManage textPageManage;
  late TextEffectManage textEffectManage;
  late TextPictureManage textPictureManage;
  final List<TextEffect> currentChapterEffects = [];
  final List<TextEffect> previousChapterEffects = [];
  final List<TextEffect> nextChapterEffects = [];
  late int currentChapterIndex;
  late int currentPageNum;

  ///跳转到下一页的阈值
  final int cutoffNext;

  ///跳转到上一页的阈值
  final int cutoffPrevious;
  bool disposed = false;
  bool? isForward;
  bool isShowMenu;

  TextPage? get currentTextPage => textPageManage.getTextPage(
        currentChapterIndex,
        currentPageNum,
        size,
        ratio,
        viewPadding,
        textConfig,
      );

  TextEffect? get currentTextEffect => textEffectManage.getTargetEffect(
        currentChapterIndex,
        currentPageNum,
        size,
        ratio,
        viewPadding,
        textConfig,
      );

  buildEffects({notify = false, times = 10}) {
    TextPage? currentTextPage = this.currentTextPage;
    if (currentTextPage == null) {
      if (times >= 0) {
        /// 内容可能还没加载完成，1秒后进行检查
        if (currentChapterEffects.isNotEmpty) {
          currentChapterEffects.clear();
          if (notify && !disposed) notifyListeners();
        }

        Future.delayed(const Duration(seconds: 1), () {
          buildEffects(notify: true, times: times - 1);
        });
      }
      return;
    }
    if (isForward != null) {
      /// 正在进行滑动动画
      int _timeout = 3;

    }

    final currEffects = textEffectManage.getCurrChapterEffects(
      currentTextPage,
      size,
      ratio,
      viewPadding,
      textConfig,
    );
    currentChapterEffects
      ..clear()
      ..addAll(currEffects);

    final nextEffects = textEffectManage.getNextChapterEffects(
      currentTextPage,
      size,
      ratio,
      viewPadding,
      textConfig,
    );

    nextChapterEffects
      ..clear()
      ..addAll(nextEffects);
    final prevEffects = textEffectManage.getPreviousChapterEffects(
      currentTextPage,
      size,
      ratio,
      viewPadding,
      textConfig,
    );

    previousChapterEffects
      ..clear()
      ..addAll(prevEffects);
    if (notify) {
      notifyListeners();
    }
    checkSave();
  }

  List get effects {
    List tmpCurrentChapterEffects = [...currentChapterEffects];
    if (tmpCurrentChapterEffects.isEmpty) {
      tmpCurrentChapterEffects.add(const Center(child: ProgressRing()));
    }
    final res = [
      ...previousChapterEffects,
      ...tmpCurrentChapterEffects,
      ...nextChapterEffects,
    ].reversed.toList();
    return res;
  }

  setControllerMethod(AnimationController Function() getController) {
    this.getController = getController;
  }

  updateScreenParams(
    Size size,
    double ratio,
    ViewPadding viewPadding,
  ) {
    screenParams.update(size, ratio, viewPadding);
    buildEffects();
  }

  int _lastSaveTime = 0;
  static const saveDelay = Duration(seconds: 5);

  checkSave() {
    if (onSave == null) return;
    if (DateTime.now().millisecondsSinceEpoch < _lastSaveTime) return;
    _lastSaveTime = DateTime.now().add(saveDelay).millisecondsSinceEpoch;
    if (disposed) return;
    TextPage? textPage = textPageManage.getTextPage(
      currentChapterIndex,
      currentPageNum,
      size,
      ratio,
      viewPadding,
      textConfig,
    );
    if (textPage != null) {
      TextEffect? textEffect =
          textEffectManage.getTextEffect(textPage, size, ratio, viewPadding, textConfig);
      if (textEffect != null) {
        onSave?.call(this, currentChapterIndex, currentPageNum);
      }
    }
  }

  ui.Image? _backImage;

  ui.Image? get backgroundImage => _backImage;

  Color get backgroundColor => textConfig.backgroundColor;

  bool get animationWithImage => _backImage != null && textConfig.animationWithImage == true;

  AnimationType get animation => textConfig.animation;

  bool get shouldClipStatus => textConfig.showStatus && !textConfig.animationStatus;

  Size get size => screenParams.size;

  double get ratio => screenParams.ratio;

  ViewPadding get viewPadding => screenParams.viewPadding;

  ui.Picture? getPicture(int chapterIndex, int pageNum, int totalNum, Size size) {
    return textPictureManage.getPicture(
      chapterIndex,
      pageNum,
      totalNum,
      size,
      ratio,
      viewPadding,
      textConfig,
    );
  }

  void previousPage() async {
    if (disposed) return;
    TextEffect? textEffect = currentTextEffect;
    if (textEffect != null) {
      TextEffect? previousTextEffect = textEffectManage.getPreviousTextEffect(
        textEffect,
        size,
        ratio,
        viewPadding,
        textConfig,
      );
      if (previousTextEffect != null) {
        currentChapterIndex = previousTextEffect.textPage.chapterIndex;
        currentPageNum = previousTextEffect.textPage.pageNum;
        checkSave();
        previousTextEffect.amount.forward().then((value) {
          if (disposed) return;
          if (currentPageNum == 1 || currentPageNum == previousTextEffect.textPage.totalPage) {
            /// 更新effects
            buildEffects();
            notifyListeners();
          }
        });
      }
    }
  }

  void nextPage() async {
    if (disposed) return;
    TextEffect? textEffect = currentTextEffect;
    if (textEffect != null) {
      TextEffect? nextTextEffect = textEffectManage.getNextTextEffect(
        textEffect,
        size,
        ratio,
        viewPadding,
        textConfig,
      );
      if (nextTextEffect != null) {
        currentChapterIndex = nextTextEffect.textPage.chapterIndex;
        currentPageNum = nextTextEffect.textPage.pageNum;
        checkSave();
        textEffect.amount.reverse().then((value) {
          if (disposed) return;
          if (currentPageNum == 1 || currentPageNum == nextTextEffect.textPage.totalPage) {
            /// 更新effects
            buildEffects();
            notifyListeners();
          }
        });
      } else {
        if (textEffect.textPage.chapterIndex == chapterNames.length - 1) {
          /// 最后一章, 没有新的内容了
          textEffect.amount.forward();
        } else {
          /// 下一章没加载出来, 但是仍能跳转到下一章
          currentChapterIndex = textEffect.textPage.chapterIndex + 1;
          currentPageNum = 1;
          textEffect.amount.reverse().then((value) {
            if (disposed) return;
            buildEffects(notify: true);
            checkSave();
          });
        }
      }
    } else {
      if (currentChapterIndex < chapterNames.length - 1) {
        /// 没到最后一章
        currentChapterIndex += 1;
        currentPageNum = 1;
        if (disposed) return;
        buildEffects(notify: true);
        checkSave();
      }
    }
  }

  void turnPage(DragUpdateDetails details, BoxConstraints dimens, {bool vertical = false}) async {
    /// 进行滑动
    if (disposed) return;
    TextEffect.autoVerticalDrag = vertical;
    final offset = vertical ? details.delta.dy : details.delta.dx;
    final _ratio = vertical ? (offset / dimens.maxHeight) : (offset / dimens.maxWidth);
    if (isForward == null) {
      if (offset > 0) {
        isForward = false;
      } else {
        isForward = true;
      }
    }
    if (currentTextEffect != null) {
      if (isForward!) {
        currentTextEffect!.amount.value += _ratio;
      } else {
        (textEffectManage.getPreviousTextEffect(
          currentTextEffect!,
          size,
          ratio,
          viewPadding,
          textConfig,
        ))?.amount.value += _ratio;
      }
    }
  }

  Future<void> onDragFinish() async {
    if (disposed) return;
    if (isForward != null) {
      if (isForward!) {
        if (currentTextEffect != null) {
          if (currentTextEffect!.amount.value <= (cutoffNext / 100 + 0.03)) {
            nextPage();
          } else {
            currentTextEffect!.amount.forward();
          }
        } else {
          nextPage();
        }
      } else {
        if (currentTextEffect != null) {
          TextEffect? previousTextEffect = textEffectManage.getPreviousTextEffect(
            currentTextEffect!,
            size,
            ratio,
            viewPadding,
            textConfig,
          );
          if (previousTextEffect != null) {
            if (previousTextEffect.amount.value >= (cutoffPrevious / 100 + 0.05)) {
              previousPage();
            } else {
              previousTextEffect.amount.reverse();
            }
          }
        } else {
          previousPage();
        }
      }
    }
    isForward = null;
  }

  gotoChapter(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= chapterNames.length) return;
    currentChapterIndex = chapterIndex;
    currentPageNum = 1;
    buildEffects(notify: true);
  }

  void toggleMenuDialog(BuildContext context) {
    isShowMenu = !isShowMenu;
    if (onToggleMenu != null) {
      onToggleMenu!(isShowMenu);
    }
    notifyListeners();
  }

  @override
  dispose() {
    disposed = true;
    textPictureManage.dispose();
    textEffectManage.dispose();
    textPageManage.dispose();
    super.dispose();
  }
}
