import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/income_switch_tile.dart';

/// 收入来源「其他」tab：金币大树/赛季殖民地开关。
///
/// 输入实时写入 store（data 字段持久化），结果汇总见页面底部 IncomeSummaryBar。
class OtherTab extends StatelessWidget {
  const OtherTab({super.key, this.bottomInset = 0.0});

  /// 悬浮汇总条占位高度：作为列表底部滚动留白，内容滚动时可从条下方穿过，
  /// 滚到底时最后一条恰好完整停在条上方
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final store = Stores.infoStore;
    return ListView(
      padding: EdgeInsets.only(bottom: bottomInset),
      children: [
        IncomeSwitchTile(
          label: '赛季殖民地',
          readValue: store.getCurrentUserSeasonColony,
          onChanged: store.setCurrentUserSeasonColony,
        ),
        IncomeSwitchTile(
          label: '金币大树',
          readValue: store.getCurrentUserGoldenTree,
          onChanged: store.setCurrentUserGoldenTree,
        ),
      ],
    );
  }
}
