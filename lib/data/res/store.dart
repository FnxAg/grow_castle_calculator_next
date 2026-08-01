import 'package:get_it/get_it.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';

abstract final class Stores {
  static final GetIt _getIt = GetIt.instance;

  static InfoStore get infoStore {
    if (!_getIt.isRegistered<InfoStore>()) {
      _getIt.registerSingleton<InfoStore>(InfoStore());
    }
    return _getIt<InfoStore>();
  }
}