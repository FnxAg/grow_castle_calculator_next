import 'package:grow_castle_calculator_next/utils/date.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/models.dart';

/// 路由路径构造与解析
abstract final class AppRoutes {
  static const home = '/home';
  static const function = '/function';
  static const guild = '/guild';
  static const tools = '/tools';
  static const settings = '/settings';

  static const branchRoots = [home, function, guild, tools, settings];

  // 功能
  static const buildCalc = '$function/build-calc';
  static const waveStatus = '$function/wave-status';
  static const bonusGold = '$function/bonus-gold';
  static const income = '$function/income';
  static const incomeTrend = '$function/income-trend';
  static const gameTrack = '$function/game-track';
  static const gameTrackChart = '$gameTrack/chart';

  // 工具
  static const rankingRoot = '$tools/rank';
  static String ranking(RankingKind kind) => '$rankingRoot/${kind.name}';
  static String rankingChart(RankingKind kind, {DateTime? date}) =>
      _withDate('${ranking(kind)}/chart', date);
  static const search = '$tools/search';
  static String player(String branchRoot, String name) =>
      '$branchRoot/player/${Uri.encodeComponent(name)}';
  static String guildDetail(String name, {DateTime? date}) =>
      _withDate('$tools/guild/${Uri.encodeComponent(name)}', date);
  static const quickCalc = '$tools/quick-calc';
  static const dragonSimulator = '$tools/dragon-simulator';
  static const itemRules = '$dragonSimulator/rules';
  static const newItemRule = '$itemRules/new';
  static String editItemRule(String id) =>
      '$itemRules/edit/${Uri.encodeComponent(id)}';
  static const itemComparer = '$tools/item-comparer';
  static String itemComparerEquip(int index) => '$itemComparer/equip/$index';
  static const bestLine = '$tools/best-line';

  // 设置
  static const users = '$settings/users';
  static const backup = '$settings/backup';
  static const about = '$settings/about';

  static String _withDate(String path, DateTime? date) =>
      date == null ? path : '$path?date=${formatHistoryDate(date)}';

  static DateTime? parseDate(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  /// 当前 location 所属分支根；未知分支回退首页
  static String branchRootOf(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return home;
    final root = '/${segments.first}';
    return branchRoots.contains(root) ? root : home;
  }
}
