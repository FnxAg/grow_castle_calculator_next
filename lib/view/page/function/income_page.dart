import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
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

/// 收入计算页
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage> {
  final ValueNotifier<double> _summaryBarHeightNotifier = ValueNotifier(0.0);

  @override
  void dispose() {
    _summaryBarHeightNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: .start,
            children: [Text(l10n.tabIncome), _AppBarInfo()],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: l10n.tooltipInfo,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(l10n.tooltipInfo),
                      content: Text(l10n.dialogIncomeNotice),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.actionClose),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
          bottom: isMobile
              ? TabBar(
                  tabs: [
                    Tab(text: l10n.tabIncomeColony),
                    Tab(text: l10n.tabIncomeWave),
                    Tab(text: l10n.tabIncomeOther),
                  ],
                )
              : null,
        ),
        body: KeyedSubtree(
          key: ValueKey(ref.watch(userReloadSignalProvider)),
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
