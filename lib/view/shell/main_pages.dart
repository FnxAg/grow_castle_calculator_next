import 'package:grow_castle_calculator_next/view/page/home/home_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/page/guild/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/function/function_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting/setting_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool/tools_page.dart';

/// 主界面页面注册表
class MainPageEntry {
  const MainPageEntry({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String Function(AppLocalizations l10n) title;
  final IconData icon;
  final WidgetBuilder builder;
}

final List<MainPageEntry> mainPages = [
  MainPageEntry(
    title: (l10n) => l10n.tabHome,
    icon: Icons.home,
    builder: (_) => const HomePage(),
  ),
  MainPageEntry(
    title: (l10n) => l10n.tabFunction,
    icon: Icons.history_edu,
    builder: (_) => const FunctionPage(),
  ),
  MainPageEntry(
    title: (l10n) => l10n.tabGuild,
    icon: Icons.flag_circle,
    builder: (_) => const GuildPage(),
  ),
  MainPageEntry(
    title: (l10n) => l10n.tabTools,
    icon: Icons.handyman,
    builder: (_) => const ToolsPage(),
  ),
  MainPageEntry(
    title: (l10n) => l10n.tabSettings,
    icon: Icons.settings,
    builder: (_) => const SettingPage(),
  ),
];
