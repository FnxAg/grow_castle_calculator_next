import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'package:grow_castle_calculator_next/app.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';


void main() async {
  await _init();

  runApp(const MyApp());
}

Future<void> _init() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    debugPrint('Failed to set high refresh rate: $e');
  }
  await _initializeHive();
  await _initializeGetIt();
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  if (!Hive.isBoxOpen('user_data')) {
    await Hive.openBox('user_data');
  }
  if (!Hive.isBoxOpen('user_meta')) {
    await Hive.openBox('user_meta');
  }
  if (!Hive.isBoxOpen('app_meta')) {
    await Hive.openBox('app_meta');
  }
  if (!Hive.isBoxOpen('item_rules')) {
    await Hive.openBox('item_rules');
  }
}

Future<void> _initializeGetIt() async {
  final GetIt getIt = GetIt.instance;
  if (!getIt.isRegistered<InfoStore>()) {
    getIt.registerSingleton<InfoStore>(InfoStore());
  }
  if (!getIt.isRegistered<AppSettingsStore>()) {
    getIt.registerSingleton<AppSettingsStore>(AppSettingsStore());
  }
}



