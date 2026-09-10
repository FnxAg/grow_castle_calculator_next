import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';

/// app 根外壳：PageView（阵容/功能/公会/工具/设置）+ 导航。
/// 窄屏沿用底部 NavigationBar，宽屏（>= [Breakpoints.expanded]）改用左侧
/// NavigationRail —— 移动端外观与滑动手势保持不变。
/// 各页面自带独立 Scaffold（用户相关页面内部自包 UserPageScaffold）。
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
  final List<GlobalKey> _tabKeys = [for (var i = 0; i < mainPages.length; i++) GlobalKey()];

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

  /// 全局 Esc 处理：返回上一页/关闭弹层。
  /// 必须消费事件——否则内置的 Esc→DismissIntent 也会触发，弹层会被弹两次。
  /// 语义与内置一致（maybePop 弹最顶路由：对话框/菜单/页面依次适用），
  /// 并额外覆盖了内置不处理的普通页面路由（barrierDismissible=false）。
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

  /// 切换页面：先释放焦点再切页。焦点若仍挂在已被切走的页面上，移动端会
  /// 自动弹出软键盘，且 PageView 会为了显示获焦子页而自动滚回来造成页面抽风
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
          if (isWide) _buildRail(),
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

  /// 单个 tab：宽屏包内层 Navigator（页面内所有 push/showDialog 就近解析到
  /// 它 → 只盖内容区、rail 常驻）；窄屏直接挂页，树上没有内层 Navigator，
  /// 一切照旧解析到根 —— 移动端行为与改造前逐像素一致。
  /// 宽屏已推的子页在缩窄过 840 时随 Navigator 拆除而收起（预期行为）。
  /// 注意：页面 push 的都是自带 builder 的 MaterialPageRoute，不经过
  /// onGenerateRoute（它只构建初始路由），因此 Esc 返回走全局按键处理
  /// （见 _handleKey），而不是挂在某个路由的包装 widget 上。
  Widget _buildTab(int index, MainPageEntry page, bool isWide) {
    final content = KeyedSubtree(
      key: _tabKeys[index],
      child: page.builder(context),
    );
    if (!isWide) return content;
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => content,
      ),
    );
  }

  /// 宽屏侧边导航
  Widget _buildRail() {
    return ListenableBuilder(
      listenable: _selectIndex,
      builder: (context, _) => NavigationRail(
        selectedIndex: _selectIndex.value,
        onDestinationSelected: _selectPage,
        // M3 下默认不显示标签（只剩图标），宽屏有横向余量，常显更易辨认
        labelType: NavigationRailLabelType.all,
        // 矮窗口下 rail 自身可滚动：5 个带标签目的地约 440 逻辑像素，
        // 不给滚动会在 rail 内部溢出
        scrollable: true,
        destinations: [
          for (final page in mainPages)
            NavigationRailDestination(
              icon: Icon(page.icon),
              label: Text(page.title),
            ),
        ],
      ),
    );
  }

  /// 窄屏底部导航（与改造前一致）
  Widget _buildBottomBar() {
    return ListenableBuilder(
      listenable: _selectIndex,
      builder: (context, child) {
        return NavigationBar(
          selectedIndex: _selectIndex.value,
          height: kBottomNavigationBarHeight * 1.1,
          animationDuration: const Duration(milliseconds: 250),
          onDestinationSelected: _selectPage,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            for (final page in mainPages)
              NavigationDestination(icon: Icon(page.icon), label: page.title),
          ],
        );
      },
    );
  }
}

