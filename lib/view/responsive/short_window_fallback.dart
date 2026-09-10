import 'package:material_ui/material_ui.dart';

/// 矮窗口兜底：可用高度 >= [minHeight] 时**原样返回 [child]**（布局、交互、
/// 滚动位置、固定汇总条全部与改造前一致）；低于阈值时把 child 放进一个高
/// [minHeight] 的滚动容器里 —— 溢出红条变成可滚动。
///
/// 为什么是"固定高度 + 外层滚动"而不是"折行 / 收缩固定区"：这些页面的固定区
/// 里是 Row 与按钮组，没有可压缩的自由度；给一个已知能容纳的高度最省事，
/// 且不改动任何既有布局代码。
///
/// 走兜底分支时的已知代价（只在矮窗口发生）：底部汇总条从"始终可见"变为
/// "滚到底可见"，且内外两层纵向滚动 —— 两者都优于溢出红条。
class ShortWindowFallback extends StatelessWidget {
  const ShortWindowFallback({
    super.key,
    required this.minHeight,
    required this.child,
  });

  /// 页面在正常窗口下需要的最小高度（AppBar + 固定区 + 列表可用余量）
  final double minHeight;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxHeight >= minHeight
          ? child
          : SingleChildScrollView(
              child: SizedBox(height: minHeight, child: child),
            ),
    );
  }
}
