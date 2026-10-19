import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/app_sidebar.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';

/// app 根外壳
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _selectIndex = ValueNotifier(0);

  /// 访问过的 tab：首次切到时才建树，之后常驻
  final Set<int> _visited = {0};

  /// 各 tab 首页的 GlobalKey：跨 840 断点时子树形状变化（包/不包内层
  /// Navigator），靠 key 重挂载保住各页 State（输入、滚动位置等）
  final List<GlobalKey> _tabKeys = [
    for (var i = 0; i < mainPages.length; i++) GlobalKey(),
  ];

  /// 各 tab 内层 Navigator 的 key（仅宽屏挂载）：Esc 返回时定位当前 tab 的栈
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    for (var i = 0; i < mainPages.length; i++) GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _selectIndex.dispose();
    super.dispose();
  }

  /// 全局 Esc / Ctrl(⌘)+1..5 处理
  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      // 先关根栈上的弹层（对话框等），再弹当前 tab 的内层栈
      final root = Navigator.of(context);
      if (root.canPop()) {
        root.maybePop();
        return true;
      }
      final nav = context.hasSidebar
          ? _navigatorKeys[_selectIndex.value].currentState
          : null;
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
      return true;
    }
    final modifier =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (modifier) {
      final index = _shortcutIndex(key);
      if (index != null && index < mainPages.length) {
        _selectPage(index);
        return true;
      }
    }
    return false;
  }

  static int? _shortcutIndex(LogicalKeyboardKey key) {
    const keys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ];
    final index = keys.indexOf(key);
    return index == -1 ? null : index;
  }

  /// 切换页面；再次点击当前 tab 回到该 tab 的根页面
  void _selectPage(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectIndex.value == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    _visited.add(index);
    _selectIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Stores.appSettingsStore;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _selectIndex,
        appSettings.sidebarExpandedNotifier,
      ]),
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final mode = width >= Breakpoints.sidebarExpanded
            ? (appSettings.sidebarExpandedNotifier.value
                  ? ShellMode.expanded
                  : ShellMode.rail)
            : width >= Breakpoints.sidebarRail
            ? ShellMode.rail
            : ShellMode.compact;
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mode.hasSidebar) ...[
                AppSidebar(
                  expanded: mode == ShellMode.expanded,
                  selectedIndex: _selectIndex.value,
                  pages: mainPages,
                  onSelected: _selectPage,
                  canToggleExpanded: width >= Breakpoints.sidebarExpanded,
                  onToggleExpanded: () => appSettings.setSidebarExpanded(
                    mode != ShellMode.expanded,
                  ),
                ),
                const VerticalDivider(width: 0.3, thickness: 1),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ShellLayout(
                      mode: mode,
                      contentWidth: constraints.maxWidth,
                      child: _buildPages(mode.hasSidebar),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: mode == ShellMode.compact
              ? _buildBottomBar()
              : null,
        );
      },
    );
  }

  /// 访问过的 tab 常驻，Offstage + TickerMode 负责隐藏/停表
  Widget _buildPages(bool wide) {
    return Stack(
      children: [
        for (var i = 0; i < mainPages.length; i++)
          Positioned.fill(
            key: ValueKey(i),
            child: _visited.contains(i)
                ? Offstage(
                    offstage: i != _selectIndex.value,
                    child: TickerMode(
                      enabled: i == _selectIndex.value,
                      child: _buildTab(i, mainPages[i], wide),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTab(int index, MainPageEntry page, bool wide) {
    final content = KeyedSubtree(
      key: _tabKeys[index],
      child: page.builder(context),
    );
    if (!wide) return content;
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: (_) => content),
    );
  }

  /// 窄屏底部导航
  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: _selectIndex.value,
      height: kBottomNavigationBarHeight * 1.1,
      animationDuration: const Duration(milliseconds: 250),
      onDestinationSelected: _selectPage,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: [
        for (final page in mainPages)
          NavigationDestination(icon: Icon(page.icon), label: page.title(l10n)),
      ],
    );
  }
}
