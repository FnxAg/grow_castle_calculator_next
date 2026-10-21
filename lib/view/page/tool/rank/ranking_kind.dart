import 'package:material_ui/material_ui.dart';

/// 排行榜
enum RankingKind {
  player(icon: Icons.eco, crossIcon: Icons.all_inclusive),
  guild(icon: Icons.flag_circle, crossIcon: null),
  hell(icon: Icons.all_inclusive, crossIcon: Icons.eco);

  const RankingKind({required this.icon, this.crossIcon});
  final IconData icon;
  final IconData? crossIcon;
}
