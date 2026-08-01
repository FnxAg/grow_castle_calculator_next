import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class NativeDynamicColorUtil {
  static const MethodChannel _channel = MethodChannel("fnxag.dynamic_color/native");

  /// 获取系统动态ColorScheme
  static Future<ColorScheme?> getDynamicColorScheme(Brightness brightness) async {
    try {
      final int? argb = await _channel.invokeMethod("getSystemWallpaperSeedColor");
      if (argb == null) return null;
      final seedColor = Color(argb);
      return ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      );
    } catch (_) {
      return null;
    }
  }
}