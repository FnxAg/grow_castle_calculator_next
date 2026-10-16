import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// 断点与宽度的唯一真源：页面里不要再出现宽度魔法数。
///
/// 全 app 只有**一个**宽度断点：窗口过 [Breakpoints.wide]，外壳换 rail、
/// 页面换多栏，都在窗口 840 这一处同时发生，拖窗口只看到一次布局切换。
abstract final class Breakpoints {
  /// 宽屏起点（窗口宽度）。取 840 而非 M3 的 600 有两条理由：600~840 段的
  /// 窗口多见于手机横屏，纵向空间比横向更稀缺（底部导航只吃一条，rail 要
  /// 吃掉整条左边）；且 840 正好是 M3 `expanded` 的起点。
  static const double wide = 840.0;

  /// 宽屏时 rail 占掉的宽度：M3 rail 固定 80，余量留给被文本缩放撑宽的标签
  /// （rail 宽度 = max(80, 最长标签宽 + 16)，没有上限）
  static const double railWidth = 96.0;

  /// 页面里判断宽屏的 body 阈值：留了余量，窗口正好 840（body = 744）仍算
  /// 宽屏，与外壳同一处翻转，不会出现"已是 rail 但页面还是单栏"。判断必须
  /// 用 LayoutBuilder 的局部 constraints —— MediaQuery 会把 rail 也算进来。
  static const double wideBody = wide - railWidth;

  /// 主从两栏的详情面板宽度：body 的 40%，夹在 340~460。
  /// body ≥ 1150（1280 桌面默认窗口）时是 460，与固定宽度时的观感一致。
  static double detailPaneWidthFor(double bodyWidth) =>
      (bodyWidth * 0.4).clamp(340.0, 460.0);
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

/// 窗口尺寸读取扩展
extension ResponsiveContext on BuildContext {
  /// 宽屏判定（rail ↔ 底部导航、6:4 侧栏的分支依据）
  bool get isWideScreen => MediaQuery.sizeOf(this).width >= Breakpoints.wide;
}
