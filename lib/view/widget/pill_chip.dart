import 'package:flutter/material.dart';

/// 通用胶囊徽标：主题色圆角胶囊 + 可选前置图标 + 文本内容。
///
/// - [text]：内容文本（[Text] 类型，样式由调用方控制）；未显式指定颜色时
///   使用胶囊前景色；胶囊的内边距与图标大小以文本实际字号为基准自适应缩放；
/// - [icon]：前置图标，不传则不显示；
/// - [backgroundColor]：背景色，默认使用主题 [ColorScheme.primaryContainer]；
///   自定义背景色时前景自动按背景亮度取黑白，保证对比度；
/// - [foreground]：强制指定前景色（图标 + 文本兜底），优先于亮度自动判断，
///   用于红/绿等自定义底色上保证对比度。
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.foreground,
  });

  final Text text;
  final IconData? icon;
  final Color? backgroundColor;

  /// 前景色（图标 + 文本兜底）；未指定时按背景亮度自动取黑白
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg = backgroundColor ?? scheme.primaryContainer;
    final Color fg = foreground ??
        (backgroundColor == null
            ? scheme.onPrimaryContainer
            : ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                ? Colors.white
                : Colors.black87);

    // 以文本实际字号为基准：内边距、图标大小、间距随内容自适应缩放
    final double fontSize =
        DefaultTextStyle.of(context).style.merge(text.style).fontSize ?? 14.0;

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
          if (icon != null) Icon(icon, size: fontSize * 1.1, color: fg),
          if (icon != null) SizedBox(width: fontSize * 0.36),
          // 前景色作为兜底：调用方 Text 显式指定颜色时优先使用
          DefaultTextStyle(
            style: TextStyle(color: fg),
            child: text,
          ),
        ],
      ),
    );
  }
}
