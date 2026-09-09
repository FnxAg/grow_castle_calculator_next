import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// WebDAV 备份配置存储：与 AppSettingsStore / ItemComparerStore 共用
/// `app_meta` box（先例见 ItemComparerStore），键全部带 `webdav` 前缀。
///
/// `webdav` 前缀同时是数据归档导出时的排除集（DataArchive.appConfigExcludePrefix）：
/// 服务器凭据与备份开关不上传云端，避免跨设备恢复时用 A 设备的服务器配置覆盖 B 设备。
/// 账号密码按需求明文保存。
class WebDavConfigStore {
  static const String boxName = 'app_meta';
  static const String urlKey = 'webdavUrl';
  static const String usernameKey = 'webdavUsername';
  static const String passwordKey = 'webdavPassword';
  static const String autoEnabledKey = 'webdavAutoEnabled';
  static const String intervalHoursKey = 'webdavIntervalHours';
  static const String lastSuccessAtKey = 'webdavLastSuccessAt';
  static const String lastErrorAtKey = 'webdavLastErrorAt';
  static const String lastErrorKey = 'webdavLastError';

  static const int defaultIntervalHours = 24;
  static const int minIntervalHours = 1;
  static const int maxIntervalHours = 720;

  final Box _box;

  final ValueNotifier<String> urlNotifier;
  final ValueNotifier<String> usernameNotifier;
  final ValueNotifier<String> passwordNotifier;
  final ValueNotifier<bool> autoEnabledNotifier;
  final ValueNotifier<int> intervalHoursNotifier;
  /// 上次成功备份时间（epoch ms）；从未成功过为 null
  final ValueNotifier<int?> lastSuccessAtNotifier;
  final ValueNotifier<int?> lastErrorAtNotifier;
  final ValueNotifier<String?> lastErrorNotifier;

  WebDavConfigStore()
      : _box = Hive.box(boxName),
        urlNotifier = ValueNotifier<String>(_readString(Hive.box(boxName), urlKey)),
        usernameNotifier = ValueNotifier<String>(_readString(Hive.box(boxName), usernameKey)),
        passwordNotifier = ValueNotifier<String>(_readString(Hive.box(boxName), passwordKey)),
        autoEnabledNotifier = ValueNotifier<bool>(
          Hive.box(boxName).get(autoEnabledKey) is bool
              ? Hive.box(boxName).get(autoEnabledKey) as bool
              : false,
        ),
        intervalHoursNotifier = ValueNotifier<int>(
          _readIntervalHours(Hive.box(boxName)),
        ),
        lastSuccessAtNotifier = ValueNotifier<int?>(
          _readEpoch(Hive.box(boxName), lastSuccessAtKey),
        ),
        lastErrorAtNotifier = ValueNotifier<int?>(
          _readEpoch(Hive.box(boxName), lastErrorAtKey),
        ),
        lastErrorNotifier = ValueNotifier<String?>(
          Hive.box(boxName).get(lastErrorKey) is String
              ? Hive.box(boxName).get(lastErrorKey) as String
              : null,
        );

  static String _readString(Box box, String key) {
    final raw = box.get(key);
    return raw is String ? raw : '';
  }

  static int _readIntervalHours(Box box) {
    final raw = box.get(intervalHoursKey);
    if (raw is int && raw >= minIntervalHours) {
      return raw.clamp(minIntervalHours, maxIntervalHours);
    }
    return defaultIntervalHours;
  }

  static int? _readEpoch(Box box, String key) {
    final raw = box.get(key);
    return raw is int ? raw : null;
  }

  /// 重新从 box 读取全部配置并刷新各 notifier（恢复/导入后调用；等值不触发通知）
  void reload() {
    urlNotifier.value = _readString(_box, urlKey);
    usernameNotifier.value = _readString(_box, usernameKey);
    passwordNotifier.value = _readString(_box, passwordKey);
    final auto = _box.get(autoEnabledKey);
    autoEnabledNotifier.value = auto is bool ? auto : false;
    intervalHoursNotifier.value = _readIntervalHours(_box);
    lastSuccessAtNotifier.value = _readEpoch(_box, lastSuccessAtKey);
    lastErrorAtNotifier.value = _readEpoch(_box, lastErrorAtKey);
    final error = _box.get(lastErrorKey);
    lastErrorNotifier.value = error is String ? error : null;
  }

  /// 服务器地址是否已配置齐全（可发起备份）
  bool get isConfigured =>
      urlNotifier.value.trim().isNotEmpty &&
      usernameNotifier.value.trim().isNotEmpty &&
      passwordNotifier.value.isNotEmpty;

  /// 距上次成功备份的间隔（小时）；从未成功过返回 null
  DateTime? get lastSuccessAt {
    final ms = lastSuccessAtNotifier.value;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void setUrl(String url) {
    final value = url.trim();
    if (urlNotifier.value == value) return;
    urlNotifier.value = value;
    _box.put(urlKey, value);
  }

  void setUsername(String username) {
    final value = username.trim();
    if (usernameNotifier.value == value) return;
    usernameNotifier.value = value;
    _box.put(usernameKey, value);
  }

  void setPassword(String password) {
    if (passwordNotifier.value == password) return;
    passwordNotifier.value = password;
    _box.put(passwordKey, password);
  }

  void setAutoEnabled(bool enabled) {
    if (autoEnabledNotifier.value == enabled) return;
    autoEnabledNotifier.value = enabled;
    _box.put(autoEnabledKey, enabled);
  }

  void setIntervalHours(int hours) {
    final value = hours.clamp(minIntervalHours, maxIntervalHours);
    if (intervalHoursNotifier.value == value) return;
    intervalHoursNotifier.value = value;
    _box.put(intervalHoursKey, value);
  }

  /// 记录一次成功备份（由 BackupService 调用）：更新时间并清除上次失败信息
  void recordSuccess(DateTime at) {
    final ms = at.millisecondsSinceEpoch;
    lastSuccessAtNotifier.value = ms;
    _box.put(lastSuccessAtKey, ms);
    if (lastErrorNotifier.value != null) {
      lastErrorNotifier.value = null;
      _box.delete(lastErrorAtKey);
      _box.delete(lastErrorKey);
    }
  }

  /// 记录一次失败（由 BackupService 调用，自动备份静默失败可查的出口）
  void recordFailure(DateTime at, String message) {
    final ms = at.millisecondsSinceEpoch;
    lastErrorAtNotifier.value = ms;
    lastErrorNotifier.value = message;
    _box.put(lastErrorAtKey, ms);
    _box.put(lastErrorKey, message);
  }
}
