import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:grow_castle_calculator_next/app.dart';
import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  final container = ProviderContainer();
  await _init(container);
  final (lightDynamic, darkDynamic) = await _fetchDynamicColorSchemes();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(lightDynamic: lightDynamic, darkDynamic: darkDynamic),
    ),
  );
}

Future<void> _init(ProviderContainer container) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Failed to set high refresh rate: $e');
    }
  }
  await _initializeHive();
  await _initializeGetIt(container);
}

Future<void> _initializeHive() async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  Hive.init(dir.path);
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
  if (!Hive.isBoxOpen('game_track')) {
    await Hive.openBox('game_track');
  }
}

Future<void> _initializeGetIt(ProviderContainer container) async {
  final GetIt getIt = GetIt.instance;
  if (!getIt.isRegistered<AppSettingsStore>()) {
    getIt.registerSingleton<AppSettingsStore>(AppSettingsStore());
  }
  if (!getIt.isRegistered<BackupService>()) {
    getIt.registerSingleton<BackupService>(BackupService(container: container));
  }
}

Future<(ColorScheme?, ColorScheme?)> _fetchDynamicColorSchemes() async {
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette()
        .timeout(const Duration(milliseconds: 500));
    if (corePalette != null) {
      return (
        corePalette.toColorScheme(),
        corePalette.toColorScheme(brightness: Brightness.dark),
      );
    }
  } catch (e) {
    debugPrint('Failed to fetch dynamic colors: $e');
  }
  try {
    final accent = await DynamicColorPlugin.getAccentColor()
        .timeout(const Duration(milliseconds: 500));
    if (accent != null) {
      return (
        ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light),
        ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      );
    }
  } catch (e) {
    debugPrint('Failed to fetch accent color: $e');
  }
  return (null, null);
}
