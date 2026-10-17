import 'item_lines.dart';

/// 百科词条内容
class WikiEntry {
  const WikiEntry({
    this.title,
    this.unit,
    this.summary,
    this.details = const <String>[],
  });

  final String? title;
  final String? unit;
  final String? summary;
  final List<String> details;
}

const Map<ItemLine, WikiEntry> uLineWiki = {
  ItemLine.bombArrow: WikiEntry(
    // title: '炸弹箭',
    unit: 'Ignis / 红毛',
    summary: '增加红毛普攻伤害',
    // details: [''],
  ),
  ItemLine.bonusGold: WikiEntry(
    // title: '金币加成',
    unit: '金币鼓',
    summary: '增加金币鼓技能获得的金币',
    // details: [''],
  ),
};

extension ItemLineWiki on ItemLine {
  WikiEntry? get wikiEntry => uLineWiki[this];
}
