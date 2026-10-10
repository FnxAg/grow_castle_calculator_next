import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';

typedef WebDavBackupClientFactory = WebDavBackupClient Function({
  required String url,
  required String username,
  required String password,
});

enum RemoteBackupRelation {
  /// 云端还没有备份文件
  noRemote,

  /// 云端明显晚于本机上次成功备份：可能来自其他设备，覆盖有丢失风险
  remoteNewer,

  /// 云端不晚于本机上次成功备份：本机自己的旧档，覆盖安全
  remoteOlder,

  /// 有文件但无法判断：缺修改时间，或本机从无成功备份记录
  remoteUnknown,
}

/// 云端备份预览
class RemoteBackupPreview {
  const RemoteBackupPreview({required this.fileInfo, required this.contents});

  final WebDavFileInfo fileInfo;
  final ArchiveContents contents;
}

/// 恢复失败时的数据分段
enum DataSection { userData, userMeta, appSettings, itemRules, gameTrack }

sealed class BackupFailure {
  const BackupFailure();

  String get id;
}

/// 已有任务在跑
class BackupBusyFailure extends BackupFailure {
  const BackupBusyFailure();
  @override
  String get id => 'busy';
}

/// 未配置 WebDAV 服务器地址/账号/密码
class BackupNotConfiguredFailure extends BackupFailure {
  const BackupNotConfiguredFailure();
  @override
  String get id => 'notConfigured';
}

/// 其它未分类失败
class BackupGenericFailure extends BackupFailure {
  const BackupGenericFailure();
  @override
  String get id => 'failed';
}

/// 归档里没有任何可恢复的数据
class BackupNoDataFailure extends BackupFailure {
  const BackupNoDataFailure();
  @override
  String get id => 'noData';
}

/// 网络/服务器侧失败
class BackupWebDavFailure extends BackupFailure {
  const BackupWebDavFailure(this.statusCode);

  final int statusCode;

  @override
  String get id => 'webdav:$statusCode';
}

/// 归档文件不合法
class BackupArchiveFailure extends BackupFailure {
  const BackupArchiveFailure(this.error);

  final ArchiveError error;

  @override
  String get id => 'archive:${error.name}';
}

/// 部分数据分段恢复失败
class BackupPartialRestoreFailure extends BackupFailure {
  const BackupPartialRestoreFailure(this.sections);

  final List<DataSection> sections;

  @override
  String get id => 'partial:${sections.map((s) => s.name).join(',')}';
}

/// 备份/恢复编排
class BackupService {
  BackupService({WebDavBackupClientFactory? clientFactory, ProviderContainer? container})
      : _clientFactory = clientFactory ?? _defaultClientFactory,
        // ignore: prefer_initializing_formals
        _container = container;

  static WebDavBackupClient _defaultClientFactory({
    required String url,
    required String username,
    required String password,
  }) =>
      WebDavBackupClient(url: url, username: username, password: password);

  /// 跨时钟比较容差
  static const Duration remoteNewerTolerance = Duration(minutes: 5);

  static BackupService get instance {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<BackupService>()) {
      getIt.registerSingleton<BackupService>(BackupService());
    }
    return getIt<BackupService>();
  }

  /// 有备份/恢复任务进行中
  final ValueNotifier<bool> busyNotifier = ValueNotifier<bool>(false);

  /// 数据恢复/导入完成通知
  final ValueNotifier<int> dataRestoredNotifier = ValueNotifier<int>(0);

  final WebDavBackupClientFactory _clientFactory;

  /// 用户数据状态容器的注入点
  final ProviderContainer? _container;

  ProviderContainer get _requireContainer =>
      _container ??
      (throw StateError('BackupService 需要 ProviderContainer：请由 main() 注册'));

  WebDavConfigStore get _config => Stores.webDavConfigStore;

  WebDavBackupClient _createClient() => _clientFactory(
        url: _config.urlNotifier.value,
        username: _config.usernameNotifier.value,
        password: _config.passwordNotifier.value,
      );

  /// 云端与本机记录的新旧判定
  static RemoteBackupRelation compareRemoteBackup({
    required WebDavFileInfo info,
    required int? lastSuccessAtMs,
  }) {
    if (!info.exists) return RemoteBackupRelation.noRemote;
    final remote = info.lastModified;
    if (remote == null || lastSuccessAtMs == null) {
      return RemoteBackupRelation.remoteUnknown;
    }
    final local = DateTime.fromMillisecondsSinceEpoch(lastSuccessAtMs);
    return remote.difference(local) > remoteNewerTolerance
        ? RemoteBackupRelation.remoteNewer
        : RemoteBackupRelation.remoteOlder;
  }

  /// 探测云端备份元信息
  Future<WebDavFileInfo> fetchRemoteInfo() =>
      _createClient().fetchInfo(fileName: kBackupFileName);

  /// 手动备份
  Future<BackupFailure?> manualBackup() async {
    if (busyNotifier.value) {
      return const BackupBusyFailure();
    }
    busyNotifier.value = true;
    BackupFailure? error;
    try {
      error = await _runUpload();
    } catch (_) {
      error = const BackupGenericFailure();
    } finally {
      busyNotifier.value = false;
    }
    final now = DateTime.now();
    if (error == null) {
      _config.recordSuccess(now);
    } else {
      _config.recordFailure(now, error.id);
    }
    return error;
  }

  /// 生成归档文本
  Future<BackupFailure?> _runUpload() async {
    if (!_config.isConfigured) {
      return const BackupNotConfiguredFailure();
    }
    final content = await buildArchiveText();
    try {
      await _createClient().upload(fileName: kBackupFileName, content: content);
      return null;
    } on WebDavException catch (e) {
      return BackupWebDavFailure(e.statusCode);
    } catch (_) {
      return const BackupGenericFailure();
    }
  }

  /// 生成整档 JSON 文本
  Future<String> buildArchiveText() async {
    _requireContainer.read(usersProvider.notifier).flush();
    Map<Object?, dynamic> snapshot(String name) =>
        Map<Object?, dynamic>.from(Hive.box(name).toMap());
    String? appVersion;
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // 拿不到版本号不影响备份
    }
    return jsonEncode(DataArchive.encode(
      userDataBox: snapshot('user_data'),
      userMetaBox: snapshot('user_meta'),
      appMetaBox: snapshot('app_meta'),
      itemRulesBox: snapshot('item_rules'),
      gameTrackBox: snapshot('game_track'),
      appVersion: appVersion,
    ));
  }

  /// 下载并解析云端备份文件
  Future<RemoteBackupPreview?> fetchRemotePreview() async {
    final client = _createClient();
    final info = await client.fetchInfo(fileName: kBackupFileName);
    if (!info.exists) {
      return null;
    }
    final text = await client.download(fileName: kBackupFileName);
    return RemoteBackupPreview(fileInfo: info, contents: DataArchive.decode(text));
  }

  /// 覆盖式恢复
  Future<BackupFailure?> applyArchive(ArchiveContents contents) async {
    if (busyNotifier.value) {
      return const BackupBusyFailure();
    }
    // 没有任何可恢复的节
    if (contents.userData == null &&
        contents.userMeta == null &&
        contents.appMeta == null &&
        contents.itemRules == null &&
        contents.gameTrack == null) {
      return const BackupNoDataFailure();
    }

    busyNotifier.value = true;
    final failed = <DataSection>[];
    try {
      // 防抖中的内存态先落盘
      _requireContainer.read(usersProvider.notifier).flush();

      if (contents.userData != null) {
        final box = Hive.box('user_data');
        try {
          await box.clear();
          await box.putAll(contents.userData!);
        } catch (e) {
          failed.add(DataSection.userData);
        }
      }
      if (contents.userMeta != null) {
        final box = Hive.box('user_meta');
        try {
          await box.clear();
          await box.putAll(contents.userMeta!);
        } catch (e) {
          failed.add(DataSection.userMeta);
        }
      } else if (contents.userData != null) {
        // 归档缺元数据节
        final box = Hive.box('user_meta');
        try {
          await box.delete('currentUserId');
          await box.delete('nextUserId');
        } catch (e) {
          failed.add(DataSection.userMeta);
        }
      }
      if (contents.appMeta != null) {
        final box = Hive.box('app_meta');
        try {
          // 保留本地 webdav* 配置
          final keys = box.keys.whereType<String>().where(
                (key) => !key.startsWith(DataArchive.appConfigExcludePrefix),
              );
          for (final key in keys.toList()) {
            await box.delete(key);
          }
          await box.putAll(contents.appMeta!);
        } catch (e) {
          failed.add(DataSection.appSettings);
        }
      }
      if (contents.itemRules != null) {
        final box = Hive.box('item_rules');
        try {
          await box.clear();
          await box.putAll(contents.itemRules!);
        } catch (e) {
          failed.add(DataSection.itemRules);
        }
      }
      if (contents.gameTrack != null) {
        final box = Hive.box('game_track');
        try {
          await box.clear();
          await box.putAll(contents.gameTrack!);
        } catch (e) {
          failed.add(DataSection.gameTrack);
        }
      }
      _reloadStores();
    } finally {
      busyNotifier.value = false;
    }

    if (failed.isNotEmpty) {
      return BackupPartialRestoreFailure(failed);
    }
    dataRestoredNotifier.value++;
    return null;
  }

  /// 写入完成后按依赖顺序重载各 store
  void _reloadStores() {
    Stores.itemComparerStore.reload();
    Stores.itemRuleStore.reload();
    Stores.appSettingsStore.reload();
    Stores.webDavConfigStore.reload();
    _requireContainer.read(usersProvider.notifier).reload();
  }
}
