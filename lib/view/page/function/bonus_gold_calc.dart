import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 收入百分比计算页：添加若干「每波金币收入」样本，
/// 按金挂成本（gabCost = 456 × 当前总波数 − 29264）计算收益率：
/// （收入 − 成本）÷ 成本，底部卡片汇总平均每波收入与百分比，
/// 可一键填入当前用户的「金挂平均收益」。
/// 样本保存在内存中（static），页面退出重进不丢失。
class BonusGoldCalcPage extends StatefulWidget {
  const BonusGoldCalcPage({super.key});

  @override
  State<BonusGoldCalcPage> createState() => _BonusGoldCalcPageState();
}

class _BonusGoldCalcPageState extends State<BonusGoldCalcPage> {
  /// 用户添加的每波金币收入样本（顺序即展示顺序）。
  /// static 保存在内存：页面被 pop 销毁后数据仍在，重进继续编辑。
  static final List<int> _incomes = [];

  static final ValueNotifier<int> _listLen = ValueNotifier(0);

  double _gabCost(int wave) => 456.0 * wave - 29264;

  void _addIncome(int gold) {
    _incomes.add(gold);
    _listLen.value = _incomes.length;
  }

  void _removeIncome(int index) {
    _incomes.removeAt(index);
    _listLen.value = _incomes.length;
  }

  /// 填入「金挂平均收益」：保留两位小数，写入后由 store 驱动收入汇总刷新
  void _applyPercent(double percent) {
    final filled = (percent * 100).roundToDouble() / 100;
    Stores.infoStore.setCurrentUserGabBonus(filled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已填入金挂平均收益 ${filled.format(fractionDigits: 2)}%')),
    );
  }

  /// 添加收入样本弹窗：输入每波金币收入
  void _showDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('输入每波金币收入'),
          content: SelectAllTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(helperText: '0-9', labelText: '每波金币收入'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final gold = int.tryParse(controller.text);
                if (gold != null) {
                  _addIncome(gold);
                }
                Navigator.of(context).pop();
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return UserPageScaffold(
      title: '收入百分比计算',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '添加收入',
          onPressed: _showDialog,
        ),
      ],
      body: ValueListenableBuilder<int>(
        valueListenable: Stores.infoStore.waveNotifier,
        builder: (context, wave, _) {
          final gabCost = _gabCost(wave);
          final safeCost = gabCost > 0 ? gabCost : 0.0;
          return ValueListenableBuilder<int>(
            valueListenable: _listLen,
            builder: (context, _, _) {
              final avgIncome = _incomes.isEmpty
                  ? 0.0
                  : _incomes.reduce((a, b) => a + b) / _incomes.length;
              final percent = _incomes.isNotEmpty ? (safeCost > 0
                  ? (avgIncome - safeCost) / safeCost * 100
                  : 0.0) : 0.0;
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
                              final scheme = Theme.of(context).colorScheme;
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.0,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(safeCost > 0 ? (income - safeCost) / safeCost * 100 : 0.0).format(fractionDigits: 2)}%',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeIncome(index),
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  _buildSummaryCard(context, wave, avgIncome, percent),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int wave,
    double avgIncome,
    double percent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
          child: Column(
            children: [
              Text(
                '当前总波数 ${wave.format()} · 金挂成本 ${_gabCost(wave).format()}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 8.0),
              _SummaryRow(icon: Icons.monetization_on, label: '平均每波收入', value: avgIncome.format()),
              _SummaryRow(
                icon: Icons.percent,
                label: '百分比',
                value: '${percent.format(fractionDigits: 2)}%',
              ),
              const SizedBox(height: 12.0),
              FilledButton.icon(
                // 无样本时禁用
                onPressed: _incomes.isEmpty
                    ? null
                    : () => _applyPercent(percent),
                icon: const Icon(Icons.draw),
                label: const Text('填入收益'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 汇总行：标签 + 右侧数值
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

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
