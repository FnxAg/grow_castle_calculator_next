import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

enum CardType { normal, floating }

enum CardShape { normal, highlight }

class CardX extends StatelessWidget {
  const CardX({
    super.key,
    required this.child,
    this.cardShape = CardShape.normal,
    this.cardType = CardType.normal,
    this.margin = UIs.cardMargin,
  });

  final Widget child;
  final CardShape cardShape;
  final CardType cardType;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: switch (cardType) {
        CardType.floating => 1.0,
        CardType.normal => 0.0,
      },
      color: switch (cardType) {
        CardType.floating => null,
        CardType.normal => ListTileTheme.of(context).tileColor,
      },
      shape: switch (cardShape) {
        CardShape.normal => UIs.cardShape,
        CardShape.highlight => UIs.cardShape.copyWith(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
        ),
      },
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
