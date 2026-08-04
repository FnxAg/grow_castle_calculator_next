import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/build_gp_page.dart';
import 'package:grow_castle_calculator_next/view/page/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/income_page.dart';

/// 页面在 AppBar 中声明的操作按钮构建器。
///
/// 页面数据变化通过 store 的 ValueNotifier 驱动 UI 重建，
/// 按钮只需直接调用 store 方法，无需手动刷新。
typedef PageActionsBuilder = List<Widget> Function(BuildContext context);

/// 抽屉页面注册表：新增页面只需在此追加一条记录，
/// 首页框架（[HomeTab]）会自动在抽屉中列出并支持切换。
class DrawerPageEntry {
  const DrawerPageEntry({
    required this.title,
    required this.icon,
    required this.builder,
    this.actionsBuilder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// 该页面在 AppBar 中显示的操作按钮；未提供则无
  final PageActionsBuilder? actionsBuilder;
}

/// 抽屉中按顺序显示的页面
final List<DrawerPageEntry> drawerPages = [
  // 阵容经济计算 AppBar
  DrawerPageEntry(
    title: '阵容',
    icon: Icons.calculate,
    builder: (_) => FormationCalcPage(),
    actionsBuilder: (context) => [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '新增条目',
        // 列表重建由 store 的 cardIdsNotifier 驱动
        onPressed: () => Stores.infoStore.addNewCard(),
      ),
    ],
  ),
  // 收入计算 AppBar
  DrawerPageEntry(
    title: '收入',
    icon: Icons.trending_up,
    builder: (_) => IncomePage(),
  ),
  DrawerPageEntry(
    title: '公会',
    icon: Icons.group,
    builder: (_) => GuildPage(),
  )
];
