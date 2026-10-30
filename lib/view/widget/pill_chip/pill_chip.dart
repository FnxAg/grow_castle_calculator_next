import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:material_ui/material_ui.dart';

/// 通用胶囊徽标：主题色圆角胶囊 + 可选前置图标 + 文本内容。
///
/// - [text]：内容文本；未显式指定颜色时使用胶囊前景色；胶囊的内边距与
///   图标大小以文本实际字号为基准自适应缩放；
/// - [textStyle]：文本样式，默认 [defaultTextStyle]；
/// - [leading]：前置图标，不传则不显示；
/// - [backgroundColor]：背景色，默认使用主题 [ColorScheme.primaryContainer]；
///   自定义背景色时前景自动按背景亮度取黑白，保证对比度；
/// - [foreground]：强制指定前景色（图标 + 文本兜底），优先于亮度自动判断，
///   用于红/绿等自定义底色上保证对比度。
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.text,
    this.textStyle = defaultTextStyle,
    this.textAlignment = AlignmentGeometry.centerLeft,
    this.leading,
    this.backgroundColor,
    this.foreground,
  });

  final String text;
  final TextStyle textStyle;
  final AlignmentGeometry textAlignment;
  final Widget? leading;
  final Color? backgroundColor;

  /// 前景色（图标 + 文本兜底）；未指定时按背景亮度自动取黑白
  final Color? foreground;

  /// 前置图标大小：12.0
  static const leadingIconSize = 12.0;

  /// 默认文本样式：字号 11.0，半粗体
  static const defaultTextStyle = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg = backgroundColor ?? scheme.primaryContainer;
    final Color fg =
        foreground ??
        (backgroundColor == null
            ? scheme.onPrimaryContainer
            : ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
            ? Colors.white
            : Colors.black87);

    // 以文本实际字号为基准：内边距、图标大小、间距随内容自适应缩放
    final double fontSize =
        DefaultTextStyle.of(context).style.merge(textStyle).fontSize ?? 14.0;
    final icon = leading is Icon ? (leading as Icon).icon : null;
    final Widget? leadingWidget = icon == null
        ? leading
        : Icon(icon, size: fontSize * 1.1, color: fg);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.72,
        vertical: fontSize * 0.18,
      ),
      decoration: BoxDecoration(
        color: bg,
        // 大圆角形成胶囊形
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            SizedBox(width: fontSize * 0.36),
          ],
          // 前景色作为兜底：[textStyle] 显式指定颜色时优先使用
          DefaultTextStyle(
            style: TextStyle(color: fg),
            child: AnimatedTextSwitcher(
              alignment: textAlignment,
              // 文本值作为 key，内容变化时触发切换动画
              child: Text(text, style: textStyle, key: ValueKey(text)),
            ),
          ),
        ],
      ),
    );
  }
}
