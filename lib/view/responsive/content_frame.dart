import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';

/// 内容限宽框架：可用宽度不足 [maxWidth] 时铺满（与改造前逐像素一致），
/// 超出时居中留白。
///
/// 不查断点、不用 LayoutBuilder —— 可用宽度更小时 `ConstrainedBox` 天然
/// 不生效，所以"窄屏零变化"是结构性保证，而不是分支判断的结果。
///
/// 用法：只包 `Scaffold` 的 `body`，**不要包整个 Scaffold**（否则 AppBar
/// 会被一起限宽，顶部两侧出现空白带、`scrolledUnder` 变色出现竖向接缝）。
/// [maxWidth] 传 null 表示不限宽，留给下一轮的多栏布局接管该页。
class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    this.maxWidth = Breakpoints.contentMaxWidth,
    required this.child,
  });

  final double? maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth;
    if (width == null) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}
