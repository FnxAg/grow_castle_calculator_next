import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/app_sidebar.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';
import 'package:grow_castle_calculator_next/view/shell/shell_animations.dart';

/// app 根外壳
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final _selectIndex = ValueNotifier(0);

  /// 访问过的 tab：首次切到时才建树，之后常驻
  final Set<int> _visited = {0};

  /// 切换过渡：旧页滑出、新页滑入
  late final AnimationController _switchController;
  int _outgoingIndex = 0;
  bool _switching = false;
  int _slideDirection = 1;

  /// 拖动中：目标页与内容区宽度
  int? _dragTarget;
  bool _dragging = false;
  bool _dragCommitting = false;
  double _dragDistance = 0.0;
  double _pageWidth = 0.0;

  /// 滑动切 tab 默认只接受触摸/触控笔
  static const Set<PointerDeviceKind> _swipeDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
  };

  /// 窄屏允许鼠标拖拽切 tab（宽屏鼠标留给文本选择）
  static const Set<PointerDeviceKind> _swipeDevicesWithMouse = {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.mouse,
  };

  /// 各 tab 首页的 GlobalKey：保证页面内容在外壳形态变化时保持同一身份
  /// （输入、滚动位置等状态不因重新布局丢失）
  final List<GlobalKey> _tabKeys = [
    for (var i = 0; i < mainPages.length; i++) GlobalKey(),
  ];

  /// 各 tab 内层 Navigator 的 key：定位当前 tab 的导航栈
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    for (var i = 0; i < mainPages.length; i++) GlobalKey<NavigatorState>(),
  ];

  late final List<_TabNavigatorObserver> _navigatorObservers;
  bool _routeChangeScheduled = false;

  @override
  void initState() {
    super.initState();
    _navigatorObservers = [
      for (var i = 0; i < mainPages.length; i++)
        _TabNavigatorObserver(() => _onTabRouteChanged(i)),
    ];
    _switchController = AnimationController(
      vsync: this,
      duration: shellAnimationDuration,
      value: 1.0,
    )..addStatusListener(_onSwitchStatus);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _switchController.dispose();
    _selectIndex.dispose();
    super.dispose();
  }

  void _onSwitchStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // animateTo 无论方向都以 completed 结束，用 _dragCommitting 区分提交/回弹
    if (_dragTarget != null && !_dragging) {
      if (_dragCommitting) {
        _commitDrag();
      } else {
        setState(() => _dragTarget = null);
      }
    } else if (_switching) {
      setState(() => _switching = false);
    }
  }

  /// 拖动开始：若正有切换动画，先就地结束
  void _onDragStart(DragStartDetails details) {
    _settleImmediately();
    _dragging = true;
    _dragDistance = 0.0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dx = details.primaryDelta ?? 0.0;
    if (dx == 0.0 || _pageWidth <= 0.0) return;
    final current = _selectIndex.value;
    if (_dragTarget == null) {
      final target = dx < 0 ? current + 1 : current - 1;
      if (target < 0 || target >= mainPages.length) return;
      _dragTarget = target;
      _slideDirection = dx < 0 ? 1 : -1;
      _visited.add(target);
    }
    _dragDistance += dx;
    // 反向拖动时进度退回，但不切换到另一侧
    final progress = (_dragDistance * -_slideDirection / _pageWidth).clamp(
      0.0,
      1.0,
    );
    _switchController.value = progress;
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final target = _dragTarget;
    if (target == null) return;
    final progress = _switchController.value;
    final velocity = details.primaryVelocity ?? 0.0;
    final committed = progress >= 0.25 || velocity * _slideDirection < -300.0;
    _dragCommitting = committed;
    final total = shellAnimationDuration.inMilliseconds;
    if (committed) {
      if (progress >= 1.0) {
        _commitDrag();
      } else {
        _animateDragTo(1.0, duration: (total * (1 - progress)).round());
      }
    } else if (progress <= 0.0) {
      setState(() => _dragTarget = null);
    } else {
      _animateDragTo(0.0, duration: (total * progress).round());
    }
  }

  void _onDragCancel() {
    _dragging = false;
    _dragCommitting = false;
    if (_dragTarget == null) return;
    final progress = _switchController.value;
    if (progress <= 0.0) {
      setState(() => _dragTarget = null);
      return;
    }
    _animateDragTo(
      0.0,
      duration: (shellAnimationDuration.inMilliseconds * progress).round(),
    );
  }

  void _animateDragTo(double target, {required int duration}) {
    _switchController.animateTo(
      target,
      duration: Duration(
        milliseconds: duration.clamp(80, shellAnimationDuration.inMilliseconds),
      ),
      curve: shellAnimationCurve,
    );
  }

  void _commitDrag() {
    final target = _dragTarget;
    if (target == null) return;
    setState(() {
      _selectIndex.value = target;
      _dragTarget = null;
      _dragCommitting = false;
      _switching = false;
    });
    _switchController.value = 1.0;
  }

  /// 立即结束进行中的切换/拖动，供新的切换操作打断
  void _settleImmediately() {
    _dragging = false;
    if (_dragTarget == null && !_switching) return;
    _switchController.stop();
    if (_dragTarget != null && _switchController.value >= 0.5) {
      _selectIndex.value = _dragTarget!;
    }
    _dragTarget = null;
    _dragCommitting = false;
    _switching = false;
    _switchController.value = 1.0;
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
      final nav = _navigatorKeys[_selectIndex.value].currentState;
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
    _settleImmediately();
    if (_selectIndex.value == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    _visited.add(index);
    _outgoingIndex = _selectIndex.value;
    _slideDirection = index > _outgoingIndex ? 1 : -1;
    _selectIndex.value = index;
    _switching = !MediaQuery.disableAnimationsOf(context);
    if (_switching) {
      _switchController
        ..value = 0.0
        ..animateTo(
          1.0,
          duration: shellAnimationDuration,
          curve: shellAnimationCurve,
        );
    } else {
      _switchController.value = 1.0;
    }
  }

  void _onTabRouteChanged(int index) {
    if (_routeChangeScheduled) return;
    _routeChangeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeChangeScheduled = false;
      if (!mounted || index != _selectIndex.value) return;
      setState(() {});
    });
  }

  bool _shouldShowBottomBar(ShellMode mode) {
    if (mode != ShellMode.compact) return false;
    return !(_navigatorKeys[_selectIndex.value].currentState?.canPop() ?? false);
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
                      child: _buildPages(constraints.maxWidth),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: _shouldShowBottomBar(mode)
              ? _buildBottomBar()
              : null,
        );
      },
    );
  }

  /// 访问过的 tab 常驻；切换时旧页滑出、新页滑入
  Widget _buildPages(double width) {
    _pageWidth = width;
    final pages = ClipRect(
      child: AnimatedBuilder(
        animation: _switchController,
        builder: (context, _) {
          final t = _switchController.value;
          final shift = _slideDirection * width;
          // 拖动时目标页是「新页」，当前页是「旧页」
          final incoming =
              _dragTarget ?? (_switching ? _selectIndex.value : null);
          final outgoing = _dragTarget != null
              ? _selectIndex.value
              : (_switching ? _outgoingIndex : null);
          return Stack(
            children: [
              for (var i = 0; i < mainPages.length; i++)
                if (_visited.contains(i))
                  Positioned.fill(
                    key: ValueKey(i),
                    child: Offstage(
                      offstage:
                          i != _selectIndex.value &&
                          i != incoming &&
                          i != outgoing,
                      child: IgnorePointer(
                        ignoring: i != _selectIndex.value && i != incoming,
                        child: TickerMode(
                          enabled: i == _selectIndex.value || i == incoming,
                          child: Opacity(
                            opacity: i == incoming
                                ? t
                                : i == outgoing
                                ? 1.0 - t
                                : 1.0,
                            child: Transform.translate(
                              offset: Offset(
                                i == incoming
                                    ? (1 - t) * shift
                                    : i == outgoing
                                    ? -t * shift
                                    : 0.0,
                                0,
                              ),
                              child: _buildTab(i, mainPages[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
    // 宽屏只认触摸/触控笔，鼠标拖拽留给文本选择；窄屏鼠标也可滑动
    final devices = width < Breakpoints.sidebarRail
        ? _swipeDevicesWithMouse
        : _swipeDevices;
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(HorizontalDragGestureRecognizer.new, (recognizer) {
              recognizer
                ..supportedDevices = devices
                ..onStart = _onDragStart
                ..onUpdate = _onDragUpdate
                ..onEnd = _onDragEnd
                ..onCancel = _onDragCancel;
            }),
      },
      child: pages,
    );
  }

  /// 每个 tab 始终保留自己的 Navigator。
  ///
  /// 如果只在宽屏创建 Navigator，窗口跨过侧栏断点时会把页面从普通
  /// 子树切换成全新的 Navigator 子树，当前子页面和路由栈都会丢失。
  Widget _buildTab(int index, MainPageEntry page) {
    final content = KeyedSubtree(
      key: _tabKeys[index],
      child: page.builder(context),
    );
    return Navigator(
      key: _navigatorKeys[index],
      observers: [_navigatorObservers[index]],
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
      animationDuration: shellAnimationDuration,
      onDestinationSelected: _selectPage,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: [
        for (final page in mainPages)
          NavigationDestination(icon: Icon(page.icon), label: page.title(l10n)),
      ],
    );
  }
}

class _TabNavigatorObserver extends NavigatorObserver {
  _TabNavigatorObserver(this.onRouteChanged);

  final VoidCallback onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged();
  }
}
