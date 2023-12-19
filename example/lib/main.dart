import 'package:read_novel_fluentui/read_novel_fluentui.dart';
import 'package:fluent_ui/fluent_ui.dart';

String content = r'''二愣子睁大着双眼，直直望着茅草和烂泥糊成的黑屋顶，身上盖着的旧棉被，已呈深黄色，看不出原来的本来面目，还若有若无的散发着淡淡的霉味。

    离床大约半丈远的地方，是一堵黄泥糊成的土墙，因为时间过久，墙壁上裂开了几丝不起眼的细长口子，从这些裂纹中，隐隐约约的传来韩母唠唠叨叨的埋怨声，偶尔还掺杂着韩父，抽旱烟杆的“啪嗒”“啪嗒”吸允声。

    二愣子姓韩名立，这么像模像样的名字,他父母可起不出来，这是他父亲用两个粗粮制成的窝头，求村里老张叔给起的名字。

    韩立被村里人叫作“二愣子”，可人并不是真愣真傻，反而是村中首屈一指的聪明孩子，但就像其他村中的孩子一样，除了家里人外，他就很少听到有人正式叫他名字“韩立”，倒是“二愣子”“二愣子”的称呼一直伴随至今。

    这也没啥，村里的其他孩子也是“狗娃”“二蛋”之类的被人一直称呼着，这些名字也不见得比“二愣子”好听了哪里去。

    韩立外表长得很不起眼，皮肤黑黑的，就是一个普通的农家小孩模样。但他的内心深处，却比同龄人早熟了许多，他从小就向往外面世界的富饶繁华，梦想有一天，他能走出这个巴掌大的村子，去看看老张叔经常所说的外面世界。

    韩立一家七口人，有两个兄长，一个姐姐，还有一个小妹，他在家里排行老四，今年刚十岁，家里的生活很清苦，一年也吃不上几顿带荤腥的饭菜，全家人一直在温饱线上徘徊着。

    第二天中午时分，当韩立顶着火辣辣的太阳，背着半人高的木柴堆，怀里还揣着满满一布袋浆果，从山里往家里赶的时侯，并不知道家中已来了一位，会改变他一生命运的客人。

    听说，在附近一个小城的酒楼，给人当大掌柜，是他父母口中的大能人。韩家近百年来，可能就出了三叔这么一位有点身份的亲戚。

    韩立只在很小的时侯，见过这位三叔几次。他大哥在城里给一位老铁匠当学徒的工作，就是这位三叔给介绍的，这位三叔还经常托人给他父母捎带一些吃的用的东西，很是照顾他是照顾他们一家，因此韩立对这位三叔的印像也很好，知道父母虽然嘴里不说，心里也是很感激的。

    每当父母一提起大哥，就神采飞扬，像换了一个人一样。韩立年龄虽小，也羡慕不已，心目最好的工作也早早就有了，就是给小城里的哪位手艺师傅看上，收做学徒，从此变成靠手艺吃饭的体面人。

    把木柴在屋后放好后，便到前屋腼腆的给三叔见了个礼，乖乖的叫了声：“三叔好”，就老老实实的站在一边，听父母同三叔聊天。

    韩立虽然年龄尚小，不能完全听懂三叔的话，但也听明白了大概的意思。

    五年一次的“七玄门”招收内门弟子测试，下个月就要开始了。这位有着几分精明劲自己尚无子女的三叔，自然想到了适龄的韩立。

    在三叔嘴里，“七玄门”自然是这方圆数百里内，了不起的、数一数二的大门派。

    当听到有可能每月有一两银子可拿，还有机会成为和三叔一样的体面人，韩父终于拿定了主意，答应了下来。

    韩立虽然不全明白三叔所说的话，但可以进城能挣大钱还是明白的。

    三叔在一个多月后，准时的来到村中，要带韩立走了，临走前韩父反复嘱咐韩立，做人要老实，遇事要忍让，别和其他人起争执，而韩母则要他多注意身体，要吃好睡好。

    他虽然从小就比其他孩子成熟的多，但毕竟还是个十岁的小孩，第一次出远门让他的心里有点伤感和彷徨。他年幼的心里暗暗下定了决心，等挣到了大钱就马上赶回来，和父母再也不分开。

    韩立从未想到，此次出去后钱财的多少对他已失去了意义，他竟然走上了一条与凡人不同的仙业大道，走出了自己的修仙之路。''';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const FluentApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextConfig textConfig;
  late ReadingController controller;

  @override
  void initState() {
    textConfig = TextConfig();
    controller = ReadingController(
      textConfig: textConfig,
      onLoadChapter: onLoadChapter,
      menuBuilder: (controller) => DefaultMenu(readingController: controller),
      chapterNames: ['第一章', '第二章', '第三章'],
    );
    super.initState();
  }

  Future<String> onLoadChapter(int index, String chapterName) async {
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: null,
      content: ReadingPage(
        controller: controller,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
