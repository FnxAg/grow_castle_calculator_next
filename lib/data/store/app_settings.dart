import 'package:material_ui/material_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 应用级设置（与用户数据无关，全局生效）
class AppSettingsStore {
  static const String _boxName = 'app_meta';
  static const String _themeModeKey = 'themeMode';
  static const String _apiUrlKey = 'apiUrl';
  static const String _thirdPartyApiEnabledKey = 'thirdPartyApiEnabled';

  /// 第三方 API 默认地址（正式接口部署前的占位地址）
  static const String defaultApiUrl = 'https://fnxag.eu.org/gcapi';

  final Box _box;
  final ValueNotifier<ThemeMode> themeModeNotifier;
  final ValueNotifier<String> apiUrlNotifier;
  final ValueNotifier<bool> thirdPartyApiEnabledNotifier;

  AppSettingsStore()
      : _box = Hive.box(_boxName),
        themeModeNotifier = ValueNotifier<ThemeMode>(
          _readThemeMode(Hive.box(_boxName)),
        ),
        apiUrlNotifier = ValueNotifier<String>(
          _readApiUrl(Hive.box(_boxName)),
        ),
        thirdPartyApiEnabledNotifier = ValueNotifier<bool>(
          _readThirdPartyApiEnabled(Hive.box(_boxName)),
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

  static String _readApiUrl(Box box) {
    final raw = box.get(_apiUrlKey);
    if (raw is String && raw.trim().isNotEmpty) {
      return raw;
    }
    return defaultApiUrl;
  }

  /// 读取第三方 API 开关状态；未设置过时默认开启（保持原有行为）
  static bool _readThirdPartyApiEnabled(Box box) {
    final raw = box.get(_thirdPartyApiEnabledKey);
    return raw is bool ? raw : true;
  }

  /// 设置第三方 API 开关状态并持久化
  void setThirdPartyApiEnabled(bool enabled) {
    if (thirdPartyApiEnabledNotifier.value == enabled) {
      return;
    }
    thirdPartyApiEnabledNotifier.value = enabled;
    _box.put(_thirdPartyApiEnabledKey, enabled);
  }

  /// 设置第三方 API 地址并持久化；输入为空时回退到默认地址
  void setApiUrl(String url) {
    final value = url.trim().isEmpty ? defaultApiUrl : url.trim();
    if (apiUrlNotifier.value == value) {
      return;
    }
    apiUrlNotifier.value = value;
    _box.put(_apiUrlKey, value);
  }
}
