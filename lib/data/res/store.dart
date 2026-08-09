import 'package:get_it/get_it.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/data/store/item_comparer_store.dart';
import 'package:grow_castle_calculator_next/data/store/item_rule_store.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';

abstract final class Stores {
  static final GetIt _getIt = GetIt.instance;

  static InfoStore get infoStore {
    if (!_getIt.isRegistered<InfoStore>()) {
      _getIt.registerSingleton<InfoStore>(InfoStore());
    }
    return _getIt<InfoStore>();
  }

  static AppSettingsStore get appSettingsStore {
    if (!_getIt.isRegistered<AppSettingsStore>()) {
      _getIt.registerSingleton<AppSettingsStore>(AppSettingsStore());
    }
    return _getIt<AppSettingsStore>();
  }

  static ItemRuleStore get itemRuleStore {
    if (!_getIt.isRegistered<ItemRuleStore>()) {
      _getIt.registerSingleton<ItemRuleStore>(ItemRuleStore());
    }
    return _getIt<ItemRuleStore>();
  }

  /// 装备对比页的输入数据（持久化于 app_meta box）
  static ItemComparerStore get itemComparerStore {
    if (!_getIt.isRegistered<ItemComparerStore>()) {
      _getIt.registerSingleton<ItemComparerStore>(ItemComparerStore());
    }
    return _getIt<ItemComparerStore>();
  }
}