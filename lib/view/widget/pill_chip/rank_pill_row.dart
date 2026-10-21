import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/guild_rank.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_hell_mode_rank.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_rank.dart';
import 'package:grow_castle_calculator_next/icon/box.dart';
import 'package:grow_castle_calculator_next/icon/crystal.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/tool/rank/ranking_kind.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/subtitle_pill_wrap.dart';
import 'package:material_ui/material_ui.dart';

/// 排名胶囊行
class RankPillRow extends StatelessWidget {
  const RankPillRow({
    super.key,
    this.rankingKind,
    this.rank,
    this.gapPrev,
    this.gapNext,
  });

  final RankingKind? rankingKind;
  final int? rank;
  final int? gapPrev;
  final int? gapNext;

  static bool _played = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    final chips = SubtitlePillWrap(
      children: [
        if (rankingKind != null)
          PillChip(
            text: Text(switch (rankingKind) {
              .player => '${getRedCrystalFromPlayerRank(rank ?? 0)}',
              .guild => '${getItemBoxFromGuildRank(rank ?? 0)}',
              .hell => '${getRedCrystalFromHellModeRank(rank ?? 0)}',
              _ => '',
            }, style: PillChip.textStyle),
            leading: switch (rankingKind) {
              .player || .hell => CrystalIcon(
                size: PillChip.leadingIconSize,
                color: colorScheme.primary,
              ),
              .guild => BoxIcon(
                size: PillChip.leadingIconSize,
                color: colorScheme.primary,
              ),
              _ => null,
            },
          ),
        if (gapPrev != null)
          PillChip(
            backgroundColor: Colors.red,
            foreground: Colors.white,
            leading: Icon(Icons.arrow_upward, size: PillChip.leadingIconSize),
            text: Text(
              gapPrev! >= 10000000
                  ? gapPrev!.formatCompact(
                      english: english,
                      traditional: traditional,
                    )
                  : gapPrev!.format(),
              style: PillChip.textStyle,
            ),
          ),
        if (rank != null)
          PillChip(
            text: Text('#$rank', style: PillChip.textStyle),
            leading: Icon(Icons.eco, size: PillChip.leadingIconSize),
          ),
        if (gapNext != null)
          PillChip(
            backgroundColor: Colors.green,
            foreground: Colors.white,
            leading: Icon(Icons.arrow_downward, size: PillChip.leadingIconSize),
            text: Text(
              gapNext! >= 10000000
                  ? gapNext!.formatCompact(
                      english: english,
                      traditional: traditional,
                    )
                  : gapNext!.format(),
              style: PillChip.textStyle,
            ),
          ),
      ],
    );
    final row = Row(
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [chips]),
            ),
          ),
        ),
      ],
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
