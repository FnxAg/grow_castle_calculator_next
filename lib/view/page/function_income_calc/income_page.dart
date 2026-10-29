import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/colony_section.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/other_section.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/summary_bar.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/wave_section.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:material_ui/material_ui.dart';

/// 收入计算页
class IncomePage extends ConsumerWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = ListView(
      children: [
        SectionHeader(l10n.tabIncomeColony),
        const ColonySection(),
        SectionHeader(l10n.tabIncomeWave),
        const WaveSection(),
        SectionHeader(l10n.tabIncomeOther),
        const OtherSection(),
      ],
    );
    return Scaffold(
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
      ),
      body: SafeArea(
        top: false,
        child: KeyedSubtree(
          key: ValueKey(ref.watch(userReloadSignalProvider)),
          child: context.isWideContent
              ? Row(
                  children: [
                    Expanded(flex: 6, child: content),
                    const Expanded(flex: 4, child: IncomeSummaryBar()),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: content),
                    const IncomeSummaryBar(),
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
    final List<Widget> segments = [
      AppBarItem.currentUser(),
      AppBarItem.currentUserTotalGold(),
    ];
    return AppBarInfo(children: segments);
  }
}
