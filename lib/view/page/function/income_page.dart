import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/colony_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/other_tab.dart';
import 'package:grow_castle_calculator_next/view/page/function/income/wave_tab.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user_total_gold.dart';
import 'package:grow_castle_calculator_next/view/widget/income_summary_bar.dart';
import 'package:material_ui/material_ui.dart';

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
    final bool isWide = context.isWideScreen;
    final Widget expandedIncomeView = Expanded(
      flex: isWide ? 6 : 1,
      child: isMobile
          ? const TabBarView(children: [ColonyTab(), WaveTab(), OtherTab()])
          : ListView(
              children: const [
                ColonyTab(),
                Divider(height: 1),
                WaveTab(),
                Divider(height: 1),
                OtherTab(),
              ],
            ),
    );
    return ListenableBuilder(
      listenable: Listenable.merge([
        Stores.infoStore.currentUserNotifier,
        Stores.infoStore.dataVersionNotifier,
      ]),
      builder: (context, _) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: .start,
                children: [Text('收入'), _AppBarInfo()],
              ),
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
                          content: const Text(
                            '填写“跳波状态”后再填写此处，否则计算结果不准确。\n\n此处计算结果为每日收入。',
                          ),
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
              bottom: isMobile
                  ? const TabBar(
                      tabs: [
                        Tab(text: '殖民地'),
                        Tab(text: '推波'),
                        Tab(text: '其他'),
                      ],
                    )
                  : null,
            ),
            // 三个 tab 的输入框都按字段名缓存了 TextEditingController，控制器
            // 在子组件 State 里，页面自身 State 保不住——换 key 整体重建。
            // key 带上用户名与 dataVersion：切用户、云恢复/导入都要重新建，
            // 否则旧数据会被写回新用户
            body: KeyedSubtree(
              key: ValueKey((
                Stores.infoStore.getCurrentUsername(),
                Stores.infoStore.dataVersionNotifier.value,
              )),
              child: !isWide
                  ? Column(children: [expandedIncomeView, IncomeSummaryBar()])
                  : Row(
                      children: [
                        expandedIncomeView,
                        Expanded(flex: 4, child: IncomeSummaryBar()),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = [CurrentUser(), CurrentUserTotalGold()];
    return AppBarInfo(children: segments);
  }
}
