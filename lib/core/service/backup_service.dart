import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';

/// 云端备份预览（从云端下载并解析后的产物，供恢复前确认弹窗展示）
class RemoteBackupPreview {
  const RemoteBackupPreview({required this.fileInfo, required this.contents});

  final WebDavFileInfo fileInfo;
  final ArchiveContents contents;
}

/// 备份/恢复编排与自动调度。
///
/// 自动触发靠监听 Hive 5 个 box 的 watch() 事件流（零侵入各 store 落盘路径：
/// 输入防抖、轨迹记录、规则/装备对比写盘都自然产生事件），统一 30s 防抖；
/// 恢复/导入期间（[_suspended]）到达的事件只置 dirty，结束后补一次，
/// 让恢复后的新状态也立刻有一份云端备份。
///
/// 自动上传全程静默：失败仅记录到 WebDavConfigStore（备份页可查），
/// 不弹提示、不打扰游戏输入；失败不自动重试，下次变更/启动/手动自然再试。
/// 自动与手动共用一个单飞锁，避免请求风暴。
class BackupService with WidgetsBindingObserver {
  BackupService();

  static const Duration autoDebounce = Duration(seconds: 30);
  static const List<String> _boxNames = [
    'user_data',
    'user_meta',
    'app_meta',
    'item_rules',
    'game_track',
  ];

  /// 单例（与 Stores 门面相同的 GetIt 惰性注册方式）；
  /// 应用启动时在 main._initializeGetIt 显式注册并 [start]
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

  final List<StreamSubscription<BoxEvent>> _subscriptions = [];
  Timer? _debounceTimer;
  bool _uploading = false;
  bool _dirty = false;
  bool _suspended = false;
  bool _pendingOnResume = false;
  bool _disposed = false;
  bool _started = false;

  WebDavConfigStore get _config => Stores.webDavConfigStore;

  // ── 启动与生命周期 ──────────────────────────────────────────────

  /// 订阅 5 个 box 的变更流并注册生命周期监听（幂等）
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    for (final name in _boxNames) {
      _subscriptions.add(Hive.box(name).watch().listen(_onBoxEvent));
    }
    // 启动补传检测：自动开启且从未成功/距上次成功超过间隔
    _scheduleCatchUpIfNeeded();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused) {
      // 退后台：取消待执行的防抖定时器；回前台时有变更则立即补一次
      if (_debounceTimer != null) {
        _debounceTimer!.cancel();
        _debounceTimer = null;
        _pendingOnResume = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pendingOnResume) {
        _pendingOnResume = false;
        if (_config.autoEnabledNotifier.value) {
          _scheduleAutoUpload();
        }
      }
      _scheduleCatchUpIfNeeded();
    } else if (state == AppLifecycleState.detached) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    }
  }

  // ── 变更监听与自动调度 ──────────────────────────────────────────

  void _onBoxEvent(BoxEvent event) {
    if (_disposed) return;
    // app_meta 的 webdav* 键是备份配置自身（开关/凭据改动），不触发自动备份
    if (event.key is String &&
        (event.key as String).startsWith(DataArchive.appConfigExcludePrefix)) {
      return;
    }
    if (_suspended) {
      // 恢复/导入期间写入：只记 dirty，结束后按需补一次
      _dirty = true;
      return;
    }
    _scheduleAutoUpload();
  }

  void _scheduleAutoUpload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(autoDebounce, () {
      _debounceTimer = null;
      unawaited(_performUpload());
    });
  }

  void _scheduleCatchUpIfNeeded() {
    final config = _config;
    if (!config.autoEnabledNotifier.value) return;
    if (shouldCatchUp(
      config.lastSuccessAtNotifier.value,
      DateTime.now(),
      config.intervalHoursNotifier.value,
    )) {
      _scheduleAutoUpload();
    }
  }

  /// 距上次成功备份超过间隔（小时）或从未成功过时需要补传；纯静态便于测试
  static bool shouldCatchUp(
    int? lastSuccessAtMs,
    DateTime now,
    int intervalHours,
  ) {
    if (lastSuccessAtMs == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastSuccessAtMs);
    return now.difference(last) >= Duration(hours: intervalHours);
  }

  // ── 上传（自动/手动共用） ────────────────────────────────────────

  /// 手动备份：立即上传；返回 null 表示成功，否则为错误文案
  Future<String?> manualBackup() => _performUpload(manual: true);

  /// 单飞执行一次上传；自动路径静默（结果记入配置供页面查询），
  /// 手动路径返回错误文案。自动开关关闭时自动路径直接跳过
  Future<String?> _performUpload({bool manual = false}) async {
    if (_uploading) {
      if (!manual) _dirty = true;
      return manual ? '已有备份任务进行中' : null;
    }
    if (busyNotifier.value) {
      // 恢复/导入等其他任务占用了通道：自动路径记 dirty 稍后补，手动直接拒绝
      if (!manual) _dirty = true;
      return manual ? '已有备份任务进行中，请稍后再试' : null;
    }
    if (!manual && !_config.autoEnabledNotifier.value) {
      _dirty = false;
      return null;
    }
    _uploading = true;
    busyNotifier.value = true;
    String? error;
    try {
      error = await _runUpload();
    } catch (_) {
      error = '备份失败，请稍后重试';
    } finally {
      _uploading = false;
      busyNotifier.value = false;
    }
    final now = DateTime.now();
    if (error == null) {
      _config.recordSuccess(now);
    } else {
      _config.recordFailure(now, error);
    }
    // 上传期间到达的新变更（单飞合并入 dirty）：成功后补一次；
    // 失败时丢弃——下一次变更/启动补传/手动备份自然再试
    final hadDirty = _dirty;
    _dirty = false;
    if (error == null && hadDirty && _config.autoEnabledNotifier.value) {
      _scheduleAutoUpload();
    }
    return manual ? error : null;
  }

  /// 生成归档文本（先 flush 当前用户防抖中的数据）并上传
  Future<String?> _runUpload() async {
    if (!_config.isConfigured) {
      return '请先配置 WebDAV 服务器地址、账号与密码';
    }
    final content = await buildArchiveText();
    final client = WebDavClient(
      url: _config.urlNotifier.value,
      username: _config.usernameNotifier.value,
      password: _config.passwordNotifier.value,
    );
    try {
      await client.upload(fileName: kBackupFileName, content: content);
      return null;
    } on WebDavException catch (e) {
      return e.message;
    } catch (_) {
      return '备份失败，请稍后重试';
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
    final client = WebDavClient(
      url: _config.urlNotifier.value,
      username: _config.usernameNotifier.value,
      password: _config.passwordNotifier.value,
    );
    final info = await client.fetchInfo(fileName: kBackupFileName);
    if (!info.exists) {
      return null;
    }
    final text = await client.download(fileName: kBackupFileName);
    return RemoteBackupPreview(fileInfo: info, contents: DataArchive.decode(text));
  }

  /// 覆盖式恢复：把归档内容写入 5 个 box 并触发全量 reload。
  /// 手动导入与云端恢复共用此路径。返回 null 表示成功，否则为错误文案。
  /// 成功后 UI 通过 store 的 ValueNotifier / dataVersion 立即刷新，无需重启。
  Future<String?> applyArchive(ArchiveContents contents) async {
    if (busyNotifier.value) {
      return '已有备份任务进行中，请稍后再试';
    }
    // 没有任何可恢复的节
    if (contents.userData == null &&
        contents.userMeta == null &&
        contents.appMeta == null &&
        contents.itemRules == null &&
        contents.gameTrack == null) {
      return '文件中不包含可恢复的数据';
    }

    _suspended = true;
    _dirty = false;
    busyNotifier.value = true;
    final failed = <String>[];
    try {
      // 防抖中的内存态先落盘，避免随后的 box 覆盖丢失最近输入
      Stores.infoStore.flush();

      if (contents.userData != null) {
        final box = Hive.box('user_data');
        try {
          await box.clear();
          await box.putAll(contents.userData!);
        } catch (e) {
          failed.add('用户数据');
        }
      }
      if (contents.userMeta != null) {
        final box = Hive.box('user_meta');
        try {
          await box.clear();
          await box.putAll(contents.userMeta!);
        } catch (e) {
          failed.add('用户元数据');
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
          failed.add('用户元数据');
        }
      }
      if (contents.appMeta != null) {
        final box = Hive.box('app_meta');
        try {
          // 保留本地 webdav* 配置（凭据/开关属于本机，归档中也不含这些键），
          // 其余键先清空再写入归档子集
          final keys = box.keys.whereType<String>().where(
                (key) => !key.startsWith(DataArchive.appConfigExcludePrefix),
              );
          for (final key in keys.toList()) {
            await box.delete(key);
          }
          await box.putAll(contents.appMeta!);
        } catch (e) {
          failed.add('应用设置');
        }
      }
      if (contents.itemRules != null) {
        final box = Hive.box('item_rules');
        try {
          await box.clear();
          await box.putAll(contents.itemRules!);
        } catch (e) {
          failed.add('高亮规则');
        }
      }
      if (contents.gameTrack != null) {
        final box = Hive.box('game_track');
        try {
          await box.clear();
          await box.putAll(contents.gameTrack!);
        } catch (e) {
          failed.add('游戏轨迹');
        }
      }
      _reloadStores();
    } finally {
      _suspended = false;
      busyNotifier.value = false;
    }

    if (_dirty && _config.autoEnabledNotifier.value) {
      // 恢复后的新状态值得立刻有一份云端备份
      _dirty = false;
      _scheduleAutoUpload();
    }
    _dirty = false;

    if (failed.isNotEmpty) {
      return '以下数据恢复失败：${failed.join('、')}';
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
