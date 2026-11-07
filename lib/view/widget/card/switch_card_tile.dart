import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

class SwitchCardTile extends StatelessWidget {
  const SwitchCardTile({
    super.key,
    this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.selected = false,
    this.contentPadding,
  });

  final Widget? title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool selected;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: UIs.cardShape,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        title: title,
        subtitle: subtitle,
        onChanged: onChanged,
        value: value,
        selected: selected,
        contentPadding: contentPadding,
      ),
    );
  }
}
