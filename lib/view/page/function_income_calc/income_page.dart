import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_edit_tile.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_field.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/summary_bar.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:material_ui/material_ui.dart';

/// 收入计算页
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage> {
  Widget _buildList({required bool wide, required AppLocalizations l10n}) {
    final wave = ref.watch(currentUserWaveProvider);
    final infiniteColony = ref.watch(
      currentUserProvider.select((u) => u.infiniteColony),
    );
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    final income = ref.watch(dailyIncomeProvider);
    Widget sectionHeaderTrailing(IconData icon, String text) =>
        PillChip(leading: Icon(icon), text: text);
    final list = ListView(
      children: [
        const IncomeEditTile(field: IncomeField.gabTime),
        const IncomeEditTile(field: IncomeField.tabTime),
        SectionHeader(
          l10n.tabIncomeWave,
          trailing: sectionHeaderTrailing(
            Icons.bolt,
            income.autoBattle.formatCompact(
              english: english,
              traditional: traditional,
            ),
          ),
        ),
        const IncomeEditTile(field: IncomeField.gabBonus),
        SectionHeader(
          l10n.tabIncomeColony,
          trailing: sectionHeaderTrailing(
            Icons.terrain,
            income.colony.formatCompact(
              english: english,
              traditional: traditional,
            ),
          ),
        ),
        IncomeEditTile(
          field: IncomeField.infiniteColony,
          titleTrailing: Tooltip(
            message: l10n.tooltipInfiniteColonyRatio,
            child: PillChip(
              text: wave > 0 ? (infiniteColony / wave * 1000).format() : '0',
            ),
          ),
        ),
        const IncomeEditTile(field: IncomeField.icCooldown),
        const IncomeEditTile(field: IncomeField.icGold),
        SwitchListTile(
          title: Text(l10n.labelWheel),
          value: ref.watch(currentUserProvider.select((u) => u.equipWheel)),
          onChanged: ref.users.setCurrentUserEquipWheel,
        ),
        SwitchListTile(
          title: Text(l10n.labelWhip),
          value: ref.watch(currentUserProvider.select((u) => u.equipWhip)),
          onChanged: ref.users.setCurrentUserEquipWhip,
        ),
        SectionHeader(
          l10n.tabIncomeOther,
          trailing: sectionHeaderTrailing(
            Icons.park,
            income.other.formatCompact(
              english: english,
              traditional: traditional,
            ),
          ),
        ),
        SwitchListTile(
          title: Text(l10n.labelSeasonColony),
          value: ref.watch(currentUserProvider.select((u) => u.seasonColony)),
          onChanged: ref.users.setCurrentUserSeasonColony,
        ),
        SwitchListTile(
          title: Text(l10n.labelGoldenTree),
          value: ref.watch(currentUserProvider.select((u) => u.goldenTree)),
          onChanged: ref.users.setCurrentUserGoldenTree,
        ),
      ],
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = context.isWideContent;
    final list = _buildList(wide: wide, l10n: l10n);
    final body = wide
        ? Row(
            children: [
              Expanded(flex: 6, child: list),
              const Expanded(flex: 4, child: IncomeSummaryBar()),
            ],
          )
        : list;
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
          child: body,
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
      AppBarItem.currentUserDailyIncome(),
    ];
    return AppBarInfo(children: segments);
  }
}
