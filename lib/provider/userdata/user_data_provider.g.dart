// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hive 网关

@ProviderFor(userDataRepository)
final userDataRepositoryProvider = UserDataRepositoryProvider._();

/// Hive 网关

final class UserDataRepositoryProvider
    extends
        $FunctionalProvider<
          UserDataRepository,
          UserDataRepository,
          UserDataRepository
        >
    with $Provider<UserDataRepository> {
  /// Hive 网关
  UserDataRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDataRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDataRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserDataRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserDataRepository create(Ref ref) {
    return userDataRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserDataRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserDataRepository>(value),
    );
  }
}

String _$userDataRepositoryHash() =>
    r'9e113205072e90b9bcef1d1ad358f9d9b1a18287';

/// 用户数据状态容器

@ProviderFor(Users)
final usersProvider = UsersProvider._();

/// 用户数据状态容器
final class UsersProvider extends $NotifierProvider<Users, UsersState> {
  /// 用户数据状态容器
  UsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usersHash();

  @$internal
  @override
  Users create() => Users();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsersState>(value),
    );
  }
}

String _$usersHash() => r'e3b88b96c7e802af09d0ee83c7f9f2f7e396559b';

/// 用户数据状态容器

abstract class _$Users extends $Notifier<UsersState> {
  UsersState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UsersState, UsersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UsersState, UsersState>,
              UsersState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 数据整体替换计数

@ProviderFor(DataVersion)
final dataVersionProvider = DataVersionProvider._();

/// 数据整体替换计数
final class DataVersionProvider extends $NotifierProvider<DataVersion, int> {
  /// 数据整体替换计数
  DataVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataVersionHash();

  @$internal
  @override
  DataVersion create() => DataVersion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$dataVersionHash() => r'9c3dfdcbd8ef7cf72d3e636a0d28633842c381dc';

/// 数据整体替换计数

abstract class _$DataVersion extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 各用户「上次在线」展示串

@ProviderFor(LastOnlineByUser)
final lastOnlineByUserProvider = LastOnlineByUserProvider._();

/// 各用户「上次在线」展示串
final class LastOnlineByUserProvider
    extends $NotifierProvider<LastOnlineByUser, Map<int, String>> {
  /// 各用户「上次在线」展示串
  LastOnlineByUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastOnlineByUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastOnlineByUserHash();

  @$internal
  @override
  LastOnlineByUser create() => LastOnlineByUser();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, String>>(value),
    );
  }
}

String _$lastOnlineByUserHash() => r'e7658b5354753ba2064966d795847ecc020cd020';

/// 各用户「上次在线」展示串

abstract class _$LastOnlineByUser extends $Notifier<Map<int, String>> {
  Map<int, String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<int, String>, Map<int, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, String>, Map<int, String>>,
              Map<int, String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
