import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

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

class _BonusGoldCalcPageState extends State<BonusGoldCalcPage> {
  /// 各用户的每波金币收入样本，会话级按用户 id 缓存。
  ///
  /// 切换用户（UserPageScaffold 换 key 重建本页）时各自的样本互不干扰。
  static final Map<int, List<int>> _incomesByUser = {};

  /// 当前用户的样本列表：initState 按当前用户名从 [_incomesByUser] 取出
  late List<int> _incomes;

  @override
  void initState() {
    super.initState();
    _incomes = _incomesByUser.putIfAbsent(
      Stores.infoStore.getCurrentUserId(),
      () => [],
    );
  }

  @override
  void dispose() {
    super.dispose();
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
    return UserPageScaffold(
      title: '推波收益计算',
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
      body: ListenableBuilder(
        listenable: Stores.infoStore.waveNotifier,
        builder: (context, _) {
          final wave = Stores.infoStore.waveNotifier.value;
          final gabCost = _gabCost(wave);
          final safeCost = gabCost > 0 ? gabCost : 0.0;
          final avgIncome = _incomes.isEmpty
              ? 0.0
              : _incomes.reduce((a, b) => a + b) / _incomes.length;
          final percent = _incomes.isEmpty
              ? 0.0
              : _sampleRate(avgIncome, safeCost);
          final summary = _buildSummaryCard(
            gabCost: gabCost,
            avgIncome: avgIncome,
            percent: percent,
          );
          return Column(
            children: [
              Expanded(
                child: _incomes.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无收入样本，点击右上角 + 添加',
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
              ),
              summary,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required double gabCost,
    required double avgIncome,
    required double percent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3.0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.money,
                label: '金挂成本',
                value: gabCost.format(),
              ),
              _SummaryRow(
                icon: Icons.monetization_on,
                label: '平均收入',
                value: avgIncome.format(),
              ),
              _SummaryRow(
                icon: Icons.percent,
                label: '百分比',
                value: '${percent.format(fractionDigits: 2)}%',
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
                    label: const Text('填入收益'),
                  ),
                  const SizedBox(width: 12.0),
                  FilledButton.tonalIcon(
                    onPressed: () => _addIncomeDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('添加收入'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单条收入样本行：序号徽标 + 金额 + 相对金挂成本的收益率 + 删除按钮
class _IncomeTile extends StatelessWidget {
  const _IncomeTile({
    required this.index,
    required this.income,
    required this.rate,
    required this.onRemove,
  });

  /// 样本序号（展示从 1 开始）
  final int index;
  final int income;

  /// 该样本相对金挂成本的收益率（%）
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

/// 汇总行：标签 + 右侧数值
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 20.0, color: colorScheme.primary),
          const SizedBox(width: 8.0),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 每波金币收入输入对话框：输入控制器由 State 持有，随对话框销毁自动释放
class _AddIncomeDialog extends StatefulWidget {
  const _AddIncomeDialog({required this.onAdd});

  /// 输入可解析为整数时回调；输入为空/非法时仅关闭对话框、不回调
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
