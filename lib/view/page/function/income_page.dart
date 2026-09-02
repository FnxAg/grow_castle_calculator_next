import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/colony_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/other_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/wave_tab.dart';
import 'package:grow_castle_calculator_next/view/widget/income_summary_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';
import 'package:measure_size/measure_size.dart';

/// 收入计算页：按收入来源分 tab（殖民地/推波/其他）。
class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final ValueNotifier<double> _summaryBarHeightNotifier = ValueNotifier(0.0);

  @override
  void dispose() {
    _summaryBarHeightNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: UserPageScaffold(
        title: '收入',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '提示',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('提示'),
                    content: const Text('填写“跳波状态”后再填写此处，否则计算结果不准确。\n\n此处计算结果为每日收入。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: '殖民地'),
            Tab(text: '推波'),
            Tab(text: '其他'),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: _summaryBarHeightNotifier,
                builder: (context, inset, _) => TabBarView(
                  children: [
                    ColonyTab(bottomInset: inset),
                    WaveTab(bottomInset: inset),
                    OtherTab(bottomInset: inset),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MeasureSize(
                onChange: (size) {
                  final next = size.height;
                  final current = _summaryBarHeightNotifier.value;
                  if ((current - next).abs() > 0.5) {
                    _summaryBarHeightNotifier.value = next;
                  }
                },
                child: IncomeSummaryBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
