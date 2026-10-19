import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// 断点
abstract final class Breakpoints {
  /// 底部导航 → 图标侧栏
  static const double sidebarRail = 840.0;

  /// 图标侧栏 → 展开侧栏
  static const double sidebarExpanded = 1200.0;

  static const double railWidth = 80.0;
  static const double expandedWidth = 240.0;

  /// 内容区并排（主从两栏）阈值
  static const double sideBySide = 840.0;

  /// 主从两栏的详情面板宽度
  static double detailPaneWidthFor(double contentWidth) =>
      (contentWidth * 0.36).clamp(360.0, 560.0);
}

/// 外壳形态
enum ShellMode {
  /// 窄屏：底部导航
  compact,

  /// 图标侧栏
  rail,

  /// 展开侧栏（图标 + 文字）
  expanded;

  bool get hasSidebar => this != ShellMode.compact;
}

/// 外壳布局信息：内容区实际宽度与侧栏形态
class ShellLayout extends InheritedWidget {
  const ShellLayout({
    super.key,
    required this.mode,
    required this.contentWidth,
    required super.child,
  });

  final ShellMode mode;
  final double contentWidth;

  bool get isWideContent => contentWidth >= Breakpoints.sideBySide;

  static ShellLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellLayout>();

  @override
  bool updateShouldNotify(ShellLayout oldWidget) =>
      mode != oldWidget.mode || contentWidth != oldWidget.contentWidth;
}

/// 窗口/布局相关读取
extension ResponsiveContext on BuildContext {
  /// 内容区实际宽度；不在 shell 内（对话框等）时退回窗口宽度
  double get contentWidth =>
      ShellLayout.maybeOf(this)?.contentWidth ?? MediaQuery.sizeOf(this).width;

  /// 内容区是否足够并排展示
  bool get isWideContent => contentWidth >= Breakpoints.sideBySide;

  /// 窗口宽度是否达到侧栏形态
  bool get hasSidebar =>
      MediaQuery.sizeOf(this).width >= Breakpoints.sidebarRail;
}

bool isDesktopPlatform([TargetPlatform? platform]) {
  final target = platform ?? defaultTargetPlatform;
  return target == TargetPlatform.windows ||
      target == TargetPlatform.macOS ||
      target == TargetPlatform.linux;
}
