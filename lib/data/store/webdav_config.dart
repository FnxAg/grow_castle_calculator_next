import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// WebDAV 备份配置存储：与 AppSettingsStore / ItemComparerStore 共用
/// `app_meta` box（先例见 ItemComparerStore），键全部带 `webdav` 前缀。
///
/// `webdav` 前缀同时是数据归档导出时的排除集（DataArchive.appConfigExcludePrefix）：
/// 服务器凭据与备份状态属于本机，不上传云端，避免跨设备恢复时用 A 设备的
/// 服务器配置覆盖 B 设备。账号密码按需求明文保存。
class WebDavConfigStore {
  static const String boxName = 'app_meta';
  static const String urlKey = 'webdavUrl';
  static const String usernameKey = 'webdavUsername';
  static const String passwordKey = 'webdavPassword';
  static const String lastSuccessAtKey = 'webdavLastSuccessAt';
  static const String lastErrorAtKey = 'webdavLastErrorAt';
  static const String lastErrorKey = 'webdavLastError';

  final Box _box;

  final ValueNotifier<String> urlNotifier;
  final ValueNotifier<String> usernameNotifier;
  final ValueNotifier<String> passwordNotifier;
  /// 上次成功备份时间（epoch ms）；从未成功过为 null
  final ValueNotifier<int?> lastSuccessAtNotifier;
  final ValueNotifier<int?> lastErrorAtNotifier;
  final ValueNotifier<String?> lastErrorNotifier;

  WebDavConfigStore()
      : _box = Hive.box(boxName),
        urlNotifier = ValueNotifier<String>(_readString(Hive.box(boxName), urlKey)),
        usernameNotifier = ValueNotifier<String>(_readString(Hive.box(boxName), usernameKey)),
        passwordNotifier = ValueNotifier<String>(_readString(Hive.box(boxName), passwordKey)),
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

  static int? _readEpoch(Box box, String key) {
    final raw = box.get(key);
    return raw is int ? raw : null;
  }

  /// 重新从 box 读取全部配置并刷新各 notifier（恢复/导入后调用；等值不触发通知）
  void reload() {
    urlNotifier.value = _readString(_box, urlKey);
    usernameNotifier.value = _readString(_box, usernameKey);
    passwordNotifier.value = _readString(_box, passwordKey);
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

  void setUrl(String url) {
    final value = url.trim();
    if (urlNotifier.value == value) return;
    urlNotifier.value = value;
    _box.put(urlKey, value);
    // 成功记录是针对某台服务器的：换地址后旧记录会把新服务器上已有的备份
    // 误判为"较旧"而不告警，清掉后判定落 remoteUnknown，会先警告
    clearLastSuccess();
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

  /// 清空上次成功备份记录（换服务器地址时调用）
  void clearLastSuccess() {
    if (lastSuccessAtNotifier.value == null) return;
    lastSuccessAtNotifier.value = null;
    _box.delete(lastSuccessAtKey);
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

  /// 记录一次失败（由 BackupService 调用，作为备份页状态区的留痕）
  void recordFailure(DateTime at, String message) {
    final ms = at.millisecondsSinceEpoch;
    lastErrorAtNotifier.value = ms;
    lastErrorNotifier.value = message;
    _box.put(lastErrorAtKey, ms);
    _box.put(lastErrorKey, message);
  }
}
