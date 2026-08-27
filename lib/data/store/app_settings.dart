import 'package:material_ui/material_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 应用级设置（与用户数据无关，全局生效）
class AppSettingsStore {
  static const String _boxName = 'app_meta';
  static const String _themeModeKey = 'themeMode';
  static const String _apiUrlKey = 'apiUrl';
  static const String _thirdPartyApiEnabledKey = 'thirdPartyApiEnabled';
  static const String _autoLastOnlineEnabledKey = 'autoLastOnlineEnabled';
  static const String _lastOnlineConcurrencyKey = 'lastOnlineConcurrency';
  static const String _gameTrackEnabledKey = 'gameTrackEnabled';
  static const String _gameTrackIntervalMinutesKey = 'gameTrackIntervalMinutes';

  /// 第三方 API 默认地址（正式接口部署前的占位地址）
  static const String defaultApiUrl = 'https://fnxag.eu.org/gcapi';

  /// 公会成员"上次在线"默认并发查询数
  static const int defaultLastOnlineConcurrency = 3;
  static const int defaultGameTrackIntervalMinutes = 5;

  final Box _box;
  final ValueNotifier<ThemeMode> themeModeNotifier;
  final ValueNotifier<String> apiUrlNotifier;
  final ValueNotifier<bool> thirdPartyApiEnabledNotifier;

  /// 公会成员"上次在线"自动查询开关
  final ValueNotifier<bool> autoLastOnlineEnabledNotifier;

  /// 公会成员"上次在线"并发查询数（1-10）
  final ValueNotifier<int> lastOnlineConcurrencyNotifier;
  final ValueNotifier<bool> gameTrackEnabledNotifier;
  final ValueNotifier<int> gameTrackIntervalMinutesNotifier;

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
        ),
        autoLastOnlineEnabledNotifier = ValueNotifier<bool>(
          _readAutoLastOnlineEnabled(Hive.box(_boxName)),
        ),
        lastOnlineConcurrencyNotifier = ValueNotifier<int>(
          _readLastOnlineConcurrency(Hive.box(_boxName)),
        ),
        gameTrackEnabledNotifier = ValueNotifier<bool>(
          _readGameTrackEnabled(Hive.box(_boxName)),
        ),
        gameTrackIntervalMinutesNotifier = ValueNotifier<int>(
          _readGameTrackIntervalMinutes(Hive.box(_boxName)),
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

  /// 读取"自动查询上次在线"开关；未设置过时默认开启（保持原有行为）
  static bool _readAutoLastOnlineEnabled(Box box) {
    final raw = box.get(_autoLastOnlineEnabledKey);
    return raw is bool ? raw : true;
  }

  /// 设置"自动查询上次在线"开关并持久化
  void setAutoLastOnlineEnabled(bool enabled) {
    if (autoLastOnlineEnabledNotifier.value == enabled) {
      return;
    }
    autoLastOnlineEnabledNotifier.value = enabled;
    _box.put(_autoLastOnlineEnabledKey, enabled);
  }

  /// 读取"查询并发数"；未设置过或非法值时回退默认值
  static int _readLastOnlineConcurrency(Box box) {
    final raw = box.get(_lastOnlineConcurrencyKey);
    if (raw is int && raw >= 1) {
      return raw.clamp(1, 10);
    }
    return defaultLastOnlineConcurrency;
  }

  /// 设置"查询并发数"并持久化（限制 1-10）
  void setLastOnlineConcurrency(int concurrency) {
    final value = concurrency.clamp(1, 10);
    if (lastOnlineConcurrencyNotifier.value == value) {
      return;
    }
    lastOnlineConcurrencyNotifier.value = value;
    _box.put(_lastOnlineConcurrencyKey, value);
  }

  static bool _readGameTrackEnabled(Box box) {
    final raw = box.get(_gameTrackEnabledKey);
    return raw is bool ? raw : false;
  }

  void setGameTrackEnabled(bool enabled) {
    if (gameTrackEnabledNotifier.value == enabled) return;
    gameTrackEnabledNotifier.value = enabled;
    _box.put(_gameTrackEnabledKey, enabled);
  }

  static int _readGameTrackIntervalMinutes(Box box) {
    final raw = box.get(_gameTrackIntervalMinutesKey);
    if (raw is int && raw >= 1) return raw.clamp(1, 1440);
    return defaultGameTrackIntervalMinutes;
  }

  void setGameTrackIntervalMinutes(int minutes) {
    final value = minutes.clamp(1, 1440);
    if (gameTrackIntervalMinutesNotifier.value == value) return;
    gameTrackIntervalMinutesNotifier.value = value;
    _box.put(_gameTrackIntervalMinutesKey, value);
  }
}
