import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';

class CrystalIcon extends StatelessWidget {
  const CrystalIcon({super.key, this.size = 24.0, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/crystal.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}