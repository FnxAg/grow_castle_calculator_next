import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';

/// app 根外壳
///
/// 窄屏沿用底部 NavigationBar，宽屏（>= [Breakpoints.expanded]）改用左侧。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _selectIndex = ValueNotifier(0);
  final PageController _pageController = PageController();

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
    _pageController.dispose();
    super.dispose();
  }

  /// 全局 Esc 处理，返回上一页/关闭弹层
  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (context.isWideScreen) {
      // 宽屏：只弹当前 tab 的内层栈（根上只有主壳，不冒泡）
      final nav = _navigatorKeys[_selectIndex.value].currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    } else {
      // 窄屏：无内层 Navigator，弹根栈（与改造前一致）
      Navigator.of(context).maybePop();
    }
    return true;
  }

  /// 切换页面时先收起键盘焦点再切换页面
  void _selectPage(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    _selectIndex.value = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWideScreen;
    return Scaffold(
      // 窄屏时 Row 只有一个 Expanded 子级，布局与改造前等价，代码只有一份
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWide) ...[_buildRail(), const VerticalDivider(width: 0.3, thickness: 1)],
          Expanded(child: _buildPages()),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildBottomBar(),
    );
  }

  Widget _buildPages() {
    final isWide = context.isWideScreen;
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        // 滑动切页时同步高亮（点击切页的高亮已在 _selectPage 里设置）
        _selectIndex.value = index;
        FocusManager.instance.primaryFocus?.unfocus();
      },
      // 相邻页保活：保留各页输入状态，并支持左右滑动切换
      allowImplicitScrolling: true,
      children: [
        for (final (i, page) in mainPages.indexed) _buildTab(i, page, isWide),
      ],
    );
  }

  Widget _buildTab(int index, MainPageEntry page, bool isWide) {
    final content = KeyedSubtree(
      key: _tabKeys[index],
      child: page.builder(context),
    );
    if (!isWide) return content;
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: (_) => content),
    );
  }

  /// 宽屏侧边导航
  Widget _buildRail() {
    return ListenableBuilder(
      listenable: _selectIndex,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        return NavigationRail(
          selectedIndex: _selectIndex.value,
          onDestinationSelected: _selectPage,
          labelType: NavigationRailLabelType.selected,
          scrollable: true,
          destinations: [
            for (final page in mainPages)
              NavigationRailDestination(
                icon: Icon(page.icon),
                label: Text(page.title(l10n)),
              ),
          ],
        );
      },
    );
  }

  /// 长屏底部导航栏
  Widget _buildBottomBar() {
    return ListenableBuilder(
      listenable: _selectIndex,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context);
        return NavigationBar(
          selectedIndex: _selectIndex.value,
          height: kBottomNavigationBarHeight * 1.1,
          animationDuration: const Duration(milliseconds: 250),
          onDestinationSelected: _selectPage,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            for (final page in mainPages)
              NavigationDestination(
                icon: Icon(page.icon),
                label: page.title(l10n),
              ),
          ],
        );
      },
    );
  }
}
