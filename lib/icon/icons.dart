import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/icon/icon_half.dart';

import 'box.dart';
import 'crystal.dart';
import 'icon_full.dart';

export 'box.dart';
export 'crystal.dart';
export 'icon_full.dart';
export 'icon_half.dart';

/// Unified access to the application's SVG icons.
abstract final class AppIcons {
  static Widget icon_full({Key? key, double size = 24.0, Color? color}) {
    return AppIconFull(key: key, size: size, color: color);
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
