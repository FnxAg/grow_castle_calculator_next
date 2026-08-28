import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/app.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('gcc_widget_test');
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
  });

  testWidgets('应用可以挂载主界面', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
