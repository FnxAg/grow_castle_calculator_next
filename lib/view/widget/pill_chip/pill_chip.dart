import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:material_ui/material_ui.dart';

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.text,
    this.textStyle,
    this.textAlignment = AlignmentGeometry.centerLeft,
    this.leading,
    this.backgroundColor,
  });

  final String text;
  final TextStyle? textStyle;
  final AlignmentGeometry textAlignment;
  final Widget? leading;
  final Color? backgroundColor;

  /// 前置图标大小
  static const leadingIconSize = 12.0;
  final double _fontSize = 11.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg = backgroundColor ?? scheme.primaryContainer;

    final defaultTextStyle = TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.w600,
      color: scheme.primary,
    );
    final icon = leading is Icon ? (leading as Icon).icon : null;
    final Widget? leadingWidget = icon == null
        ? leading
        : Icon(
            icon,
            size: leadingIconSize,
            color:
                (leading as Icon).color ??
                (backgroundColor != null ? Colors.white : scheme.primary),
          );
    final pillChipTextStyle = DefaultTextStyle.of(context).style.copyWith(
      fontSize: textStyle?.fontSize ?? defaultTextStyle.fontSize,
      fontWeight: textStyle?.fontWeight ?? defaultTextStyle.fontWeight,
      color:
          textStyle?.color ??
          (backgroundColor != null
              ? Colors.white
              : textStyle?.color ?? defaultTextStyle.color),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            SizedBox(width: _fontSize * 0.36),
          ],
          AnimatedTextSwitcher(
            alignment: textAlignment,
            child: Text(
              text,
              style: pillChipTextStyle,
              key: ValueKey(text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
