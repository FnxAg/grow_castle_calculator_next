import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/colony_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/other_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/wave_tab.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 收入计算页：按收入来源分 tab（殖民地/推波/其他）。
///
/// 每个 tab 的结构类似阵容页：body 内输入框 + 实时计算详单；
/// 具体输入项与计算规则待补充。
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
        body: const TabBarView(
          children: [
            ColonyTab(),
            WaveTab(),
            OtherTab(),
          ],
        ),
      ),
    );
  }
}
