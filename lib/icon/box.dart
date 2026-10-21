import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';

class BoxIcon extends StatelessWidget {
  const BoxIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/box.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}