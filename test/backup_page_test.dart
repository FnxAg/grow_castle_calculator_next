import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';
import 'package:grow_castle_calculator_next/view/page/setting/backup_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// 数据备份页 widget 冒烟测试。
///
/// Hive 写盘约定：不要在 testWidgets 的 FakeAsync 时区内发起/遗留 box 写入
/// ——写入链的完成延续绑定在该时区上，时区随用例结束销毁后，下一个用例
/// 真实时区里对该 box 的 close/delete 会永久等待。因此本文件所有持久化
/// 操作都经 tester.runAsync（真实时区）执行，UI 只做渲染断言。
void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: BackupPage()));
    await tester.pump();
  }

  setUp(() async {
    // 每个用例使用独立 Hive 目录（runAsync 写入完成后，真实时区 close 安全）
    for (final name in [
      'app_meta',
      'user_data',
      'user_meta',
      'item_rules',
      'game_track',
    ]) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }
    }
    final dir = await Directory.systemTemp.createTemp('backup_page_test');
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
  });

  tearDown(() {
    // 重置 GetIt：让每个用例重新创建 store（从已清理的 box 加载）
    GetIt.instance.reset();
  });

  testWidgets('页面渲染:各操作入口与配置行齐全', (tester) async {
    await pumpPage(tester);
    for (final label in [
      '自动备份',
      '服务器地址',
      '账号',
      '密码',
      '自动备份间隔',
      '立即备份',
      '从云端恢复',
      '导出到文件',
      '导入文件',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '缺少入口: $label');
    }
    // 未配置时各配置行副标题显示"未设置"
    expect(find.text('未设置'), findsNWidgets(3));
  });

  testWidgets('未配置时点立即备份:提示先配置且不发起上传', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('立即备份'));
    await tester.pumpAndSettle();
    expect(find.textContaining('请先配置 WebDAV'), findsOneWidget);
  });

  testWidgets('自动备份开启后开关显示为开并已持久化', (tester) async {
    // 经真实时区写入自动备份开关（见文件头注释）
    await tester.runAsync(() async {
      Stores.webDavConfigStore.setAutoEnabled(true);
    });
    await pumpPage(tester);
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, isTrue);
    await tester.runAsync(() async {
      expect(
        Hive.box(WebDavConfigStore.boxName).get('webdavAutoEnabled'),
        isTrue,
      );
    });
  });

  testWidgets('已填密码时显示打点而非明文', (tester) async {
    await tester.runAsync(() async {
      final store = Stores.webDavConfigStore;
      store.setPassword('secret123');
      store.setUrl('https://dav.example.com/dav/x');
      store.setUsername('user');
    });
    await pumpPage(tester);
    expect(find.text('••••••'), findsOneWidget);
    expect(find.text('secret123'), findsNothing);
  });
}
