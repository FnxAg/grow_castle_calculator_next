import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/notice/top_notice.dart';
import 'package:material_ui/material_ui.dart';
import 'package:measure_size/measure_size.dart';

/// 单条收入相对金挂成本的收益率，成本非正时记 0
double _sampleRate(num income, double safeCost) =>
    safeCost > 0 ? (income - safeCost) / safeCost * 100 : 0.0;

enum Action { overwrite, reset, edit, remove }

/// 收入百分比计算页
class BonusGoldCalcPage extends ConsumerStatefulWidget {
  const BonusGoldCalcPage({super.key});

  @override
  ConsumerState<BonusGoldCalcPage> createState() => _BonusGoldCalcPageState();
}

class _BonusGoldCalcPageState extends ConsumerState<BonusGoldCalcPage>
    with SingleTickerProviderStateMixin {
  static final Map<int, List<int>> _incomesByUser = {};

  late List<int> _incomes;
  double paddingTop = 0.0;

  @override
  void initState() {
    super.initState();
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      reloadForCurrentUser();
    });
    _loadIncomes();
  }

  void reloadForCurrentUser() {
    setState(_loadIncomes);
  }

  void _loadIncomes() {
    _incomes = _incomesByUser.putIfAbsent(
      ref.read(currentUserIdProvider),
      () => [],
    );
  }

  double _gabCost(int wave) => 456.0 * wave - 29264;

  void _addIncome(int gold) {
    setState(() => _incomes.add(gold));
  }

  void _removeIncome(int index) {
    setState(() => _incomes.removeAt(index));
  }

  void _editIncome(int index, int gold) {
    setState(() => _incomes[index] = gold);
  }

  void _showIncomeDialog([int? index]) {
    final l10n = AppLocalizations.of(context);
    final initialIncome = index == null ? null : _incomes[index];
    final controller = TextEditingController(
      text: initialIncome?.toString() ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          void submit() {
            final gold = int.tryParse(controller.text);
            if (gold != null) {
              if (index == null) {
                _addIncome(gold);
              } else {
                _editIncome(index, gold);
              }
            }
            Navigator.of(dialogContext).pop();
          }

          return AlertDialog(
            title: Text(
              initialIncome == null
                  ? l10n.dialogInputWaveIncome
                  : l10n.actionEdit,
            ),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: CardField(
                    title: l10n.labelIncome,
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    helperText:
                        int.tryParse(controller.text.trim())?.format() ?? '-',
                    suffixIcon: TextButton(
                      onPressed: () => setDialogState(
                        () => controller.text = '${controller.text}000',
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 18),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('+000'),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                    autofocus: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : initialIncome != null &&
                          initialIncome.toString() == controller.text
                    ? null
                    : submit,
                child: Text(
                  initialIncome == null ? l10n.actionAdd : l10n.actionSave,
                ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  void _overwrite(double percent) {
    final l10n = AppLocalizations.of(context);
    final filled = (percent * 100).roundToDouble() / 100;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actionOverwriteCurrentUserData),
        content: Text(
          l10n.dialogApplyGabBonusContent(
            ref.read(currentUserGabBonusProvider).format(fractionDigits: 2),
            filled.format(fractionDigits: 2),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.users.setCurrentUserGabBonus(filled);
              showTopNotice(
                context,
                message: l10n.snackAppliedGabBonus(
                  filled.format(fractionDigits: 2),
                ),
              );
            },
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = context.isCompactUnitEnglish;
    final traditional = context.isTraditionalChineseLocale;
    final username = ref.watch(currentUsernameProvider);
    final wave = ref.watch(currentUserWaveProvider);
    final gabCost = _gabCost(wave);
    final safeCost = gabCost > 0 ? gabCost : 0.0;
    final avgIncome = _incomes.isEmpty
        ? 0.0
        : _incomes.fold<double>(0, (sum, income) => sum + income) /
              _incomes.length;
    final percent = _incomes.isEmpty ? 0.0 : _sampleRate(avgIncome, safeCost);

    final Widget popupMenuButton = PopupMenuButton<Action>(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: Action.overwrite,
          child: Text(l10n.actionOverwriteCurrentUserData),
        ),
        PopupMenuItem(value: Action.reset, child: Text(l10n.actionReset)),
      ],
      onSelected: (action) {
        switch (action) {
          case Action.overwrite:
            _overwrite(percent);
          case Action.reset:
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.actionReset),
                content: Text(l10n.dialogReset),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.actionCancel),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      setState(() => _incomes.clear());
                    },
                    child: Text(l10n.actionConfirm),
                  ),
                ],
              ),
            );
          case Action.edit:
          case Action.remove:
            break;
        }
      },
    );

    final Widget list = ListView.builder(
      padding: UIs.padding.add(EdgeInsets.only(top: paddingTop)),
      itemCount: _incomes.length,
      itemBuilder: (context, index) {
        final income = _incomes[index];
        return _IncomeTile(
          index: index,
          income: income,
          rate: _sampleRate(income, safeCost),
          onAction: (action) {
            switch (action) {
              case Action.edit:
                _showIncomeDialog(index);
              case Action.remove:
                _removeIncome(index);
              case Action.overwrite:
              case Action.reset:
                break;
            }
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.wavePushIncomeCalc)],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.actionAdd,
            onPressed: () => _showIncomeDialog(),
          ),
          popupMenuButton,
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  if (_incomes.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.emptyIncomeSamples,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return list;
                },
              ),
            ),
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: MeasureSize(
                onChange: (size) {
                  setState(() => paddingTop = size.height);
                },
                child: Padding(
                  padding: UIs.padding,
                  child: CardTile(
                    cardType: CardType.glass,
                    title: Text(username, overflow: TextOverflow.ellipsis),
                    trailing: Wrap(
                      spacing: 2.0,
                      children: [
                        Tooltip(
                          message: l10n.labelGabCost,
                          child: PillChip(
                            text: gabCost.formatCompact(
                              english: english,
                              traditional: traditional,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: l10n.labelAverageIncome,
                          child: PillChip(
                            text: avgIncome.formatCompact(
                              english: english,
                              traditional: traditional,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: l10n.labelPercent,
                          child: PillChip(
                            text: '${percent.format(fractionDigits: 2)}%',
                          ),
                        ),
                      ],
                    ),
                    onTap: () => showTopNotice(
                      context,
                      duration: const Duration(seconds: 7),
                      content: Column(
                        children: [
                          SummaryRow(
                            title: Text(l10n.labelGabCost),
                            trailing: SummaryRow.text(
                              gabCost.formatCompact(
                                english: english,
                                traditional: traditional,
                              ),
                            ),
                          ),
                          SummaryRow(
                            title: Text(l10n.labelAverageIncome),
                            trailing: SummaryRow.text(
                              avgIncome.formatCompact(
                                english: english,
                                traditional: traditional,
                              ),
                            ),
                          ),
                          SummaryRow(
                            title: Text(l10n.labelPercent),
                            trailing: SummaryRow.text(
                              '${percent.format(fractionDigits: 2)}%',
                            ),
                          ),
                        ],
                      ),
                      noticeType: NoticeType.content,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单条收入样本行
class _IncomeTile extends StatelessWidget {
  const _IncomeTile({
    required this.index,
    required this.income,
    required this.rate,
    required this.onAction,
  });

  final int index;
  final int income;
  final double rate;
  final ValueChanged<Action> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CardTile(
      leading: CircleAvatar(
        radius: 12.0,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.0,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        income.format(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16.0,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillChip(text: '${rate.format(fractionDigits: 2)}%'),
          PopupMenuButton<Action>(
            tooltip: l10n.actionEdit,
            itemBuilder: (context) => [
              PopupMenuItem(value: Action.edit, child: Text(l10n.actionEdit)),
              PopupMenuItem(
                value: Action.remove,
                child: Text(l10n.actionRemove),
              ),
            ],
            onSelected: (action) {
              if (action == Action.remove) {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.actionRemove),
                    content: Text(l10n.dialogRemove),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.actionCancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onAction(Action.remove);
                        },
                        child: Text(l10n.actionConfirm),
                      ),
                    ],
                  ),
                );
              } else {
                onAction(action);
              }
            },
          ),
        ],
      ),
    );
  }
}
