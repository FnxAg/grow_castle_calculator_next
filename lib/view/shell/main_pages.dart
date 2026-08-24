import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/page/formation_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting_page.dart';
import 'package:grow_castle_calculator_next/view/page/tools_page.dart';

/// 主界面页面注册表：新增页面只需在此追加一条记录，
/// 外壳（MainShell）会自动生成底部导航项并挂载页面。
/// 各页面自带独立 Scaffold（用户相关页面自包 UserPageScaffold）。
class MainPageEntry {
  const MainPageEntry({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

/// 底部导航中按顺序显示的页面
final List<MainPageEntry> mainPages = [
  // 阵容经济计算
  MainPageEntry(
    title: '阵容',
    icon: Icons.calculate,
    builder: (_) => const FormationCalcPage(),
  ),
  // 用户功能
  MainPageEntry(
    title: '功能',
    icon: Icons.history_edu,
    builder: (_) => const FunctionPage(),
  ),
  // 公会
  MainPageEntry(
    title: '公会',
    icon: Icons.flag_circle,
    builder: (_) => const GuildPage(),
  ),
  // 工具
  MainPageEntry(
    title: '工具',
    icon: Icons.handyman,
    builder: (_) => const ToolsPage(),
  ),
  // 设置
  MainPageEntry(
    title: '设置',
    icon: Icons.settings,
    builder: (_) => const SettingPage(),
  ),
];
