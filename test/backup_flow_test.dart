import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';
import 'package:grow_castle_calculator_next/view/page/setting/backup_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 手动备份/恢复流程测试：探测 → 确认弹窗 → 上传/恢复。
///
/// 网络侧用 [_FakeWebDavClient] 经 BackupService 的 clientFactory 注入，
/// 全程不触网；断言的是"假客户端被调用与否"，而非 HTTP 动词序列。
///
/// **Hive 写盘约定（本文件的硬前提）**：testWidgets 的 FakeAsync 时区里
/// 任何 box 写入都会把写链的完成延续绑在该时区上，用例结束后时区销毁、
/// 写链永久停摆，**下一条用例的 setUp 里 `await box.clear()`（真实时区）
/// 会永久等待**（即 backup_page_test 文件头写明的禁忌）。而上传/恢复路径
/// 天然会写盘（`InfoStore.flush()` 无条件落盘、`recordSuccess` 记时间），
/// 因此本文件把这两个 store 换成 [_FakeInfoStore] / [_FakeConfigStore]：
/// 只更新内存与 notifier、不碰 box。**新增用例时不要让页面触发任何写盘**，
/// 需要验证"确实落盘"的行为请放到 backup_service_test.dart 的服务级测试里。
class _FakeWebDavClient extends WebDavBackupClient {
  _FakeWebDavClient()
      : super(
          url: 'https://dav.example.com/dav',
          username: 'u',
          password: 'p',
        );

  /// fetchInfo 的返回值；为 null 时返回"云端无文件"
  WebDavFileInfo? info;

  /// 非 null 时 fetchInfo 直接抛出该对象（模拟 401/网络层等失败）
  Object? infoError;

  /// download 返回的归档文本；为 null 时抛 404
  String? remoteText;

  final List<String> uploadedContents = [];
  int infoCalls = 0;
  int downloadCalls = 0;

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
    uploadedContents.add(content);
  }

  @override
  Future<String> download({required String fileName}) async {
    downloadCalls++;
    final text = remoteText;
    if (text == null) throw WebDavException(404, '云端还没有备份文件');
    return text;
  }
}

/// 不落盘的配置 store：setter 只改 notifier（父类会写 box，见文件头约定）。
/// `isConfigured` / 各 notifier 沿用父类实现，备份页读到的东西与真实一致。
class _FakeConfigStore extends WebDavConfigStore {
  int successCalls = 0;
  int failureCalls = 0;

  @override
  void setUrl(String url) => urlNotifier.value = url;

  @override
  void setUsername(String username) => usernameNotifier.value = username;

  @override
  void setPassword(String password) => passwordNotifier.value = password;

  @override
  void clearLastSuccess() => lastSuccessAtNotifier.value = null;

  @override
  void recordSuccess(DateTime at) {
    successCalls++;
    lastSuccessAtNotifier.value = at.millisecondsSinceEpoch;
    lastErrorNotifier.value = null;
  }

  @override
  void recordFailure(DateTime at, String message) {
    failureCalls++;
    lastErrorAtNotifier.value = at.millisecondsSinceEpoch;
    lastErrorNotifier.value = message;
  }
}

/// 不落盘的 InfoStore：`BackupService.buildArchiveText()` 会调 `flush()`
/// 把防抖中的输入落盘（父类实现连写两个 box），测试里空转即可。
class _FakeInfoStore extends InfoStore {
  int flushCalls = 0;

  @override
  void flush() => flushCalls++;
}

void main() {
  late _FakeWebDavClient fake;
  late _FakeConfigStore config;

  setUp(() async {
    if (!Hive.isBoxOpen('app_meta')) {
      final dir = await Directory.systemTemp.createTemp('backup_flow_test');
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
    fake = _FakeWebDavClient();
    // store 必须在**真实时区**构造：InfoStore 在用户为空时会新建默认用户
    // 并落盘（_persistUser/_persistMeta），在 FakeAsync 时区里构造会毒化
    // 写链（见文件头写盘约定）。之后的 configure() 只改 notifier，不写盘。
    config = _FakeConfigStore();
    GetIt.instance
      ..registerSingleton<WebDavConfigStore>(config)
      ..registerSingleton<InfoStore>(_FakeInfoStore());
    // 备份时会读应用版本号：不走平台通道（FakeAsync 下永不返回，
    // 会让 busy 状态与转圈卡住，pumpAndSettle 随之超时）
    PackageInfo.setMockInitialValues(
      appName: 'gcc_next',
      packageName: 'grow_castle_calculator_next',
      version: '1.5.4',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: BackupPage()));
    await tester.pump();
  }

  /// 配置凭据（可选设置上次成功备份时间）并注册注入假客户端的服务。
  /// store 已由 setUp 在真实时区建好，这里只改 notifier，不产生写盘
  void configure({int? lastSuccessMs}) {
    config
      ..setUrl('https://dav.example.com/dav/x')
      ..setUsername('alice')
      ..setPassword('pw');
    if (lastSuccessMs != null) {
      config.recordSuccess(DateTime.fromMillisecondsSinceEpoch(lastSuccessMs));
    }
    GetIt.instance.registerSingleton<BackupService>(
      BackupService(
        clientFactory: ({
          required String url,
          required String username,
          required String password,
        }) =>
            fake,
      ),
    );
  }

  Future<void> tapBackup(WidgetTester tester) async {
    await tester.tap(find.text('立即备份'));
    await tester.pumpAndSettle();
  }

  testWidgets('探测认证失败:提示错误、不上传、不写失败留痕', (tester) async {
    configure();
    fake.infoError = WebDavException(401, '账号或密码错误（HTTP 401）');
    await pumpPage(tester);

    await tapBackup(tester);

    expect(find.textContaining('账号或密码错误'), findsOneWidget);
    expect(fake.uploadedContents, isEmpty);
    expect(Stores.webDavConfigStore.lastErrorNotifier.value, isNull);
  });

  testWidgets('探测网络层失败:提示后拦截', (tester) async {
    configure();
    fake.infoError = StateError('socket 连接失败');
    await pumpPage(tester);

    await tapBackup(tester);

    expect(find.textContaining('请稍后重试'), findsOneWidget);
    expect(fake.uploadedContents, isEmpty);
  });

  testWidgets('云端无备份:弹窗提示将新建,确认后上传并记录成功', (tester) async {
    configure();
    fake.info = const WebDavFileInfo(exists: false);
    await pumpPage(tester);

    await tapBackup(tester);

    expect(find.textContaining('还没有备份文件'), findsOneWidget);
    expect(find.textContaining('本机上次成功备份：从未'), findsOneWidget);
    expect(find.text('恢复云端'), findsNothing); // 无云端内容可恢复，不给捷径

    await tester.tap(find.text('上传'));
    await tester.pumpAndSettle();

    expect(fake.uploadedContents, hasLength(1));
    expect(find.textContaining('已备份到云端'), findsOneWidget);
    expect(Stores.webDavConfigStore.lastSuccessAtNotifier.value, isNotNull);
  });

  testWidgets('云端较新:高亮警告,取消后不发任何上传', (tester) async {
    final local = DateTime(2026, 1, 1, 12);
    configure(lastSuccessMs: local.millisecondsSinceEpoch);
    fake.info = WebDavFileInfo(
      exists: true,
      lastModified: local.add(const Duration(days: 1)),
      contentLength: 4096,
    );
    await pumpPage(tester);

    await tapBackup(tester);

    expect(find.textContaining('可能来自其他设备'), findsOneWidget);
    expect(find.textContaining('4 KB'), findsOneWidget);
    expect(find.text('恢复云端'), findsOneWidget);
    expect(find.text('仍要覆盖'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(fake.uploadedContents, isEmpty);
    expect(
      Stores.webDavConfigStore.lastSuccessAtNotifier.value,
      local.millisecondsSinceEpoch,
    );
  });

  testWidgets('云端较新:点恢复云端落到既有预览确认流程', (tester) async {
    final local = DateTime(2026, 1, 1, 12);
    configure(lastSuccessMs: local.millisecondsSinceEpoch);
    fake.info = WebDavFileInfo(
      exists: true,
      lastModified: local.add(const Duration(days: 1)),
      contentLength: 1024,
    );
    fake.remoteText = jsonEncode({
      'formatVersion': 1,
      'exportedAt': '2026-01-02T00:00:00Z',
      'data': {
        'userData': {
          '0': {'name': '云端用户'},
        },
      },
    });
    await pumpPage(tester);

    await tapBackup(tester);
    await tester.tap(find.text('恢复云端'));
    await tester.pumpAndSettle();

    // 恢复流程自带预览确认（来源/摘要/覆盖警告）
    expect(find.text('覆盖恢复'), findsOneWidget);
    expect(find.textContaining('用户数：1'), findsOneWidget);
    expect(fake.downloadCalls, 1);
    expect(fake.uploadedContents, isEmpty);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 取消不写盘：box 里仍是 InfoStore 建出来的默认用户，未被云端内容覆盖
    final stored = Hive.box('user_data').get(0) as Map;
    expect(stored['username'], 'default');
  });

  testWidgets('云端较旧:无警告,确认后覆盖上传', (tester) async {
    final local = DateTime(2026, 1, 5, 12);
    configure(lastSuccessMs: local.millisecondsSinceEpoch);
    fake.info = WebDavFileInfo(
      exists: true,
      lastModified: local.subtract(const Duration(days: 2)),
      contentLength: 2048,
    );
    await pumpPage(tester);

    await tapBackup(tester);

    expect(find.textContaining('可能来自其他设备'), findsNothing);
    expect(find.textContaining('无法找回'), findsNothing);
    expect(find.text('恢复云端'), findsNothing);
    expect(find.text('覆盖上传'), findsOneWidget);

    await tester.tap(find.text('覆盖上传'));
    await tester.pumpAndSettle();

    expect(fake.uploadedContents, hasLength(1));
  });

  testWidgets('云端有文件但取不到修改时间:按未知告警', (tester) async {
    configure(lastSuccessMs: DateTime(2026, 1, 1).millisecondsSinceEpoch);
    fake.info = const WebDavFileInfo(exists: true); // 无 lastModified
    await pumpPage(tester);

    await tapBackup(tester);

    expect(find.textContaining('无法获取云端备份时间'), findsOneWidget);
    expect(find.text('仍要覆盖'), findsOneWidget);
    expect(find.text('恢复云端'), findsNothing); // 判不出新旧就不暗示某一侧
  });

  testWidgets('本机无成功记录而云端有文件:提示来源不明', (tester) async {
    configure();
    fake.info = WebDavFileInfo(exists: true, lastModified: DateTime(2026, 1, 1));
    await pumpPage(tester);

    await tapBackup(tester);

    expect(find.textContaining('本机没有成功备份记录'), findsOneWidget);
    expect(find.text('仍要覆盖'), findsOneWidget);
  });

}
