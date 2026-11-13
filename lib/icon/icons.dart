import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/icon/icon_half.dart';

import 'box.dart';
import 'crystal.dart';
import 'icon.dart';

export 'box.dart';
export 'crystal.dart';
export 'icon.dart';
export 'icon_half.dart';

/// Unified access to the application's SVG icons.
abstract final class AppIcons {
  static Widget icon({Key? key, double size = 24.0, Color? color}) {
    return AppIcon(key: key, size: size, color: color);
  }

  static Widget icon_half({Key? key, double size = 24.0, Color? color}) {
    return AppIconHalf(key: key, size: size, color: color);
  }

  static Widget box({Key? key, double size = 24.0, Color? color}) {
    return BoxIcon(key: key, size: size, color: color);
  }

  static Widget crystal({Key? key, double size = 24.0, Color? color}) {
    return CrystalIcon(key: key, size: size, color: color);
  }
}
