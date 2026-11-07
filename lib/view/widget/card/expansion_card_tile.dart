import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

class ExpansionCardTile extends StatelessWidget {
  const ExpansionCardTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.controller,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.maintainState = false,
    this.childrenPadding,
    this.children = const <Widget>[],
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final ExpansibleController? controller;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final EdgeInsetsGeometry? tilePadding;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final bool maintainState;
  final EdgeInsetsGeometry? childrenPadding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tileColor = ListTileTheme.of(context).tileColor;
    return Card(
      elevation: 0,
      shape: UIs.cardShape,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        controller: controller,
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: tilePadding,
        expandedCrossAxisAlignment: expandedCrossAxisAlignment,
        maintainState: maintainState,
        childrenPadding: childrenPadding,
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: tileColor,
        collapsedBackgroundColor: tileColor,
        children: children,
      ),
    );
  }
}
