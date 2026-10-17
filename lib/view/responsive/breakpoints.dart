import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// 断点
abstract final class Breakpoints {
  /// 宽屏起点
  static const double wide = 840.0;

  /// 宽屏时 rail 占掉的宽度
  static const double railWidth = 96.0;

  /// 页面里判断宽屏的 body 阈值
  static const double wideBody = wide - railWidth;

  /// 主从两栏的详情面板宽度
  static double detailPaneWidthFor(double bodyWidth) =>
      (bodyWidth * 0.4).clamp(400.0, double.infinity);
}

bool isDesktopPlatform([TargetPlatform? platform]) {
  final target = platform ?? defaultTargetPlatform;
  return target == TargetPlatform.windows ||
      target == TargetPlatform.macOS ||
      target == TargetPlatform.linux;
}

/// 窗口尺寸读取扩展
extension ResponsiveContext on BuildContext {
  /// 宽屏判定
  bool get isWideScreen => MediaQuery.sizeOf(this).width >= Breakpoints.wide;
}
