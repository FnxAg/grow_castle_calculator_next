import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/colony_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/other_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/wave_tab.dart';
import 'package:grow_castle_calculator_next/view/widget/income_summary_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 收入计算页：按收入来源分 tab（殖民地/推波/其他）。
///
/// 每个 tab 内为输入列表；底部固定汇总条展示每日殖民地/挂机/其他收入与
/// 总收入（与阵容页底部汇总条同模式，由 store 的 incomeNotifier 驱动实时更新）。
class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // TabBar 放在 AppBar 底部（Material 标准做法），
    // 由 UserPageScaffold 新增的 bottom 参数透传
    return DefaultTabController(
      length: 3,
      child: UserPageScaffold(
        title: '收入',
        bottom: const TabBar(
          tabs: [
            Tab(text: '殖民地'),
            Tab(text: '推波'),
            Tab(text: '其他'),
          ],
        ),
        // 汇总条固定在底部，tab 内容在剩余高度内各自滚动
        body: const Column(
          children: [
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('提示'),
              subtitle: Text('填写“跳波状态”后再填写此处，否则计算结果不准确'),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ColonyTab(),
                  WaveTab(),
                  OtherTab(),
                ],
              ),
            ),
            IncomeSummaryBar(),
          ],
        ),
      ),
    );
  }
}
