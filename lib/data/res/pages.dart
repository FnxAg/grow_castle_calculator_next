import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/build_gp_page.dart';
import 'package:grow_castle_calculator_next/view/page/income_page.dart';

/// 页面在 AppBar 中声明的操作按钮构建器。
///
/// 页面数据变化通过 store 的 ValueNotifier 驱动 UI 重建，
/// 按钮只需直接调用 store 方法，无需手动刷新。
typedef PageActionsBuilder = List<Widget> Function(BuildContext context);

/// 抽屉页面注册表：新增页面只需在此追加一条记录，
/// 首页框架（[HomeTab]）会自动在抽屉中列出并支持切换。
class DrawerPageEntry {
  const DrawerPageEntry({
    required this.title,
    required this.icon,
    required this.builder,
    this.actionsBuilder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// 该页面在 AppBar 中显示的操作按钮；未提供则无
  final PageActionsBuilder? actionsBuilder;
}

/// 抽屉中按顺序显示的页面
final List<DrawerPageEntry> drawerPages = [
  // 阵容经济计算 AppBar
  DrawerPageEntry(
    title: '阵容经济计算',
    icon: Icons.calculate,
    builder: (_) => FormationCalcPage(),
    actionsBuilder: (context) => [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '新增条目',
        // 列表重建由 store 的 cardIdsNotifier 驱动
        onPressed: () => Stores.infoStore.addNewCard(),
      ),
      IconButton(
        icon: const Icon(Icons.list_alt),
        tooltip: '单位汇总',
        onPressed: () => _showUnitSummarySheet(context),
      ),
    ],
  ),
  // 收入计算 AppBar
  DrawerPageEntry(
    title: '收入计算',
    icon: Icons.trending_up,
    builder: (_) => IncomePage(),
  ),
];

/// 系统语言非中文时使用英文数量级缩写（K/M/B/T/P/E）
bool _useEnglishUnits(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return !code.startsWith('zh');
}

/// 弹出单位汇总表单（showModalBottomSheet + DraggableScrollableSheet，
/// 可拖拽到接近全高，方便安卓截图）。
///
/// 每行展示：序号、名称、等级、金币，以及
/// 占比（单位金币 / 总金币）、1/比例（单位等级 / 总波数）、比例（总波数 / 单位等级）；
/// 未启用单位的三个比例项固定显示 0。
/// 底部汇总条与 build_gp 一致：总波数 / 赛季波数 / 总金币 / GP / 指数。
void _showUnitSummarySheet(BuildContext context) {
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
        scrollController: scrollController,
      ),
    ),
  );
}

/// 单位汇总弹窗主体：拖拽把手 + 标题区 + 可滚动单位列表 + 底部汇总条
class _UnitSummarySheet extends StatelessWidget {
  const _UnitSummarySheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = Stores.infoStore;
    return Column(
      children: [
        // 拖拽把手
        Container(
          margin: const EdgeInsets.only(top: 8.0),
          width: 36.0,
          height: 4.0,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
          child: Row(
            children: [
              Text('单位汇总', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '用户：${store.getCurrentUser()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
        //   child: Text(
        //     '占比 = 金币/总金币 · 比例 = 等级/总波数',
        //     style: theme.textTheme.bodySmall?.copyWith(
        //       color: theme.colorScheme.onSurfaceVariant,
        //     ),
        //   ),
        // ),
        const Divider(height: 1.0),
        // 单位列表：等级/启用/波数 的变更最终都会触发 totalGoldNotifier，
        // 监听它即可覆盖全部数据刷新
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: store.totalGoldNotifier,
            builder: (context, totalGold, _) {
              final cardIds = store.getCardIds();
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                itemCount: cardIds.length,
                itemBuilder: (context, index) => _UnitSummaryRow(
                  id: cardIds[index],
                  index: index,
                  totalGold: totalGold,
                ),
              );
            },
          ),
        ),
        const Divider(height: 1.0),
        const _UnitSummaryBar(),
      ],
    );
  }
}

/// 单个单位汇总行：第一行 序号/名称/等级/金币，第二行 占比/1比例/比例
class _UnitSummaryRow extends StatelessWidget {
  const _UnitSummaryRow({
    required this.id,
    required this.index,
    required this.totalGold,
  });

  final int id;
  final int index;

  /// 启用单位金币之和，用于计算占比
  final double totalGold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = Stores.infoStore;
    final applied = store.getApplyFlag(id);
    final name = store.getTextValue(id);
    final level = int.tryParse(store.getNumberValue(id)) ?? 0;
    final gold = store.getUnitGold(id);
    final wave = store.getWave();

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
                    Flexible(
                      child: Text(
                        name.isNotEmpty ? name : '单位 $id',
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
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
                      gold.formatCompact(english: _useEnglishUnits(context)),
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
        borderRadius: BorderRadius.circular(4.0),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
  const _UnitSummaryBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = Stores.infoStore;
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
      child: ValueListenableBuilder<double>(
        valueListenable: store.totalGoldNotifier,
        // 等级/启用/波数 变化都会触发该通知，一次监听即可全部刷新
        builder: (context, totalGold, _) => Row(
          children: [
            _SummaryStat(
              label: '总波数',
              value: store.getWave().format(),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            _SummaryStat(
              label: '赛季波数',
              value: store.getSeasonWave().format(),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            _SummaryStat(
              label: '总金币',
              value: totalGold.formatCompact(
                english: _useEnglishUnits(context),
              ),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            _SummaryStat(
              label: 'GP',
              value: store.gpNotifier.value.format(fractionDigits: 3),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            _SummaryStat(
              label: '指数',
              value: store.gpCNNotifier.value.format(fractionDigits: 3),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
          ],
        ),
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
