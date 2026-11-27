import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/widget/glass_surface.dart';
import 'package:material_ui/material_ui.dart';

enum CardType { normal, floating, glass }

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
    final shape = switch (cardShape) {
      CardShape.normal => UIs.cardShape,
      CardShape.highlight => UIs.cardShape.copyWith(
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.0,
        ),
      ),
    };

    if (cardType == CardType.glass) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: margin,
        child: GlassSurface(
          borderRadius: shape.borderRadius,
          tintColor:
              ListTileTheme.of(context).tileColor ??
              scheme.surfaceContainerHigh,
          borderColor: cardShape == CardShape.highlight ? scheme.primary : null,
          child: child,
        ),
      );
    }

    return Card(
      elevation: cardType == CardType.floating ? 1.0 : 0.0,
      color: switch (cardType) {
        CardType.floating => null,
        CardType.normal => ListTileTheme.of(context).tileColor,
        CardType.glass => Colors.transparent,
      },
      shape: shape,
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
