import 'package:grow_castle_calculator_next/core/service/api.dart';

/// 榜单里程碑名次
const List<int> rankMilestoneRanks = [1, 3, 5, 10, 50, 100, 200, 300];

/// 里程碑名次对应的榜单条目
class RankMilestone {
  const RankMilestone({required this.name, required this.score});

  final String name;
  final int score;
}

/// 榜单中里程碑名次对应的条目；没有榜单数据时返回 null
Map<int, RankMilestone>? milestonesOf(SeasonQueryResult<RankInfo>? ranking) {
  if (ranking == null) return null;
  final entries = <int, RankMilestone>{};
  for (final milestoneRank in rankMilestoneRanks) {
    RankInfo? closestItem;
    for (final item in ranking.items) {
      if (item.rank <= milestoneRank &&
          (closestItem == null || item.rank > closestItem.rank)) {
        closestItem = item;
      }
    }
    if (closestItem != null) {
      entries[milestoneRank] = RankMilestone(
        name: closestItem.name,
        score: closestItem.score,
      );
    }
  }
  return entries;
}

/// [rank] 之前（名次更靠前）与之后最近的里程碑名次
(int?, int?) milestonesAround(int rank) {
  int? previous;
  int? next;
  for (final milestone in rankMilestoneRanks) {
    if (milestone < rank) {
      previous = milestone;
    } else if (milestone > rank && next == null) {
      next = milestone;
    }
  }
  return (previous, next);
}
