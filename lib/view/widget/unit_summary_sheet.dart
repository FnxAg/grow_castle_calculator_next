import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/store/user_data.dart';

/// 系统语言非中文时使用英文数量级缩写（K/M/B/T/P/E）
bool _useEnglishUnits(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return !code.startsWith('zh');
}

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
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _UnitSummarySheet(
        username: username,
        data: data,
        scrollController: scrollController,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
          child: Row(
            children: [
              Text('账号信息', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                username,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1.0),
        // 快照数据不随输入变化，无需监听 notifier
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            itemCount: cardIds.length,
            itemBuilder: (context, index) => _UnitSummaryRow(
              id: cardIds[index],
              index: index,
              data: data,
            ),
          ),
        ),
        const Divider(height: 1.0),
        _UnitSummaryBar(data: data),
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

    final nameStyle = TextStyle(
      fontWeight: FontWeight.w600,
      decoration: applied ? null : TextDecoration.lineThrough,
      color: applied ? null : theme.disabledColor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IndexBadge(index: index, applied: applied),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name.isNotEmpty ? name : id == 1 ? '城堡' : id == 2 ? '城弓' : '单位 $id',
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Lv.${level.format()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      gold.formatCompact(english: false),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: applied
                            ? theme.colorScheme.primary
                            : theme.disabledColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Row(
                  children: [
                    _metric(theme, '占比', '${_fmt(share)}%', applied),
                    const SizedBox(width: 12.0),
                    _metric(theme, '1/比例', _fmt(oneOverRatio), applied),
                    const SizedBox(width: 12.0),
                    _metric(theme, '比例', _fmt(ratio), applied),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 占比/比例数值：数值过小时自动增加小数位，避免显示成 0.00
  static String _fmt(double v) {
    if (v == 0) return '0';
    final digits = v.abs() < 0.0001 ? 6 : v.abs() < 0.01 ? 4 : 2;
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

/// 第二行指标项：标签与数值分居两端，保证同列数值纵向对齐
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
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(width: 4.0),
        Text(value, style: valueStyle),
      ],
    ),
  );
}

/// 底部汇总条：与 build_gp 汇总一致的 总波数/赛季波数/总金币/GP/指数
class _UnitSummaryBar extends StatelessWidget {
  const _UnitSummaryBar({required this.data});

  final UserData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = TextStyle(
      fontSize: 11.0,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = TextStyle(
      fontSize: 13.0,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 12.0),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
      child: Row(
        children: [
          _SummaryStat(
            label: '总波数',
            value: data.wave.format(),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          _SummaryStat(
            label: '赛季波数',
            value: data.seasonWave.format(),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          _SummaryStat(
            label: '总金币',
            value: data.totalGold.formatCompact(
              english: false,
            ),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          _SummaryStat(
            label: 'GP',
            value: data.gp.format(fractionDigits: 3),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          _SummaryStat(
            label: '指数',
            value: data.gpCN.format(fractionDigits: 3),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ],
      ),
    );
  }
}

/// 汇总条单项：标签 + 数值，数值过长时自动缩放
class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: valueStyle, maxLines: 1),
          ),
        ],
      ),
    );
  }
}
