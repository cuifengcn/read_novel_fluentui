import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:read_novel_fluentui/read_novel_fluentui.dart';

class DefaultMenu extends StatefulWidget {
  final ReadingController readingController;

  const DefaultMenu({super.key, required this.readingController});

  @override
  State<DefaultMenu> createState() => _DefaultMenuState();
}

class _DefaultMenuState extends State<DefaultMenu> {
  final Widget space = const SizedBox(width: 10);
  late double selectedChapterIndex = widget.readingController.currentChapterIndex + 1.0;

  Widget buildTop() {
    return Card(
        child: Row(
      children: [
        IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        space,
        Expanded(
          child: widget.readingController.chapterNames.isNotEmpty
              ? Text(
                  widget
                      .readingController.chapterNames[widget.readingController.currentChapterIndex],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
            icon: const Icon(FluentIcons.refresh),
            onPressed: () {
              widget.readingController.buildEffects(notify: true);
            }),
      ],
    ));
  }

  Widget buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FilledButton(
            child: const Text("上一章"),
            onPressed: () {
              widget.readingController
                  .gotoChapter(widget.readingController.currentChapterIndex - 1);
            }),
        FilledButton(
            child: const Text("下一章"),
            onPressed: () {
              widget.readingController
                  .gotoChapter(widget.readingController.currentChapterIndex + 1);
            }),
      ],
    );
  }

  Widget buildBottom() {
    return Container(
      width: double.infinity,
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(color: FluentTheme.of(context).micaBackgroundColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                const Text('章节'),
                const SizedBox(width: 10),
                Expanded(
                    child: Slider(
                  value: selectedChapterIndex,
                  min: 1,
                  divisions: max(
                    1,
                    widget.readingController.chapterNames.length - 1,
                  ),
                  max: max(
                    widget.readingController.chapterNames.length.toDouble(),
                    selectedChapterIndex,
                  ),
                  label: '${selectedChapterIndex.toInt()}',
                  style: SliderThemeData(
                    labelBackgroundColor: FluentTheme.of(context).accentColor,
                  ),
                  onChangeEnd: (v) {
                    widget.readingController.gotoChapter(selectedChapterIndex.toInt() - 1);
                  },
                  onChanged: (v) {
                    selectedChapterIndex = v;
                    setState(() {});
                  },
                )),
                const SizedBox(width: 10),
                Text('共${widget.readingController.chapterNames.length}章'),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Button(
                    child: const Column(
                      children: [Icon(FluentIcons.back, size: 22), Text("退出")],
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Button(
                    child: const Column(
                      children: [Icon(FluentIcons.bulleted_list, size: 22), Text("目录")],
                    ),
                    onPressed: () {
                      showCatalogListDialog();
                    },
                  ),
                  Button(
                    child: const Column(
                      children: [Icon(FluentIcons.text_field, size: 22), Text("调节")],
                    ),
                    onPressed: () async {
                      bool? res = await showSettingTextDialog();
                    },
                  ),
                  widget.readingController.textConfig.darkMode
                      ? Button(
                          child: const Column(
                            children: [Icon(FluentIcons.sunny, size: 22), Text("日间")],
                          ),
                          onPressed: () {
                            widget.readingController.textConfig.darkMode = false;
                            setState(() {});
                          })
                      : Button(
                          child: const Column(
                            children: [Icon(FluentIcons.clear_night, size: 22), Text("夜间")],
                          ),
                          onPressed: () {
                            widget.readingController.textConfig.darkMode = true;
                            setState(() {});
                          },
                        ),
                  // _buildPopupMenu(context, bgColor, color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  showCatalogListDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            content: CatalogListContent(
              controller: widget.readingController,
              initIndex: widget.readingController.currentChapterIndex,
            ),
            actions: [
              Button(child: const Text('关闭'), onPressed: () => Navigator.of(context).pop())
            ],
          );
        });
  }

  showSettingTextDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          TextConfig config = widget.readingController.textConfig;
          return ContentDialog(
            content: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setState) {
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('单手模式'),
                      subtitle: const Text('全屏点击向下翻页'),
                      trailing: ToggleSwitch(
                        checked: config.oneHand,
                        onChanged: (bool value) {
                          config.oneHand = value;
                          setState(() {});
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('字号'),
                      subtitle: const Text('文字大小'),
                      trailing: DropDownButton(
                        title: Text('${config.fontSize.toInt()}'),
                        items: List.generate(
                            30,
                            (index) => MenuFlyoutItem(
                                text: Text('${index + 10}'),
                                onPressed: () {
                                  config.fontSize = index + 10;
                                  widget.readingController.buildEffects(notify: true);
                                  setState(() {});
                                })),
                      ),
                    ),
                    ListTile(
                      title: const Text('下划线'),
                      subtitle: const Text('显示文字下划线'),
                      trailing: ToggleSwitch(
                        checked: config.underLine,
                        onChanged: (bool value) {
                          config.underLine = value;
                          setState(() {});
                        },
                      ),
                    ),
                    const Text('前景色/背景色请在日间模式下进行调整'),
                    ListTile(
                      title: const Text('前景色'),
                      subtitle: const Text('文本颜色'),
                      trailing: SplitButton(
                        flyout: FlyoutContent(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Wrap(
                            runSpacing: 10,
                            spacing: 10,
                            children: compositionColors.map((color) {
                              return Button(
                                style:
                                    ButtonStyle(padding: ButtonState.all(const EdgeInsets.all(4))),
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  color: color,
                                ),
                                onPressed: () {
                                  config.fontColor = color;
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                              color: config.fontColor,
                              borderRadius: const BorderRadiusDirectional.horizontal(
                                start: Radius.circular(4),
                              )),
                          height: 32,
                          width: 36,
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('背景色'),
                      subtitle: const Text('背景颜色'),
                      trailing: SplitButton(
                        flyout: FlyoutContent(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Wrap(
                            runSpacing: 10,
                            spacing: 10,
                            children: compositionColors.map((color) {
                              return Button(
                                style:
                                    ButtonStyle(padding: ButtonState.all(const EdgeInsets.all(4))),
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  color: color,
                                ),
                                onPressed: () {
                                  config.backgroundColor = color;
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                              color: config.backgroundColor,
                              borderRadius: const BorderRadiusDirectional.horizontal(
                                start: Radius.circular(4),
                              )),
                          height: 32,
                          width: 36,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              Button(
                  child: const Text('关闭'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.readingController.buildEffects(notify: true);
                  })
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          buildTop(),
          const Spacer(),
          buildControlButtons(),
          const SizedBox(height: 10),
          buildBottom(),
        ],
      ),
    );
  }
}

class CatalogListContent extends StatefulWidget {
  final ReadingController controller;
  final int initIndex;

  const CatalogListContent({super.key, required this.controller, required this.initIndex});

  @override
  State<CatalogListContent> createState() => _CatalogListContentState();
}

class _CatalogListContentState extends State<CatalogListContent> {
  late int selectedIndex = widget.initIndex;
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController(initialScrollOffset: widget.initIndex * 50);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      child: ListView.builder(
        shrinkWrap: true,
        controller: scrollController,
        itemBuilder: (context, index) {
          return ListTile.selectable(
            selected: index == selectedIndex,
            onSelectionChange: (checked) {
              if (checked) {
                selectedIndex = index;
              }
            },
            title: Text(
              widget.controller.chapterNames[index],
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.controller.gotoChapter(index);
            },
          );
        },
        itemExtent: 50,
        itemCount: widget.controller.chapterNames.length,
      ),
    );
  }
}
