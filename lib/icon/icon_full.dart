import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';

class AppIconFull extends StatelessWidget {
  const AppIconFull({super.key, this.size = 24.0, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/icon_full.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}