import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

class RadioCardTile<T> extends StatelessWidget {
  const RadioCardTile({
    super.key,
    required this.value,
    this.title,
    this.subtitle,
    this.secondary,
    this.selected = false,
    this.dense,
    this.enabled,
    this.toggleable = false,
    this.contentPadding,
    this.controlAffinity,
    this.activeColor,
  });

  final T value;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool selected;
  final bool? dense;
  final bool? enabled;
  final bool toggleable;
  final EdgeInsetsGeometry? contentPadding;
  final ListTileControlAffinity? controlAffinity;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: UIs.cardMargin,
      shape: UIs.cardShape,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: UIs.cardTileMinHeight),
        child: RadioListTile<T>(
          value: value,
          title: title,
          subtitle: subtitle,
          secondary: secondary,
          selected: selected,
          dense: dense,
          enabled: enabled,
          toggleable: toggleable,
          contentPadding: contentPadding,
          controlAffinity: controlAffinity,
          activeColor: activeColor,
        ),
      ),
    );
  }
}
