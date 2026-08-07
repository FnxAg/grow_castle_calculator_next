import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 阵容页底部汇总条：总波数 / 赛季波数（可编辑、可联网查询）、排名胶囊、
/// 总金币、GP、指数。数值变化由 store 的 ValueNotifier 驱动实时更新。
class FormationSummaryBar extends StatelessWidget {
  const FormationSummaryBar({
    super.key,
    required this.querying,
    required this.playerRank,
    required this.playerGapPrev,
    required this.playerGapNext,
    required this.hellRank,
    required this.guildRank,
    required this.onQuery,
  });

  /// 联网查询进行中（按钮显示转圈并禁用）
  final bool querying;

  /// 玩家赛季榜排名（前 300 内才显示，不在榜单则隐藏）
  final int? playerRank;

  /// 与上一名/下一名的分数差距；首名/末名时对应侧为 null
  final int? playerGapPrev;
  final int? playerGapNext;

  /// 无尽榜排名（前 300 内才显示）
  final int? hellRank;

  /// 所属公会在公会榜上的排名（前 300 内才显示）
  final int? guildRank;

  /// 联网查询按钮回调（冷却与提示逻辑在页面 State 中）
  final VoidCallback onQuery;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.emoji_events,
            label: '总波数',
            actions: [
              _SmallIconButton(
                icon: const Icon(Icons.edit),
                tooltip: '修改总波数',
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  showWaveEditDialog(
                    context,
                    title: '设置总波数',
                    labelText: '总波数',
                    fallback: 1,
                    onSave: Stores.infoStore.setUserWave,
                  );
                },
              ),
              // 未配置用户（userId == 0）不显示联网查询按钮
              if (Stores.infoStore.getCurrentUserId() != 0)
                _SmallIconButton(
                  icon: querying
                      ? const SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.cloud_sync),
                  tooltip: '联网查询波数',
                  onPressed: querying ? null : onQuery,
                ),
            ],
            value: ValueListenableBuilder<int>(
              valueListenable: Stores.infoStore.waveNotifier,
              builder: (context, wave, _) => _ValueText(text: wave.format()),
            ),
          ),
          _SummaryRow(
            icon: Icons.eco,
            label: '赛季波数',
            actions: [
              _SmallIconButton(
                icon: const Icon(Icons.edit),
                tooltip: '修改赛季波数',
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  showWaveEditDialog(
                    context,
                    title: '设置赛季波数',
                    labelText: '赛季波数',
                    fallback: 0,
                    onSave: Stores.infoStore.setCurrentUserSeasonWave,
                  );
                },
              ),
            ],
            value: ValueListenableBuilder<int>(
              valueListenable: Stores.infoStore.seasonWaveNotifier,
              builder: (context, seasonWave, _) =>
                  _ValueText(text: seasonWave.format()),
            ),
          ),
          // 排名行：个人赛季 / 无尽 / 所属公会三类榜单有任一排名才显示
          if (playerRank != null || hellRank != null || guildRank != null)
            _RankRow(
              playerRank: playerRank,
              playerGapPrev: playerGapPrev,
              playerGapNext: playerGapNext,
              hellRank: hellRank,
              guildRank: guildRank,
            ),
          _SummaryRow(
            icon: Icons.monetization_on_outlined,
            label: '总金币',
            value: ValueListenableBuilder<double>(
              valueListenable: Stores.infoStore.totalGoldNotifier,
              builder: (context, gold, _) => _ValueText(
                text: gold.formatCompact(fractionDigits: 2, english: false),
              ),
            ),
          ),
          _SummaryRow(
            icon: Icons.star,
            label: 'GP',
            value: ValueListenableBuilder<double>(
              valueListenable: Stores.infoStore.gpNotifier,
              builder: (context, gp, _) =>
                  _ValueText(text: gp.format(fractionDigits: 3)),
            ),
          ),
          _SummaryRow(
            icon: Icons.local_fire_department,
            label: '指数',
            value: ValueListenableBuilder<double>(
              valueListenable: Stores.infoStore.gpCNNotifier,
              builder: (context, gpCN, _) =>
                  _ValueText(text: gpCN.format(fractionDigits: 3)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹窗输入整数（波数/赛季波数），确定后调用 [onSave]；空输入回退 [fallback]。
///
/// 控制器随对话框路由销毁后由 GC 回收，不手动 dispose：若 pop 后立即释放，
/// 路由退场动画期间 TextField 仍挂载，访问已释放的控制器会抛异常导致路由卡死。
Future<void> showWaveEditDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required int fallback,
  required ValueChanged<int> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text(title),
        content: SelectAllTextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: labelText,
            helperText: '0-9',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? fallback;
              onSave(value);
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      );
    },
  );
}

/// 汇总行：图标 + 标签 + 行内操作按钮 + 右侧数值
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    this.actions = const [],
    required this.value,
  });

  final IconData icon;
  final String label;

  /// 标签与数值之间的行内操作按钮（编辑/联网查询）
  final List<Widget> actions;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20.0, color: colorScheme.primary),
        const SizedBox(width: 8.0),
        Text(label),
        const SizedBox(width: 8.0),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 4.0),
          actions[i],
        ],
        const Spacer(),
        value,
      ],
    );
  }
}

/// 排名胶囊行：个人赛季 / 无尽 / 所属公会，内容过宽时可横向滚动
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.playerRank,
    required this.playerGapPrev,
    required this.playerGapNext,
    required this.hellRank,
    required this.guildRank,
  });

  final int? playerRank;
  final int? playerGapPrev;
  final int? playerGapNext;
  final int? hellRank;
  final int? guildRank;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const chipTextStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Icon(Icons.leaderboard, size: 20.0, color: colorScheme.primary),
        const SizedBox(width: 8.0),
        const Text('排名'),
        // 胶囊靠右，与其他行的数值展示样式统一
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 个人赛季榜：与上一名/下一名的分数差距（首尾无对应名次则隐藏）
                  if (playerGapPrev != null) ...[
                    PillChip(
                      backgroundColor: Colors.red,
                      foreground: Colors.white,
                      icon: Icons.arrow_upward,
                      text: Text(
                        playerGapPrev!.format(),
                        style: chipTextStyle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                  ],
                  if (playerRank != null) ...[
                    PillChip(
                      text: Text('#$playerRank', style: chipTextStyle),
                      icon: Icons.eco,
                    ),
                    const SizedBox(width: 4.0),
                  ],
                  if (playerGapNext != null) ...[
                    PillChip(
                      backgroundColor: Colors.green,
                      foreground: Colors.white,
                      icon: Icons.arrow_downward,
                      text: Text(
                        playerGapNext!.format(),
                        style: chipTextStyle,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  if (hellRank != null) ...[
                    PillChip(
                      text: Text('#$hellRank', style: chipTextStyle),
                      // 无尽模式：∞ 无限符号
                      icon: Icons.all_inclusive,
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  if (guildRank != null) ...[
                    PillChip(
                      text: Text('#$guildRank', style: chipTextStyle),
                      icon: Icons.flag_circle,
                    ),
                    const SizedBox(width: 8.0),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 汇总数值：主题色加粗大字
class _ValueText extends StatelessWidget {
  const _ValueText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }
}

/// 20x20 的行内小图标按钮（汇总行编辑/查询入口）
class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: IconButton(
        icon: icon,
        iconSize: 20.0,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: Theme.of(context).colorScheme.primary,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
