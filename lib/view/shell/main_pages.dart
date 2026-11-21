import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 主界面页面注册表（顺序须与路由 branches 一致）
class MainPageEntry {
  const MainPageEntry({required this.title, required this.icon});

  final String Function(AppLocalizations l10n) title;
  final IconData icon;
}

final List<MainPageEntry> mainPages = [
  MainPageEntry(title: (l10n) => l10n.tabHome, icon: Icons.home),
  MainPageEntry(title: (l10n) => l10n.tabFunction, icon: Icons.history_edu),
  MainPageEntry(title: (l10n) => l10n.tabGuild, icon: Icons.flag_circle),
  MainPageEntry(title: (l10n) => l10n.tabTools, icon: Icons.handyman),
  MainPageEntry(title: (l10n) => l10n.tabSettings, icon: Icons.settings),
];
