import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// 窗口宽度分级（对齐 Material 3 的 WindowSizeClass）。
///
/// 本轮只用到 [expanded] 以上（宽屏外壳）；其余等级是下一轮 2×2 图表与
/// master-detail 的接入点，届时不必再改壳层判定。
enum ScreenSize {
  /// < 600：手机竖屏
  compact,

  /// 600 ~ 840：手机横屏 / 小平板
  medium,

  /// 840 ~ 1200：平板横屏 / 桌面默认窗口
  expanded,

  /// >= 1200：桌面宽窗口
  large;

  static ScreenSize fromWidth(double width) {
    if (width < Breakpoints.medium) return ScreenSize.compact;
    if (width < Breakpoints.expanded) return ScreenSize.medium;
    if (width < Breakpoints.large) return ScreenSize.expanded;
    return ScreenSize.large;
  }

  /// 当前等级是否不低于 [other]
  bool atLeast(ScreenSize other) => index >= other.index;
}

/// 断点与宽度的唯一真源：页面里不要再出现宽度魔法数
abstract final class Breakpoints {
  // ── 窗口分级 ──
  static const double medium = 600.0;

  /// 宽屏外壳（NavigationRail）的起点。取 840 而非 M3 的 600 有两条理由：
  /// 600~840 段的窗口多见于手机横屏，纵向空间比横向更稀缺（底部导航只吃
  /// 一条，rail 要吃掉整条左边）；且 840 正好是 M3 `expanded` 的起点，
  /// 桌面上 1280×720 的默认窗口稳稳落在 rail 侧。
  static const double expanded = 840.0;

  static const double large = 1200.0;

  // ── 主从两栏 ──
  /// 主从两栏的最小**局部**宽度：body 可用宽度低于此值时退回单栏 + push。
  /// 布局内判断必须用 LayoutBuilder 的局部 constraints（而非窗口宽度）
  static const double masterDetailMinWidth = 900.0;

  /// 主从两栏右侧详情面板宽度（余下给左侧列表）
  static const double detailPaneWidth = 460.0;

  // ── 图表网格 ──
  /// 图表 2×2 网格的最小**局部**宽度（两张面板各 ≥310）
  static const double chartGridMinWidth = 640.0;
}

/// 是否为桌面平台（windows/macOS/linux）。
///
/// 用于交互层的平台差异（SelectionArea / 聚焦全选 / hover 显露）。
/// `flutter test` 下 defaultTargetPlatform 恒为 android（SDK 在 FLUTTER_TEST
/// 环境变量存在时强制覆盖），因此桌面分支对现有测试天然不可见。
bool isDesktopPlatform([TargetPlatform? platform]) {
  final target = platform ?? defaultTargetPlatform;
  return target == TargetPlatform.windows ||
      target == TargetPlatform.macOS ||
      target == TargetPlatform.linux;
}

/// 窗口尺寸读取扩展。
///
/// 断点用**窗口宽度**而非局部约束宽度：它回答的是"这是不是一块宽屏幕"，
/// 不该随嵌套深度（rail 旁 / AppBar 内 / 对话框里）变化。需要知道"body 里
/// 还剩多宽"的局部自适应（如主从两栏、图表网格）请用 LayoutBuilder ——
/// 那里 MediaQuery 会把导航栏占掉的宽度也算进来，给出偏大的错答案。
extension ResponsiveContext on BuildContext {
  double get windowWidth => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize => ScreenSize.fromWidth(windowWidth);

  /// 宽屏外壳判定（NavigationRail / NavigationBar 的分支依据）
  bool get isWideScreen => windowWidth >= Breakpoints.expanded;
}
