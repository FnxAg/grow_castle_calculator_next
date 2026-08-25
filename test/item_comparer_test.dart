import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/item_comparer_store.dart';
import 'package:grow_castle_calculator_next/view/page/tool/item_comparer.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUp(() async {
    // 整个测试文件共享一个 Hive 测试目录（testWidgets 的 FakeAsync 时区内
    // 不能关闭 box：close 等待的真实 I/O 永远无法完成，会挂起测试）
    if (!Hive.isBoxOpen(ItemComparerStore.boxName)) {
      final dir = await Directory.systemTemp.createTemp('item_comparer_test');
      Hive.init(dir.path);
      await Hive.openBox(ItemComparerStore.boxName);
    }
    // 清空上一个用例的持久化数据
    await Hive.box(ItemComparerStore.boxName)
        .delete(ItemComparerStore.itemComparerKey);
  });

  tearDown(() {
    // 重置 GetIt：让每个用例重新创建 store（从已清理的 box 加载）
    GetIt.instance.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    // 放大视口，让整个 ListView 都参与构建
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ItemComparerPage()));
  }

  testWidgets('存储中已有已选词条时，进入页面下拉框不崩溃', (tester) async {
    final store = Stores.itemComparerStore;
    store.baseAttack = '1000';
    store.increasedDmg = '500';
    // 覆盖三种选项：普通白词条 / Element Damage / More Dmg
    store.item1.addAll([
      ItemComparerLineInput(line: ItemLine.damagePercent, value: '10'),
      ItemComparerLineInput(isElementDamage: true, value: '12'),
      ItemComparerLineInput(isMoreDmg: true, value: '30'),
    ]);
    store.item2.add(
      ItemComparerLineInput(line: ItemLine.attackSpeed, value: '50'),
    );

    await pumpPage(tester);

    // 恢复过程中不应有断言异常（下拉框需与 items 中的选项匹配）
    expect(tester.takeException(), isNull);
    // 面板数值恢复
    expect(find.text('1000'), findsOneWidget);
    // 各词条选中项均显示（下拉框内部可能重复渲染，只断言存在）
    expect(find.text('Damage %'), findsAtLeastNWidgets(1));
    expect(find.text('Element Damage %'), findsAtLeastNWidgets(1));
    expect(find.text('More Dmg %'), findsAtLeastNWidgets(1));
    expect(find.text('Attack Speed %'), findsAtLeastNWidgets(1));
  });

  testWidgets('存储为空时进入页面正常（各补一条空词条行）', (tester) async {
    await pumpPage(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('选择词条类型'), findsNWidgets(2));
  });

  testWidgets('输入内容后写入 Hive，重新进入页面可恢复', (tester) async {
    await pumpPage(tester);

    // 修改面板第一个输入框（Base Attack）与第一个词条数值框
    await tester.enterText(find.byType(TextField).first, '4321');
    await tester.pump();

    // 存储已同步（Hive box 中已有数据）
    expect(Stores.itemComparerStore.baseAttack, '4321');
    final saved = Hive.box(ItemComparerStore.boxName)
        .get(ItemComparerStore.itemComparerKey) as String;
    expect(saved, contains('4321'));

    // 重新进入页面（销毁旧页面重建，模拟退出再进入）仍能恢复
    // （结果区表格也会显示 4321，因此只断言存在）
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: ItemComparerPage()));
    expect(find.text('4321'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}
