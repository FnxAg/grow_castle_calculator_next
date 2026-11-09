import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

class CheckboxCardTile extends StatelessWidget {
  const CheckboxCardTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.selected = false,
    this.dense,
    this.enabled,
    this.tristate = false,
    this.contentPadding,
    this.controlAffinity,
    this.activeColor,
    this.checkColor,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool selected;
  final bool? dense;
  final bool? enabled;
  final bool tristate;
  final EdgeInsetsGeometry? contentPadding;
  final ListTileControlAffinity? controlAffinity;
  final Color? activeColor;
  final Color? checkColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: UIs.cardMargin,
      shape: UIs.cardShape,
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: title,
        subtitle: subtitle,
        secondary: secondary,
        selected: selected,
        dense: dense,
        enabled: enabled,
        tristate: tristate,
        contentPadding: contentPadding,
        controlAffinity: controlAffinity,
        activeColor: activeColor,
        checkColor: checkColor,
      ),
    );
  }
}
