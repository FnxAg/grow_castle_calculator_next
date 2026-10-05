import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/page/formation_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting_page.dart';
import 'package:grow_castle_calculator_next/view/page/tools_page.dart';

/// 主界面页面注册表：新增页面只需在此追加一条记录，
/// 外壳（MainShell）会自动生成底部导航项并挂载页面。
/// 各页面自带独立 Scaffold 与 AppBar（标题下方用 AppBarInfo 拼当前用户信息）。
class MainPageEntry {
  const MainPageEntry({
    required this.title,
    required this.icon,
    required this.builder,
  });

  /// tab 名。注册表是顶层 final，拿不到 context，所以存成取词条的函数，
  /// 由消费端（MainShell）传入当前语言的 AppLocalizations
  final String Function(AppLocalizations l10n) title;
  final IconData icon;
  final WidgetBuilder builder;
}

/// 底部导航中按顺序显示的页面
final List<MainPageEntry> mainPages = [
  // 阵容经济计算
  MainPageEntry(
    title: (l10n) => l10n.tabFormation,
    icon: Icons.castle,
    builder: (_) => const FormationCalcPage(),
  ),
  // 用户功能
  MainPageEntry(
    title: (l10n) => l10n.tabFunction,
    icon: Icons.history_edu,
    builder: (_) => const FunctionPage(),
  ),
  // 公会
  MainPageEntry(
    title: (l10n) => l10n.tabGuild,
    icon: Icons.flag_circle,
    builder: (_) => const GuildPage(),
  ),
  // 工具
  MainPageEntry(
    title: (l10n) => l10n.tabTools,
    icon: Icons.handyman,
    builder: (_) => const ToolsPage(),
  ),
  // 设置
  MainPageEntry(
    title: (l10n) => l10n.tabSettings,
    icon: Icons.settings,
    builder: (_) => const SettingPage(),
  ),
];
