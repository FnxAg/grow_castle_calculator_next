import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/current_user_reload.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// 单条收入相对金挂成本的收益率（%）：成本非正（当前波数过低）时记 0，
/// 避免负成本导致的除零/噪音百分比
double _sampleRate(num income, double safeCost) =>
    safeCost > 0 ? (income - safeCost) / safeCost * 100 : 0.0;

/// 收入百分比计算页：输入样本计算平均收益率。
class BonusGoldCalcPage extends StatefulWidget {
  const BonusGoldCalcPage({super.key});

  @override
  State<BonusGoldCalcPage> createState() => _BonusGoldCalcPageState();
}

class _BonusGoldCalcPageState extends State<BonusGoldCalcPage>
    with CurrentUserReload {
  /// 会话缓存
  static final Map<int, List<int>> _incomesByUser = {};

  /// 当前用户的样本列表
  late List<int> _incomes;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  /// 样本按 userId 分桶，切换用户时换回该用户自己的一份
  @override
  void reloadForCurrentUser() {
    setState(_loadIncomes);
  }

  void _loadIncomes() {
    _incomes = _incomesByUser.putIfAbsent(
      Stores.infoStore.getCurrentUserId(),
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

  void _applyPercent(double percent) {
    final filled = (percent * 100).roundToDouble() / 100;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认填入收益'),
        content: Text(
          '金挂收益：${Stores.infoStore.getCurrentUserGabBonus()}% -> ${filled.format(fractionDigits: 2)}%？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Stores.infoStore.setCurrentUserGabBonus(filled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '已填入金挂平均收益 ${filled.format(fractionDigits: 2)}%',
                  ),
                ),
              );
            },
            child: const Text('确认'),
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
    final store = Stores.infoStore;
    return ListenableBuilder(
      listenable: Listenable.merge([
        store.currentUserNotifier,
        store.dataVersionNotifier,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: .start,
              children: [const Text('推波收益计算'), _AppBarInfo()],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.restore_page),
                tooltip: '重置',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('重置'),
                      content: const Text('确认清空当前用户的所有收入样本？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            setState(() => _incomes.clear());
                          },
                          child: const Text('确认'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: store.waveNotifier,
            builder: (context, _) {
              final isWide = context.isWideScreen;
              final wave = store.waveNotifier.value;
              final gabCost = _gabCost(wave);
              final safeCost = gabCost > 0 ? gabCost : 0.0;
              final avgIncome = _incomes.isEmpty
                  ? 0.0
                  : _incomes.reduce((a, b) => a + b) / _incomes.length;
              final percent = _incomes.isEmpty
                  ? 0.0
                  : _sampleRate(avgIncome, safeCost);
              final Widget bodyView = Expanded(
                flex: isWide ? 6 : 1,
                child: _incomes.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无收入样本',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _incomes.length,
                        itemBuilder: (context, index) {
                          final income = _incomes[index];
                          return _IncomeTile(
                            index: index,
                            income: income,
                            rate: _sampleRate(income, safeCost),
                            onRemove: () => _removeIncome(index),
                          );
                        },
                      ),
              );
              final Widget summary = _buildSummaryCard(
                gabCost: gabCost,
                avgIncome: avgIncome,
                percent: percent,
              );
              return isWide
                  ? Row(
                      children: [
                        bodyView,
                        Expanded(flex: 4, child: summary),
                      ],
                    )
                  : Column(children: [bodyView, summary]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required double gabCost,
    required double avgIncome,
    required double percent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SummaryCard(
        children: <Widget>[
          SummaryRow(
            leadingIcon: Icons.money,
            title: Text('金挂成本'),
            trailing: SummaryRowValueText(text: gabCost.format()),
          ),
          SummaryRow(
            leadingIcon: Icons.monetization_on,
            title: Text('平均收入'),
            trailing: SummaryRowValueText(text: avgIncome.format()),
          ),
          SummaryRow(
            leadingIcon: Icons.percent,
            title: Text('百分比'),
            trailing: SummaryRowValueText(
              text: '${percent.format(fractionDigits: 2)}%',
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: .center,
            children: [
              FilledButton.icon(
                onPressed: _incomes.isEmpty
                    ? null
                    : () => _applyPercent(percent),
                icon: const Icon(Icons.draw),
                label: const Text('填入'),
              ),
              const SizedBox(width: 12.0),
              FilledButton.tonalIcon(
                onPressed: () => _addIncomeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),
        ],
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
    required this.onRemove,
  });

  final int index;
  final int income;
  final double rate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(999.0),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        income.format(),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${rate.format(fractionDigits: 2)}%', style: style),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }
}

/// 每波金币收入输入对话框
class _AddIncomeDialog extends StatefulWidget {
  const _AddIncomeDialog({required this.onAdd});

  final ValueChanged<int> onAdd;

  @override
  State<_AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<_AddIncomeDialog> {
  final TextEditingController _controller = TextEditingController();

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
    return AlertDialog(
      title: const Text('输入每波金币收入'),
      content: SelectAllTextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          helperText: '0-9',
          labelText: '每波金币收入',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _submit, child: const Text('添加')),
      ],
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = <Widget>[CurrentUser()];
    return AppBarInfo(children: segments);
  }
}
