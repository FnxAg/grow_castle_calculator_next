import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

/// 排名胶囊行
class RankPillRow extends StatelessWidget {
  const RankPillRow({super.key, this.rank, this.gapPrev, this.gapNext});

  final int? rank;
  final int? gapPrev;
  final int? gapNext;

  static bool _played = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    const chipTextStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
    );
    final chips = <(Widget, double)>[
      if (gapPrev != null)
        (
          PillChip(
            backgroundColor: Colors.red,
            foreground: Colors.white,
            icon: Icons.arrow_upward,
            text: Text(
              gapPrev! >= 10000000
                  ? gapPrev!.formatCompact(
                      english: english,
                      traditional: traditional,
                    )
                  : gapPrev!.format(),
              style: chipTextStyle,
            ),
          ),
          4.0,
        ),
      if (rank != null)
        (
          PillChip(
            text: Text('#$rank', style: chipTextStyle),
            icon: Icons.eco,
          ),
          4.0,
        ),
      if (gapNext != null)
        (
          PillChip(
            backgroundColor: Colors.green,
            foreground: Colors.white,
            icon: Icons.arrow_downward,
            text: Text(
              gapNext! >= 10000000
                  ? gapNext!.formatCompact(
                      english: english,
                      traditional: traditional,
                    )
                  : gapNext!.toString(),
              style: chipTextStyle,
            ),
          ),
          8.0,
        ),
    ];
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
