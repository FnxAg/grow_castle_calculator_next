import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 应用级设置（与用户数据无关，全局生效）
class AppSettingsStore {
  static const String _boxName = 'app_meta';
  static const String _themeModeKey = 'themeMode';

  final Box _box;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  AppSettingsStore()
      : _box = Hive.box(_boxName),
        themeModeNotifier = ValueNotifier<ThemeMode>(
          _readThemeMode(Hive.box(_boxName)),
        );

  static ThemeMode _readThemeMode(Box box) {
    final raw = box.get(_themeModeKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return ThemeMode.system;
  }

  /// 设置主题模式并持久化
  void setThemeMode(ThemeMode mode) {
    if (themeModeNotifier.value == mode) {
      return;
    }
    themeModeNotifier.value = mode;
    _box.put(_themeModeKey, mode.name);
  }
}
