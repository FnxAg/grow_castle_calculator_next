import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

String rankingKindLabel(AppLocalizations l10n, RankingKind kind) =>
    switch (kind) {
      RankingKind.player => l10n.rankingKindPlayer,
      RankingKind.guild => l10n.rankingKindGuild,
      RankingKind.hell => l10n.rankingKindHell,
    };

/// 排行榜
enum RankingKind {
  player(icon: Icons.eco, crossIcon: Icons.all_inclusive),
  guild(icon: Icons.flag_circle, crossIcon: null),
  hell(icon: Icons.all_inclusive, crossIcon: Icons.eco);

  const RankingKind({required this.icon, this.crossIcon});
  final IconData icon;
  final IconData? crossIcon;
}

/// 归一化后的榜单行
class RankRow {
  const RankRow({
    required this.rank,
    required this.name,
    required this.score,
    this.gapPrev,
    this.gapNext,
  });

  final int rank;
  final String name;
  final int score;
  final int? gapPrev;
  final int? gapNext;
}
