import 'package:flutter/material.dart';

class AnimatedTextSwitcher extends StatelessWidget {
  const AnimatedTextSwitcher({
    super.key,
    required this.child,
    this.alignment = .centerLeft,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: alignment,
        children: [...previousChildren, ?currentChild],
      ),
      child: child,
    );
  }
}
