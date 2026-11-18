import 'package:grow_castle_calculator_next/view/widget/card/card_x.dart';
import 'package:material_ui/material_ui.dart';

class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.dense,
    this.contentPadding,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool enabled;
  final bool? dense;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return CardX(
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
        selected: selected,
        enabled: enabled,
        dense: dense,
        contentPadding: contentPadding,
        style: ListTileStyle.list,
      ),
    );
  }
}
