import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:material_ui/material_ui.dart';

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

  void _showIncomeDialog(int index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddIncomeDialog(
        initialIncome: _incomes[index],
        onAdd: (gold) => _editIncome(index, gold),
      ),
    );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.snackAppliedGabBonus(filled.format(fractionDigits: 2)),
                  ),
                ),
              );
            },
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
  }

  void _addIncomeDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddIncomeDialog(onAdd: _addIncome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = context.isCompactUnitEnglish;
    final traditional = context.isTraditionalChineseLocale;
    final wave = ref.watch(currentUserWaveProvider);
    final gabCost = _gabCost(wave);
    final safeCost = gabCost > 0 ? gabCost : 0.0;
    final avgIncome = _incomes.isEmpty
        ? 0.0
        : _incomes.reduce((a, b) => a + b) / _incomes.length;
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

    final Widget floatingActionButton = FloatingActionButton(
      onPressed: _addIncomeDialog,
      tooltip: l10n.actionAdd,
      child: const Icon(Icons.add),
    );

    final Widget list = ListView.builder(
      padding: EdgeInsets.only(
        bottom: 72 + MediaQuery.of(context).padding.bottom,
      ),
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

    final Widget appBarInfo = AppBarInfo(
      children: [
        AppBarItem.currentUser(),
        AppBarItem.text(
          gabCost.formatCompact(english: english, traditional: traditional),
          tooltip: l10n.labelGabCost,
        ),
        AppBarItem.text(
          avgIncome.formatCompact(english: english, traditional: traditional),
          tooltip: l10n.labelAverageIncome,
        ),
        AppBarItem.text(
          '${percent.format(fractionDigits: 2)}%',
          tooltip: l10n.labelPercent,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.wavePushIncomeCalc), appBarInfo],
        ),
        actions: [popupMenuButton],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: UIs.padding,
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
      ),
      floatingActionButton: floatingActionButton,
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

/// 每波金币收入输入对话框
class _AddIncomeDialog extends StatefulWidget {
  const _AddIncomeDialog({this.initialIncome, required this.onAdd});

  final int? initialIncome;
  final ValueChanged<int> onAdd;

  @override
  State<_AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<_AddIncomeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialIncome?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final gold = int.tryParse(_controller.text);
    if (gold != null) {
      widget.onAdd(gold);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.initialIncome == null
            ? l10n.dialogInputWaveIncome
            : l10n.actionEdit,
      ),
      content: SelectAllTextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          helperText: int.tryParse(_controller.text.trim())?.format() ?? '-',
          suffix: TextButton(
            onPressed: () =>
                setState(() => _controller.text = '${_controller.text}000'),
            child: Text('+000'),
          ),
        ),
        onChanged: (_) => setState(() {}),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : widget.initialIncome.toString() == _controller.text
              ? null
              : _submit,
          child: Text(
            widget.initialIncome == null ? l10n.actionAdd : l10n.actionSave,
          ),
        ),
      ],
    );
  }
}
