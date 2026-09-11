import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/store/user_data.dart';
import 'package:material_ui/material_ui.dart';

/// 弹出单位汇总表单
///
/// 展示 [username] 用户的单位汇总，数据来自 [data] 快照（不随输入实时变化），
void showUnitSummarySheet(
  BuildContext context, {
  required String username,
  required UserData data,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (context, scrollController) => _UnitSummarySheet(
            username: username,
            data: data,
            scrollController: scrollController,
          ),
        ),
      ),
    ),
  );
}

/// 单位汇总弹窗主体：拖拽把手 + 标题区 + 可滚动单位列表 + 底部汇总条
class _UnitSummarySheet extends StatelessWidget {
  const _UnitSummarySheet({
    required this.username,
    required this.data,
    required this.scrollController,
  });

  final String username;
  final UserData data;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardIds = data.cardIds;
    final enabledCount = cardIds
        .where((id) => data.applyFlags[id] ?? true)
        .length;

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Column(
        children: [
          const SizedBox(height: 10.0),
          Container(
            width: 36.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('详细信息', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 3.0),
                      Text(
                        username,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: '$enabledCount/${cardIds.length} 启用',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _OverviewPanel(data: data),
          ),
          const SizedBox(height: 8.0),
          const Divider(height: 1.0),
          // 快照数据不随输入变化，无需监听 notifier
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
              itemCount: cardIds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8.0),
              itemBuilder: (context, index) =>
                  _UnitSummaryRow(id: cardIds[index], index: index, data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.0, color: colors.onSecondaryContainer),
            const SizedBox(width: 5.0),
            Text(
              label,
              style: TextStyle(
                color: colors.onSecondaryContainer,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.data});

  final UserData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 12.0),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _OverviewValue(
                  label: 'GP',
                  value: data.gp.format(fractionDigits: 3),
                  prominent: true,
                ),
              ),
              Container(
                width: 1.0,
                height: 42.0,
                color: colors.onPrimaryContainer.withValues(alpha: 0.16),
              ),
              Expanded(
                child: _OverviewValue(
                  label: '指数',
                  value: data.gpCN.format(fractionDigits: 3),
                  prominent: true,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(
              height: 1.0,
              color: colors.onPrimaryContainer.withValues(alpha: 0.14),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _OverviewValue(label: '总波数', value: data.wave.format()),
              ),
              Expanded(
                child: _OverviewValue(
                  label: '赛季波数',
                  value: data.seasonWave.format(),
                ),
              ),
              Expanded(
                child: _OverviewValue(
                  label: '总金币',
                  value: data.totalGold.formatCompact(english: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.onPrimaryContainer.withValues(alpha: 0.72),
            fontSize: 11.0,
          ),
        ),
        const SizedBox(height: 3.0),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontSize: prominent ? 22.0 : 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitSummaryRow extends StatelessWidget {
  const _UnitSummaryRow({
    required this.id,
    required this.index,
    required this.data,
  });

  final int id;
  final int index;
  final UserData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applied = data.applyFlags[id] ?? true;
    final name = data.textValues[id] ?? '';
    final level = int.tryParse(data.numberValues[id] ?? '') ?? 0;
    final gold = data.unitGold[id] ?? 0.0;
    final wave = data.wave;
    final totalGold = data.totalGold;

    // 占比 = 单位金币 / 总金币；未启用固定为 0
    final share = applied && totalGold > 0 ? gold / totalGold * 100 : 0.0;
    // 1/比例 = 单位等级 / 总波数；比例 为其倒数（总波数 / 单位等级）；
    // 未启用或除数为 0 时均为 0
    final oneOverRatio = applied && wave > 0 && level > 0 ? level / wave : 0.0;
    final ratio = oneOverRatio > 0 ? 1 / oneOverRatio : 0.0;

    final colors = theme.colorScheme;
    final title = name.isNotEmpty
        ? name
        : id == 1
        ? '城堡'
        : id == 2
        ? '城弓'
        : '单位 $id';

    return Opacity(
      opacity: applied ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 10.0),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _IndexBadge(index: index, applied: applied),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Lv. ${level.format()}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12.0),
                Text(
                  gold.formatCompact(english: false),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                _metric(theme, '金币占比', '${_fmt(share)}%', applied),
                _metricDivider(colors),
                _metric(theme, '单位 / 波数', _fmt(oneOverRatio), applied),
                _metricDivider(colors),
                _metric(theme, '波数 / 单位', _fmt(ratio), applied),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 占比/比例数值：数值过小时自动增加小数位，避免显示成 0.00
  static String _fmt(double v) {
    if (v == 0) return '0';
    final digits = v.abs() < 0.0001
        ? 6
        : v.abs() < 0.01
        ? 4
        : 2;
    return v.format(fractionDigits: digits);
  }
}

/// 序号徽标，未启用时置灰
class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index, required this.applied});

  final int index;
  final bool applied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 22.0,
      height: 22.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: applied
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
          color: applied
              ? theme.colorScheme.onPrimaryContainer
              : theme.disabledColor,
        ),
      ),
    );
  }
}

Widget _metric(ThemeData theme, String label, String value, bool applied) {
  final labelStyle = TextStyle(
    fontSize: 11.0,
    color: theme.colorScheme.onSurfaceVariant,
  );
  final valueStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: applied ? theme.colorScheme.primary : theme.disabledColor,
  );
  return Expanded(
    child: Column(
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 3.0),
        Text(value, style: valueStyle),
      ],
    ),
  );
}

Widget _metricDivider(ColorScheme colors) => SizedBox(
  height: 24.0,
  child: VerticalDivider(
    width: 1.0,
    color: colors.outlineVariant.withValues(alpha: 0.6),
  ),
);
