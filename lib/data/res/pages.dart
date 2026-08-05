import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/build_gp_page.dart';
import 'package:grow_castle_calculator_next/view/page/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/income_page.dart';
import 'package:grow_castle_calculator_next/view/tab/setting_tab.dart';
import 'package:grow_castle_calculator_next/view/tab/tools_tab.dart';
import 'package:grow_castle_calculator_next/view/widget/season_indicator.dart';

/// 页面在 AppBar 中声明的操作按钮构建器。
///
/// 页面数据变化通过 store 的 ValueNotifier 驱动 UI 重建，
/// 按钮只需直接调用 store 方法，无需手动刷新。
typedef PageActionsBuilder = List<Widget> Function(BuildContext context);

/// 主界面页面注册表：新增页面只需在此追加一条记录，
/// 外壳（MainShell）会自动生成底部导航项并挂载页面。
class MainPageEntry {
  const MainPageEntry({
    required this.title,
    required this.icon,
    required this.builder,
    this.actionsBuilder,
    this.userPage = false,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// 该页面在 AppBar 中显示的操作按钮；未提供则无
  final PageActionsBuilder? actionsBuilder;

  /// 是否属于当前用户上下文（阵容/收入/公会）：
  /// 此类页面由 UserPageScaffold 挂载，AppBar 带用户名头部与用户管理入口
  final bool userPage;
}

/// 底部导航中按顺序显示的页面
final List<MainPageEntry> mainPages = [
  // 阵容经济计算
  MainPageEntry(
    title: '阵容',
    icon: Icons.calculate,
    userPage: true,
    builder: (_) => const FormationCalcPage(),
    actionsBuilder: (context) => [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '新增条目',
        // 列表重建由 store 的 cardIdsNotifier 驱动
        onPressed: () => Stores.infoStore.addNewCard(),
      ),
    ],
  ),
  // 收入计算
  MainPageEntry(
    title: '收入',
    icon: Icons.trending_up,
    userPage: true,
    builder: (_) => const IncomePage(),
  ),
  // 公会
  MainPageEntry(
    title: '公会',
    icon: Icons.group,
    userPage: true,
    builder: (_) => const GuildPage(),
    // AppBar action 区：公会赛季进度（点击查看详情）
    actionsBuilder: (context) => [
      SeasonIndicator(notifier: RankingCache.guildSeasonNotifier),
    ],
  ),
  // 工具
  MainPageEntry(
    title: '工具',
    icon: Icons.handyman,
    builder: (_) => const ToolsTab(),
  ),
  // 设置
  MainPageEntry(
    title: '设置',
    icon: Icons.settings,
    builder: (_) => const SettingTab(),
  ),
];
