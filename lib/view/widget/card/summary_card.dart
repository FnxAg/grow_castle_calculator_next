import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:material_ui/material_ui.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.children,
    this.onTap,
    this.cardType = CardType.normal,
  });

  final List<Widget> children;
  final VoidCallback? onTap;
  final CardType cardType;

  @override
  Widget build(BuildContext context) {
    return CardX(
      cardType: cardType,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: UIs.inCardPadding,
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    this.leading,
    required this.title,
    this.actions = const [],
    required this.trailing,
  });

  static Widget text(String text) => SummaryRowValueText(text: text);

  final Widget? leading;
  final Widget title;
  final List<Widget> actions;
  final Widget trailing;

  /// 图标大小：20.0
  static const leadingIconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = leading is Icon ? (leading as Icon).icon : null;
    final Widget? leadingWidget = icon == null
        ? leading
        : Icon(
            icon,
            size: SummaryRow.leadingIconSize,
            color: colorScheme.primary,
          );
    return Row(
      children: [
        if (leadingWidget != null) ...[
          leadingWidget,
          const SizedBox(width: 8.0),
        ],
        title,
        const SizedBox(width: 8.0),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 4.0),
          actions[i],
        ],
        const Spacer(),
        trailing,
      ],
    );
  }
}

class SummaryRowValueText extends StatelessWidget {
  const SummaryRowValueText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedTextSwitcher(
      alignment: .centerRight,
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
