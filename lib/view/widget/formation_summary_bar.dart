import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 阵容页底部汇总条
class FormationSummaryBar extends ConsumerWidget {
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

  /// 联网查询进行中
  final bool querying;

  /// 玩家赛季榜排名
  final int? playerRank;

  /// 与上一名/下一名的分数差距
  final int? playerGapPrev;
  final int? playerGapNext;

  /// 无尽榜排名
  final int? hellRank;

  /// 所属公会在公会榜上的排名
  final int? guildRank;

  /// 联网查询按钮回调
  final VoidCallback onQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDefaultUser = ref.watch(currentUserIdProvider) == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: SummaryCard(
        children: <Widget>[
          SummaryRow(
            leadingIcon: Icons.emoji_events,
            title: Text(l10n.totalWave),
            actions: [
              if (isDefaultUser)
                _SmallIconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.tooltipEditTotalWave,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    showWaveEditDialog(
                      context,
                      title: l10n.dialogSetTotalWave,
                      labelText: l10n.totalWave,
                      fallback: 1,
                      onSave: ref.users.setUserWave,
                    );
                  },
                ),
              if (isMobile && !isDefaultUser)
                _SmallIconButton(
                  icon: querying
                      ? const SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.cloud_sync),
                  tooltip: l10n.tooltipFetchData,
                  onPressed: querying ? null : onQuery,
                ),
            ],
            trailing: SummaryRowValueText(
              text: ref.watch(currentUserWaveProvider).format(),
            ),
          ),
          SummaryRow(
            leadingIcon: Icons.eco,
            title: Text(l10n.seasonWave),
            actions: [
              if (isDefaultUser)
                _SmallIconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.tooltipEditSeasonWave,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    showWaveEditDialog(
                      context,
                      title: l10n.dialogSetSeasonWave,
                      labelText: l10n.seasonWave,
                      fallback: 0,
                      onSave: ref.users.setCurrentUserSeasonWave,
                    );
                  },
                ),
            ],
            trailing: SummaryRowValueText(
              text: ref.watch(currentUserSeasonWaveProvider).format(),
            ),
          ),
          // 排名行
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: (playerRank != null || hellRank != null || guildRank != null)
                ? _RankIntro(
                    playerRank: playerRank,
                    playerGapPrev: playerGapPrev,
                    playerGapNext: playerGapNext,
                    hellRank: hellRank,
                    guildRank: guildRank,
                  )
                : const SizedBox(width: double.infinity),
          ),
          SummaryRow(
            leadingIcon: Icons.monetization_on,
            title: Text(l10n.totalGold),
            trailing: SummaryRowValueText(
              text: ref
                  .watch(currentUserTotalGoldProvider)
                  .formatCompact(
                    fractionDigits: 2,
                    english: !context.isChineseLocale,
                    traditional: context.isTraditionalChineseLocale,
                  ),
            ),
          ),
          SummaryRow(
            leadingIcon: Icons.star,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(l10n.goldPower)],
            ),
            trailing: SummaryRowValueText(
              text:
                  '${ref.watch(currentUserGpProvider).format(fractionDigits: 3)}'
                  ' · '
                  '${ref.watch(currentUserGpCnProvider).format(fractionDigits: 3)}',
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showWaveEditDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required int fallback,
  required ValueChanged<int> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _WaveEditDialog(
      title: title,
      labelText: labelText,
      fallback: fallback,
      onSave: onSave,
    ),
  );
}

class _WaveEditDialog extends StatefulWidget {
  const _WaveEditDialog({
    required this.title,
    required this.labelText,
    required this.fallback,
    required this.onSave,
  });

  final String title;
  final String labelText;

  final int fallback;
  final ValueChanged<int> onSave;

  @override
  State<_WaveEditDialog> createState() => _WaveEditDialogState();
}

class _WaveEditDialogState extends State<_WaveEditDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SelectAllTextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.labelText,
          helperText: '0-9',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).actionCancel),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? widget.fallback;
            widget.onSave(value);
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).actionSave),
        ),
      ],
    );
  }
}

class _RankIntro extends StatelessWidget {
  const _RankIntro({
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

  static bool _played = false;

  @override
  Widget build(BuildContext context) {
    final row = _RankRow(
      playerRank: playerRank,
      playerGapPrev: playerGapPrev,
      playerGapNext: playerGapNext,
      hellRank: hellRank,
      guildRank: guildRank,
    );
    if (_played) return row;
    _played = true;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: row,
    );
  }
}

/// 排名胶囊行
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
    final chips = <(Widget, double)>[
      if (playerGapPrev != null)
        (
          PillChip(
            backgroundColor: Colors.red,
            foreground: Colors.white,
            icon: Icons.arrow_upward,
            text: Text(playerGapPrev!.format(), style: chipTextStyle),
          ),
          4.0,
        ),
      if (playerRank != null)
        (
          PillChip(
            text: Text('#$playerRank', style: chipTextStyle),
            icon: Icons.eco,
          ),
          4.0,
        ),
      if (playerGapNext != null)
        (
          PillChip(
            backgroundColor: Colors.green,
            foreground: Colors.white,
            icon: Icons.arrow_downward,
            text: Text(playerGapNext!.format(), style: chipTextStyle),
          ),
          8.0,
        ),
      if (hellRank != null)
        (
          PillChip(
            text: Text('#$hellRank', style: chipTextStyle),
            icon: Icons.all_inclusive,
          ),
          8.0,
        ),
      if (guildRank != null)
        (
          PillChip(
            text: Text('#$guildRank', style: chipTextStyle),
            icon: Icons.flag_circle,
          ),
          8.0,
        ),
    ];
    return Row(
      children: [
        Icon(Icons.leaderboard, size: 20.0, color: colorScheme.primary),
        const SizedBox(width: 8.0),
        Text(AppLocalizations.of(context).ranking),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    chips[i].$1,
                    if (i < chips.length - 1) SizedBox(width: chips[i].$2),
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
