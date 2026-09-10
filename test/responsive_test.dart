import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/app.dart';
import 'package:grow_castle_calculator_next/view/page/function/track/game_track_chart_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool/dragon_simulator_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/responsive/content_frame.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 响应式基础设施测试：内容限宽容器 + 外壳的宽窄分支。
void main() {
  const contentKey = ValueKey('content');

  group('ContentFrame:限宽容器', () {
    Future<void> pumpFrame(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ContentFrame(child: SizedBox.expand(key: contentKey)),
        ),
      ));
    }

    testWidgets('宽视口:限宽到 contentMaxWidth 并水平居中', (tester) async {
      await pumpFrame(tester, 1200);

      final rect = tester.getRect(find.byKey(contentKey));
      expect(rect.width, Breakpoints.contentMaxWidth);
      expect(rect.left, (1200 - Breakpoints.contentMaxWidth) / 2);
    });

    testWidgets('窄视口:限宽不生效，内容铺满（结构保证，非分支判断）', (tester) async {
      await pumpFrame(tester, 400);

      expect(tester.getSize(find.byKey(contentKey)).width, 400);
    });

    testWidgets('maxWidth 传 null 表示不限宽', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ContentFrame(
            maxWidth: null,
            child: SizedBox.expand(key: contentKey),
          ),
        ),
      ));

      expect(tester.getSize(find.byKey(contentKey)).width, 1400);
    });
  });

  group('MainShell:宽窄外壳分支', () {
    setUpAll(() async {
      final directory = await Directory.systemTemp.createTemp('responsive_test');
      Hive.init(directory.path);
      for (final name in [
        'user_data',
        'user_meta',
        'app_meta',
        'item_rules',
        'game_track',
      ]) {
        await Hive.openBox(name);
      }
      // 主页各页 initState 里有平台通道调用（如设置页读应用版本号），
      // 在测试环境不会响应，先塞一份假数据
      PackageInfo.setMockInitialValues(
        appName: 'gcc_next',
        packageName: 'grow_castle_calculator_next',
        version: '1.5.4',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    Future<void> pumpApp(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MyApp());
      await tester.pump();
    }

    testWidgets('宽视口:用 NavigationRail，隐藏底部导航', (tester) async {
      await pumpApp(tester, const Size(1280, 720));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('窄视口:保持底部导航', (tester) async {
      await pumpApp(tester, const Size(400, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('阈值边界:840 宽即切换到 rail', (tester) async {
      await pumpApp(tester, const Size(Breakpoints.expanded, 720));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('宽屏:推页只盖内容区，rail 常驻，Esc 返回上一页', (tester) async {
      await pumpApp(tester, const Size(1280, 720));

      await tester.tap(find.byIcon(Icons.handyman));
      await tester.pumpAndSettle();
      await tester.tap(find.text('刷龙模拟器'));
      await tester.pumpAndSettle();

      // 子页推到内层 Navigator：只盖内容区，rail 保持可见可切
      expect(find.byType(DragonSimulatorPage), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);

      // Esc 返回工具列表
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DragonSimulatorPage), findsNothing);
      expect(find.text('刷龙模拟器'), findsOneWidget);
    });

    testWidgets('窄屏:推页全屏盖住底部导航（移动端行为不变的回归锚点）', (tester) async {
      await pumpApp(tester, const Size(400, 800));

      await tester.tap(find.byIcon(Icons.handyman));
      await tester.pumpAndSettle();
      await tester.tap(find.text('刷龙模拟器'));
      await tester.pumpAndSettle();

      // 窄屏无内层 Navigator：子页推到根，全屏覆盖（含底部导航）
      expect(find.byType(DragonSimulatorPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('isDesktopPlatform:平台判定', () {
    test('桌面三平台为真，移动与测试环境为假', () {
      expect(isDesktopPlatform(TargetPlatform.windows), isTrue);
      expect(isDesktopPlatform(TargetPlatform.macOS), isTrue);
      expect(isDesktopPlatform(TargetPlatform.linux), isTrue);
      expect(isDesktopPlatform(TargetPlatform.android), isFalse);
      expect(isDesktopPlatform(TargetPlatform.iOS), isFalse);
      // 无参数时取 defaultTargetPlatform：flutter test 下恒为 android
      expect(isDesktopPlatform(), isFalse);
    });
  });

  group('轨迹图表:2×2 网格', () {
    setUp(() async {
      // 普通 setUp 在真实时区运行：这里写盘不会毒化 testWidgets 的 FakeAsync
      await Hive.box('game_track').clear();
      await Hive.box('game_track').put('user_0', [
        {
          'id': 't1',
          'recordedAt': '2026-01-01T00:00:00',
          'wave': 100,
          'totalGold': 1000000.0,
          'gp': 1.0,
          'gpCN': 2.0,
        },
        {
          'id': 't2',
          'recordedAt': '2026-01-02T00:00:00',
          'wave': 200,
          'totalGold': 2000000.0,
          'gp': 1.5,
          'gpCN': 3.0,
        },
      ]);
    });

    Future<void> pumpChartPage(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: GameTrackChartPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('宽屏:4 张图 2×2 并排（前两张同高、后两张同高、两行上下排列）', (tester) async {
      await pumpChartPage(tester, const Size(1400, 900));

      final charts = find.byType(LineChart);
      expect(charts, findsNWidgets(4));
      final y0 = tester.getTopLeft(charts.at(0)).dy;
      final y1 = tester.getTopLeft(charts.at(1)).dy;
      final y2 = tester.getTopLeft(charts.at(2)).dy;
      final y3 = tester.getTopLeft(charts.at(3)).dy;
      expect(y1, y0); // 第一行并排
      expect(y3, y2); // 第二行并排
      expect(y2, greaterThan(y0)); // 两行上下排列
    });

    testWidgets('窄屏:4 张图纵排（高度依次递增）', (tester) async {
      // 视口加高，保证 4 张面板都进入 ListView 的可视构建区间
      await pumpChartPage(tester, const Size(500, 1600));

      final charts = find.byType(LineChart);
      expect(charts, findsNWidgets(4));
      final y0 = tester.getTopLeft(charts.at(0)).dy;
      final y1 = tester.getTopLeft(charts.at(1)).dy;
      final y2 = tester.getTopLeft(charts.at(2)).dy;
      final y3 = tester.getTopLeft(charts.at(3)).dy;
      expect(y1, greaterThan(y0));
      expect(y2, greaterThan(y1));
      expect(y3, greaterThan(y2));
    });
  });

  group('桌面平台根组件', () {
    setUpAll(() async {
      if (!Hive.isBoxOpen('app_meta')) {
        final directory =
            await Directory.systemTemp.createTemp('desktop_root_test');
        Hive.init(directory.path);
        for (final name in [
          'user_data',
          'user_meta',
          'app_meta',
          'item_rules',
          'game_track',
        ]) {
          await Hive.openBox(name);
        }
      }
      PackageInfo.setMockInitialValues(
        appName: 'gcc_next',
        packageName: 'grow_castle_calculator_next',
        version: '1.5.4',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    testWidgets('桌面端挂载根组件不抛异常且文本可选', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 默认 flutter test 下 defaultTargetPlatform 恒为 android，桌面专属的
      // 根级包裹不会被构建；用 debug 覆盖模拟桌面。**必须在测试体内复位**：
      // flutter_test 在测试体结束时校验 foundation 调试变量已还原，
      // 放到 tearDown 里复位会太晚（debugAssertAllFoundationVarsUnset 断言失败）
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.pumpWidget(const MyApp());
        await tester.pump();

        // SelectionArea 需要 Overlay 祖先：缺少时这里会是
        // "No Overlay widget found" 的断言异常
        expect(tester.takeException(), isNull);
        expect(find.byType(SelectionArea), findsOneWidget);
        // 宽屏外壳与文本可选共存
        expect(find.byType(NavigationRail), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
