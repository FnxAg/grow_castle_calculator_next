import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';

/// 构造 [WebDavBackupClient] 的工厂：测试经此注入假实现，全程不触网
typedef WebDavBackupClientFactory = WebDavBackupClient Function({
  required String url,
  required String username,
  required String password,
});

/// 云端备份与本机记录的新旧关系（备份前探测的判定结论）
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

/// 云端备份预览（从云端下载并解析后的产物，供恢复前确认弹窗展示）
class RemoteBackupPreview {
  const RemoteBackupPreview({required this.fileInfo, required this.contents});

  final WebDavFileInfo fileInfo;
  final ArchiveContents contents;
}

/// 恢复失败时的数据分段（用于「以下数据恢复失败：…」）
enum DataSection { userData, userMeta, appSettings, itemRules, gameTrack }

/// 备份/恢复失败原因。
///
/// **不携带任何文案**：服务层只回答"失败在哪一步"，文案由 UI 层按当前语言
/// 翻译（lib/view/extension/service_error_l10n.dart）。这样错误原因被写进
/// WebDAV 配置持久化时也是语言中立的（[id]），换语言不会显示成旧语言。
sealed class BackupFailure {
  const BackupFailure();

  /// 持久化用的稳定 id（存进「上次失败原因」）
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

/// 其它未分类失败（写盘异常、未知异常等）
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

/// 网络/服务器侧失败，[statusCode] 为 HTTP 状态码（-1 = 连不上）
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

/// 备份/恢复编排：全部手动触发，无任何自动上传路径。
///
/// 云端只有一份文件，覆盖即不可找回，因此上传前必须由备份页先
/// [fetchRemoteInfo] 探测、用 [compareRemoteBackup] 判定新旧、经用户确认，
/// 才调用 [manualBackup]。[applyArchive] 是手动导入与云端恢复的共用路径，
/// 与上传共用一个 busy 锁避免并发写 box。
class BackupService {
  BackupService({WebDavBackupClientFactory? clientFactory})
      : _clientFactory = clientFactory ?? _defaultClientFactory;

  static WebDavBackupClient _defaultClientFactory({
    required String url,
    required String username,
    required String password,
  }) =>
      WebDavBackupClient(url: url, username: username, password: password);

  /// 跨时钟比较容差：覆盖上传往返 + 设备与服务器的轻度时钟偏差。
  /// 服务器时钟偏快只会多弹一次警告（可容忍），偏慢会漏报（危险），
  /// 故取偏保守的小值。
  static const Duration remoteNewerTolerance = Duration(minutes: 5);

  /// 单例（与 Stores 门面相同的 GetIt 惰性注册方式）
  static BackupService get instance {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<BackupService>()) {
      getIt.registerSingleton<BackupService>(BackupService());
    }
    return getIt<BackupService>();
  }

  /// 有备份/恢复任务进行中（页面转圈/禁用操作入口）
  final ValueNotifier<bool> busyNotifier = ValueNotifier<bool>(false);

  /// 数据恢复/导入完成通知（值递增）：供不依赖 store notifier 的页面
  /// （如装备对比输入页）重新回填输入框
  final ValueNotifier<int> dataRestoredNotifier = ValueNotifier<int>(0);

  final WebDavBackupClientFactory _clientFactory;

  WebDavConfigStore get _config => Stores.webDavConfigStore;

  WebDavBackupClient _createClient() => _clientFactory(
        url: _config.urlNotifier.value,
        username: _config.usernameNotifier.value,
        password: _config.passwordNotifier.value,
      );

  /// 云端与本机记录的新旧判定（纯函数便于测试）。
  /// 同一结论在上传与恢复两个方向上的"危险方"相反：上传时 remoteNewer
  /// 危险（会盖掉别处的新数据），恢复时 remoteOlder 危险（会退回旧数据）。
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

  // ── 探测 ────────────────────────────────────────────────────────

  /// 探测云端备份元信息（PROPFIND/HEAD，不下载内容）。
  /// 云端无文件时 exists 为 false；认证/网络/服务器错误抛 [WebDavException]
  Future<WebDavFileInfo> fetchRemoteInfo() =>
      _createClient().fetchInfo(fileName: kBackupFileName);

  // ── 上传（仅手动） ──────────────────────────────────────────────

  /// 手动备份：立即上传；返回 null 表示成功，否则为失败原因。
  ///
  /// **调用方必须先 [fetchRemoteInfo] 探测并经用户确认覆盖**。
  /// 确认到 PUT 之间存在窗口：期间其他设备若上传，本机的覆盖仍会生效
  /// （本轮不处理；用条件 PUT 封堵是后续可选加固）。
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

  /// 生成归档文本（先 flush 当前用户防抖中的数据）并上传
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

  // ── 归档生成 ────────────────────────────────────────────────────

  /// 生成整档 JSON 文本（编码前先 flush：InfoStore 输入有 400ms 防抖落盘，
  /// 不 flush 会漏掉最近输入）
  Future<String> buildArchiveText() async {
    Stores.infoStore.flush();
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

  // ── 云端恢复 ────────────────────────────────────────────────────

  /// 下载并解析云端备份文件；云端尚无备份时返回 null；
  /// 网络/认证错误抛 [WebDavException]，内容损坏抛 [DataArchiveException]
  Future<RemoteBackupPreview?> fetchRemotePreview() async {
    final client = _createClient();
    final info = await client.fetchInfo(fileName: kBackupFileName);
    if (!info.exists) {
      return null;
    }
    final text = await client.download(fileName: kBackupFileName);
    return RemoteBackupPreview(fileInfo: info, contents: DataArchive.decode(text));
  }

  /// 覆盖式恢复：把归档内容写入 5 个 box 并触发全量 reload。
  /// 手动导入与云端恢复共用此路径。返回 null 表示成功，否则为失败原因。
  /// 成功后 UI 通过 store 的 ValueNotifier / dataVersion 立即刷新，无需重启。
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
      // 防抖中的内存态先落盘，避免随后的 box 覆盖丢失最近输入
      Stores.infoStore.flush();

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
        // 归档缺元数据节（裁剪/手写文件）：清掉本机陈旧的 currentUserId/
        // nextUserId，让 InfoStore reload 按导入的用户 key 重算。
        // 否则陈旧的 nextUserId 会让之后新建的用户 id 覆盖导入的用户
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
          // 保留本地 webdav* 配置（凭据与备份状态属于本机，归档中也不含这些键），
          // 其余键先清空再写入归档子集
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

  /// 写入完成后按依赖顺序重载各 store：
  /// 各 store 的 reload 内部重置字段并刷新 ValueNotifier（等值不通知，安全）
  void _reloadStores() {
    Stores.itemComparerStore.reload();
    Stores.itemRuleStore.reload();
    Stores.appSettingsStore.reload();
    Stores.webDavConfigStore.reload();
    Stores.infoStore.reload();
  }
}
