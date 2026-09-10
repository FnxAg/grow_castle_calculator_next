import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 可注入的假客户端：记录调用并按需返回/抛出，全程不触网
class _FakeWebDavClient extends WebDavBackupClient {
  _FakeWebDavClient({this.info, this.infoError, this.uploadError})
      : super(
          url: 'https://dav.example.com/dav',
          username: 'u',
          password: 'p',
        );

  /// fetchInfo 的返回值；为 null 时返回"云端无文件"
  WebDavFileInfo? info;

  /// 非 null 时 fetchInfo 直接抛出该对象（用于模拟各类失败）
  Object? infoError;

  /// 非 null 时 upload 抛出 WebDavException(401, 该文案)
  String? uploadError;

  final List<String> uploadedContents = [];
  int infoCalls = 0;

  @override
  Future<WebDavFileInfo> fetchInfo({required String fileName}) async {
    infoCalls++;
    if (infoError != null) throw infoError!;
    return info ?? const WebDavFileInfo(exists: false);
  }

  @override
  Future<void> upload({
    required String fileName,
    required String content,
  }) async {
    if (uploadError != null) throw WebDavException(401, uploadError!);
    uploadedContents.add(content);
  }
}

void main() {
  setUp(() async {
    // 整个文件共享一个 Hive 测试目录（不 close box）
    if (!Hive.isBoxOpen('app_meta')) {
      final dir = await Directory.systemTemp.createTemp('backup_service_test');
      Hive.init(dir.path);
      for (final name in [
        'app_meta',
        'user_data',
        'user_meta',
        'item_rules',
        'game_track',
      ]) {
        await Hive.openBox(name);
      }
    }
    for (final name in [
      'app_meta',
      'user_data',
      'user_meta',
      'item_rules',
      'game_track',
    ]) {
      await Hive.box(name).clear();
    }
    GetIt.instance.reset();
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  BackupService serviceWith(
    _FakeWebDavClient fake, {
    List<String>? seenCredentials,
  }) {
    return BackupService(
      clientFactory: ({
        required String url,
        required String username,
        required String password,
      }) {
        seenCredentials?.addAll([url, username, password]);
        return fake;
      },
    );
  }

  group('compareRemoteBackup:云端与本机记录的新旧判定', () {
    final local = DateTime(2026, 1, 1, 12);
    final localMs = local.millisecondsSinceEpoch;

    WebDavFileInfo info({bool exists = true, DateTime? modified}) =>
        WebDavFileInfo(exists: exists, lastModified: modified);

    test('云端无文件 → noRemote', () {
      expect(
        BackupService.compareRemoteBackup(
          info: info(exists: false),
          lastSuccessAtMs: localMs,
        ),
        RemoteBackupRelation.noRemote,
      );
    });

    test('有文件但取不到修改时间 → remoteUnknown', () {
      expect(
        BackupService.compareRemoteBackup(
          info: info(),
          lastSuccessAtMs: localMs,
        ),
        RemoteBackupRelation.remoteUnknown,
      );
    });

    test('本机从未成功备份过 → remoteUnknown', () {
      expect(
        BackupService.compareRemoteBackup(
          info: info(modified: local.add(const Duration(days: 3))),
          lastSuccessAtMs: null,
        ),
        RemoteBackupRelation.remoteUnknown,
      );
    });

    test('云端晚于本机超过容差 → remoteNewer', () {
      expect(
        BackupService.compareRemoteBackup(
          info: info(
            modified: local
                .add(BackupService.remoteNewerTolerance)
                .add(const Duration(seconds: 1)),
          ),
          lastSuccessAtMs: localMs,
        ),
        RemoteBackupRelation.remoteNewer,
      );
    });

    test('差值正好等于容差 → remoteOlder（严格大于才告警）', () {
      expect(
        BackupService.compareRemoteBackup(
          info: info(modified: local.add(BackupService.remoteNewerTolerance)),
          lastSuccessAtMs: localMs,
        ),
        RemoteBackupRelation.remoteOlder,
      );
    });

    test('本机刚上传完的邻近时间(±数秒) → remoteOlder', () {
      expect(
        BackupService.compareRemoteBackup(
          info: info(modified: local.add(const Duration(seconds: 1))),
          lastSuccessAtMs: localMs,
        ),
        RemoteBackupRelation.remoteOlder,
      );
    });

    test('云端是更早的旧档 → remoteOlder', () {
      expect(
        BackupService.compareRemoteBackup(
          info: info(modified: local.subtract(const Duration(days: 1))),
          lastSuccessAtMs: localMs,
        ),
        RemoteBackupRelation.remoteOlder,
      );
    });

    test('UTC 与本地时间混用仍按绝对时刻比较', () {
      final utcLocal = DateTime.utc(2026, 1, 1, 12);
      expect(
        BackupService.compareRemoteBackup(
          info: info(modified: utcLocal.add(const Duration(days: 2))),
          lastSuccessAtMs: utcLocal.millisecondsSinceEpoch,
        ),
        RemoteBackupRelation.remoteNewer,
      );
    });
  });

  group('manualBackup:上传与留痕', () {
    test('成功:返回 null、内容进客户端、凭据取自配置、记录成功时间', () async {
      final fake = _FakeWebDavClient();
      final seen = <String>[];
      final service = serviceWith(fake, seenCredentials: seen);
      Stores.webDavConfigStore
        ..setUrl('https://dav.example.com/dav/x')
        ..setUsername('alice')
        ..setPassword('pw');

      expect(await service.manualBackup(), isNull);

      expect(seen, ['https://dav.example.com/dav/x', 'alice', 'pw']);
      expect(fake.uploadedContents, hasLength(1));
      final config = Stores.webDavConfigStore;
      expect(config.lastSuccessAtNotifier.value, isNotNull);
      expect(config.lastErrorNotifier.value, isNull);
    });

    test('失败:返回错误文案并写入失败留痕，成功时间不变', () async {
      final fake = _FakeWebDavClient(uploadError: '账号或密码错误（HTTP 401）');
      final service = serviceWith(fake);
      Stores.webDavConfigStore
        ..setUrl('https://dav.example.com/dav/x')
        ..setUsername('alice')
        ..setPassword('pw');

      expect(await service.manualBackup(), '账号或密码错误（HTTP 401）');

      final config = Stores.webDavConfigStore;
      expect(config.lastErrorNotifier.value, '账号或密码错误（HTTP 401）');
      expect(config.lastSuccessAtNotifier.value, isNull);
    });

    test('已有任务进行中:直接拒绝且不发起请求', () async {
      final fake = _FakeWebDavClient();
      final service = serviceWith(fake);
      service.busyNotifier.value = true;

      expect(await service.manualBackup(), contains('进行中'));
      expect(fake.uploadedContents, isEmpty);
    });
  });

  group('fetchRemoteInfo:探测透传', () {
    test('云端有文件时带回修改时间与大小', () async {
      final fake = _FakeWebDavClient(
        info: WebDavFileInfo(
          exists: true,
          lastModified: DateTime(2026, 1, 2),
          contentLength: 2048,
        ),
      );
      final service = serviceWith(fake);

      final info = await service.fetchRemoteInfo();

      expect(info.exists, isTrue);
      expect(info.lastModified, DateTime(2026, 1, 2));
      expect(info.contentLength, 2048);
      expect(fake.infoCalls, 1);
    });

    test('云端无文件时 exists 为 false', () async {
      final service = serviceWith(_FakeWebDavClient());
      expect((await service.fetchRemoteInfo()).exists, isFalse);
    });

    test('客户端抛出时向上抛出', () async {
      final service = serviceWith(
        _FakeWebDavClient(infoError: WebDavException(401, '账号或密码错误（HTTP 401）')),
      );
      await expectLater(
        service.fetchRemoteInfo(),
        throwsA(
          isA<WebDavException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('applyArchive:覆盖式恢复', () {
    ArchiveContents contentsWith({Map<String, dynamic>? userData}) =>
        DataArchive.decode(jsonEncode({
          'formatVersion': 1,
          'data': {'userData': ?userData},
        }));

    test('写入 user_data、清掉旧条目并递增 dataRestoredNotifier', () async {
      final service = serviceWith(_FakeWebDavClient());
      await Hive.box('user_data').put(9, {'name': '旧用户'});

      expect(
        await service.applyArchive(contentsWith(userData: {'0': {'name': '恢复'}})),
        isNull,
      );

      expect(Hive.box('user_data').get(0), {'name': '恢复'});
      expect(Hive.box('user_data').get(9), isNull);
      expect(service.dataRestoredNotifier.value, 1);
    });

    test('没有任何可恢复节时拒绝且不写盘', () async {
      final service = serviceWith(_FakeWebDavClient());
      await Hive.box('user_data').put(0, {'name': '保留'});

      expect(await service.applyArchive(contentsWith()), contains('不包含'));

      expect(Hive.box('user_data').get(0), {'name': '保留'});
      expect(service.dataRestoredNotifier.value, 0);
    });

    test('已有任务进行中时拒绝', () async {
      final service = serviceWith(_FakeWebDavClient());
      service.busyNotifier.value = true;

      expect(
        await service.applyArchive(contentsWith(userData: {'0': {}})),
        contains('进行中'),
      );
      expect(service.dataRestoredNotifier.value, 0);
    });
  });

  group('buildArchiveText:整档生成', () {
    test('生成的文本可被 DataArchive 回读，且含用户数与轨迹条数', () async {
      await Hive.box('user_data').put(0, {'name': '甲'});
      await Hive.box('user_data').put(1, {'name': '乙'});
      await Hive.box('game_track').put('user_0', [
        {'floor': 1},
        {'floor': 2},
      ]);

      final text = await serviceWith(_FakeWebDavClient()).buildArchiveText();
      final contents = DataArchive.decode(text);

      expect(contents.userCount, 2);
      expect(contents.trackRecordCount, 2);
      // 凭据与备份状态不进归档
      expect(contents.appMeta?.keys.where((k) => k.startsWith('webdav')), isEmpty);
    });
  });
}
