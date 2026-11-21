import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/app_sidebar.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';
import 'package:grow_castle_calculator_next/view/shell/shell_animations.dart';
import 'package:grow_castle_calculator_next/view/shell/shell_transition.dart';
import 'package:material_ui/material_ui.dart';

/// 应用外壳：侧栏/底部栏布局、滑动切 tab、快捷键
class ShellScaffold extends StatefulWidget {
  const ShellScaffold({
    super.key,
    required this.navigationShell,
    required this.location,
  });

  final StatefulNavigationShell navigationShell;

  /// 当前 location（来自 shell builder 的 state.uri）
  final Uri location;

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _switchController;
  late final ShellTransition _transition;

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

  /// 分支根页：pathSegments 只有一段（/home、/function……）
  bool get _isRootLocation => widget.location.pathSegments.length <= 1;

  @override
  void initState() {
    super.initState();
    _switchController = AnimationController(
      vsync: this,
      duration: shellAnimationDuration,
      value: 1.0,
    )..addStatusListener(_onSwitchStatus);
    _transition = ShellTransition(controller: _switchController)
      ..currentIndex = widget.navigationShell.currentIndex;
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _switchController.dispose();
    _transition.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部 go（如首页快捷入口跨分支）不带动画，直接同步索引
    _transition.syncCurrentIndex(widget.navigationShell.currentIndex);
  }

  void _onSwitchStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    switch (_transition.phase) {
      case ShellSwitchPhase.settlingBack:
        _rollback();
      case ShellSwitchPhase.switching:
      case ShellSwitchPhase.settlingForward:
        _finishForward();
      case ShellSwitchPhase.idle:
        break;
    }
  }

  void _finishForward() {
    _transition.finishForward();
    _switchController.value = 1.0;
  }

  /// 回滚到拖动开始时的分支
  void _rollback() {
    final source = _transition.sourceIndex;
    _transition.finishRollback(source);
    _switchController.value = 1.0;
    widget.navigationShell.goBranch(source);
  }

  /// 立即结束进行中的切换/拖动，供新的操作打断
  void _settleImmediately() {
    if (_transition.phase == ShellSwitchPhase.settlingBack) {
      _rollback();
      return;
    }
    if (_transition.isBusy) {
      _finishForward();
    }
  }

  void _animateDragTo(double target, double progress) {
    final total = shellAnimationDuration.inMilliseconds;
    final remaining = (target > progress ? 1 - progress : progress).clamp(
      0.0,
      1.0,
    );
    _switchController.animateTo(
      target,
      duration: Duration(
        milliseconds: (total * remaining).round().clamp(80, total),
      ),
      curve: shellAnimationCurve,
    );
  }

  void _onDragStart(DragStartDetails details) {
    _settleImmediately();
    _transition.beginDrag(
      source: _transition.currentIndex,
      sourceWasRoot: _isRootLocation,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dx = details.primaryDelta ?? 0.0;
    if (dx == 0.0 || _transition.pageWidth <= 0.0) return;

    if (_transition.dragTarget == null) {
      final target = _transition.sourceIndex + (dx < 0 ? 1 : -1);
      if (target < 0 || target >= mainPages.length) return;
      _transition.beginDragTarget(target, dx < 0 ? 1 : -1);
      // 未访问过的分支在此惰性加载，才能作为「新页」参与滑入
      widget.navigationShell.goBranch(target);
    }

    _transition.dragDistance += dx;
    _switchController.value =
        (_transition.dragDistance *
                -_transition.slideDirection /
                _transition.pageWidth)
            .clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    _transition.endDrag();
    final target = _transition.dragTarget;
    if (target == null) return;
    final progress = _switchController.value;
    final velocity = details.primaryVelocity ?? 0.0;
    final committed =
        progress >= 0.25 || velocity * _transition.slideDirection < -300.0;

    if (committed) {
      if (progress >= 1.0) {
        _finishForward();
      } else {
        _transition.setPhase(ShellSwitchPhase.settlingForward);
        _animateDragTo(1.0, progress);
      }
    } else if (progress <= 0.0) {
      _rollback();
    } else {
      _transition.setPhase(ShellSwitchPhase.settlingBack);
      _animateDragTo(0.0, progress);
    }
  }

  void _onDragCancel() {
    _transition.endDrag();
    if (_transition.dragTarget == null) return;
    if (_switchController.value <= 0.0) {
      _rollback();
      return;
    }
    _transition.setPhase(ShellSwitchPhase.settlingBack);
    _animateDragTo(0.0, _switchController.value);
  }

  /// 切换页面；再次点击当前 tab 回到该 tab 的根页面
  void _selectPage(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    _settleImmediately();
    final current = _transition.currentIndex;
    if (current == index) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    _transition.beginSwitch(
      from: current,
      to: index,
      sourceWasRoot: _isRootLocation,
      direction: index > current ? 1 : -1,
    );
    widget.navigationShell.goBranch(index);

    if (MediaQuery.disableAnimationsOf(context)) {
      _finishForward();
    } else {
      _switchController
        ..value = 0.0
        ..animateTo(
          1.0,
          duration: shellAnimationDuration,
          curve: shellAnimationCurve,
        );
    }
  }

  /// 全局 Esc / Ctrl(⌘)+1..5 处理
  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
        return true;
      }
      return false;
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

  @override
  Widget build(BuildContext context) {
    final appSettings = Stores.appSettingsStore;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _transition,
        appSettings.sidebarExpandedNotifier,
      ]),
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final desktop = isDesktopPlatform();
        final mode = width >= Breakpoints.sidebarExpanded
            ? (appSettings.sidebarExpandedNotifier.value
                  ? ShellMode.expanded
                  : ShellMode.rail)
            : desktop || width >= Breakpoints.sidebarRail
            ? ShellMode.rail
            : ShellMode.compact;
        final showBottomBar =
            mode == ShellMode.compact &&
            (_transition.isBusy ? _transition.sourceWasRoot : _isRootLocation);
        // 拖动会话内保持 recognizer 存活；窄屏只在分支根页允许滑动
        final swipeEnabled =
            mode.hasSidebar ||
            _transition.dragging ||
            _transition.dragTarget != null ||
            _isRootLocation;

        return Scaffold(
          // 宽屏没有底部栏时 body 不会自动避让系统导航栏；compact 下由底栏处理
          body: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mode.hasSidebar) ...[
                  AppSidebar(
                    expanded: mode == ShellMode.expanded,
                    selectedIndex: _transition.displayIndex,
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
                  // 固定在 Row 末尾，侧栏出现/消失时复用同一子树（分支栈不重建）
                  key: const ValueKey('shell_content'),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _transition.pageWidth = constraints.maxWidth;
                      return ShellLayout(
                        mode: mode,
                        contentWidth: constraints.maxWidth,
                        child: ShellTransitionScope(
                          transition: _transition,
                          child: RawGestureDetector(
                            gestures: swipeEnabled
                                ? _buildGestures(constraints.maxWidth)
                                : const <Type, GestureRecognizerFactory>{},
                            child: widget.navigationShell,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: showBottomBar ? _buildBottomBar() : null,
        );
      },
    );
  }

  Map<Type, GestureRecognizerFactory> _buildGestures(double width) {
    // 宽屏鼠标拖拽留给文本选择；窄屏鼠标也可滑动
    final devices = width < Breakpoints.sidebarRail
        ? _swipeDevicesWithMouse
        : _swipeDevices;
    return <Type, GestureRecognizerFactory>{
      HorizontalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
            HorizontalDragGestureRecognizer.new,
            (recognizer) {
              recognizer
                ..supportedDevices = devices
                ..onStart = _onDragStart
                ..onUpdate = _onDragUpdate
                ..onEnd = _onDragEnd
                ..onCancel = _onDragCancel;
            },
          ),
    };
  }

  /// 窄屏底部导航
  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: _transition.displayIndex,
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
