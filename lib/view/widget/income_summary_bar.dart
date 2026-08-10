import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';

/// 收入页底部汇总条：每日殖民地 / 挂机 / 其他收入与总收入。
///
/// 数值由 store 的 incomeNotifier 驱动实时更新（收入参数、跳波参数、
/// 波数变更或切换用户时触发），分项见 core/calc/gold_income.dart。
class IncomeSummaryBar extends StatelessWidget {
  const IncomeSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 卡片效果与阵容页底部汇总条统一：16 外边距 + Card + 内边距
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: ValueListenableBuilder<int>(
        valueListenable: Stores.infoStore.incomeNotifier,
        builder: (context, _, _) {
          final income = Stores.infoStore.getCurrentUserDailyIncomeBreakdown();
          return Column(
            children: [
              _IncomeRow(
                icon: Icons.terrain,
                label: '每日殖民地收入',
                value: income.colony,
              ),
              _IncomeRow(
                icon: Icons.bolt,
                label: '每日挂机收入',
                value: income.autoBattle,
              ),
              _IncomeRow(
                icon: Icons.park,
                label: '每日其他收入',
                value: income.other,
              ),
              _IncomeRow(
                icon: Icons.monetization_on_outlined,
                label: '每日总收入',
                value: income.total,
              ),
            ],
          );
        },
          ),
        ),
      ),
    );
  }
}

/// 汇总行：图标 + 标签 + 右侧数值（中文数量级缩写，与阵容页总金币风格一致）
class _IncomeRow extends StatelessWidget {
  const _IncomeRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20.0, color: colorScheme.primary),
        const SizedBox(width: 8.0),
        Text(label),
        const Spacer(),
        Text(
          value.formatCompact(fractionDigits: 2, english: false),
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
