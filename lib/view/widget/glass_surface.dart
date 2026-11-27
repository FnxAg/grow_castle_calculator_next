import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
    this.tintColor,
    this.borderColor,
    this.blurSigma = 18.0,
  });

  final BorderRadiusGeometry borderRadius;
  final Widget child;
  final Color? tintColor;
  final Color? borderColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = tintColor ?? scheme.surfaceContainerHigh;
    final clipRadius = borderRadius.resolve(Directionality.of(context));

    return Material(
      color: Colors.transparent,
      elevation: 10.0,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: clipRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: 0.82),
                  tint.withValues(alpha: 0.70),
                ],
              ),
              border: Border.all(
                color: borderColor ?? scheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
