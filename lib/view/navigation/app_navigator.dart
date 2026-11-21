import 'package:go_router/go_router.dart';
import 'package:grow_castle_calculator_next/view/navigation/app_routes.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/models.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// 页面跳转具名入口：跨分支用 go，同分支详情用 push。
extension AppNavigator on BuildContext {
  GoRouter get appRouter => GoRouter.of(this);

  /// 当前 location 所属分支根
  String get currentBranchRoot => AppRoutes.branchRootOf(appRouter.state.uri);

  Future<T?> pushLocation<T extends Object?>(
    String location, {
    Object? extra,
  }) => appRouter.push<T>(location, extra: extra);

  // 功能页：属于 Function 分支；从其它 tab 打开时切换分支
  void openBuildCalc() {
    if (currentBranchRoot == AppRoutes.function || !isDesktopPlatform()) {
      appRouter.push(AppRoutes.buildCalc);
    } else {
      appRouter.go(AppRoutes.buildCalc);
    }
  }

  void openWaveStatus() => appRouter.push(AppRoutes.waveStatus);

  void openBonusGold() => appRouter.push(AppRoutes.bonusGold);

  void openIncome() => appRouter.push(AppRoutes.income);

  void openIncomeTrend() => appRouter.push(AppRoutes.incomeTrend);

  void openGameTrack() => appRouter.push(AppRoutes.gameTrack);

  void openGameTrackChart() => appRouter.push(AppRoutes.gameTrackChart);

  // 通用详情：留在当前分支
  void openPlayerDetail(String name) =>
      appRouter.push(AppRoutes.player(currentBranchRoot, name));

  void openGuildDetail(String name, {DateTime? date}) {
    final location = AppRoutes.guildDetail(name, date: date);
    if (currentBranchRoot == AppRoutes.tools) {
      appRouter.push(location);
    } else {
      appRouter.go(location);
    }
  }

  // 工具
  void openRanking(RankingKind kind) => appRouter.push(AppRoutes.ranking(kind));

  void openRankingChart(RankingKind kind, {DateTime? date}) =>
      appRouter.push(AppRoutes.rankingChart(kind, date: date));

  void openSearch() => appRouter.push(AppRoutes.search);

  void openQuickCalc() => appRouter.push(AppRoutes.quickCalc);

  void openDragonSimulator() => appRouter.push(AppRoutes.dragonSimulator);

  void openItemRules() => appRouter.push(AppRoutes.itemRules);

  void openNewItemRule() => appRouter.push(AppRoutes.newItemRule);

  void openEditItemRule(String id) =>
      appRouter.push(AppRoutes.editItemRule(id));

  void openItemComparer() => appRouter.push(AppRoutes.itemComparer);

  void openBestLine() => appRouter.push(AppRoutes.bestLine);

  // 设置
  void openUserManagement() {
    if (currentBranchRoot == AppRoutes.settings || !isDesktopPlatform()) {
      appRouter.push(AppRoutes.users);
    } else {
      appRouter.go(AppRoutes.users);
    }
  }

  void openBackup() => appRouter.push(AppRoutes.backup);

  void openAbout() => appRouter.push(AppRoutes.about);
}
