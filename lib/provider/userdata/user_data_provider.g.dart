// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hive 网关。
///
/// 必须 keepAlive：它被 [Users] 用 `ref.read` 读取（不建立依赖边），
/// auto-dispose 的 provider 会在 [Users.build] 返回后立刻被销毁。

@ProviderFor(userDataRepository)
final userDataRepositoryProvider = UserDataRepositoryProvider._();

/// Hive 网关。
///
/// 必须 keepAlive：它被 [Users] 用 `ref.read` 读取（不建立依赖边），
/// auto-dispose 的 provider 会在 [Users.build] 返回后立刻被销毁。

final class UserDataRepositoryProvider
    extends
        $FunctionalProvider<
          UserDataRepository,
          UserDataRepository,
          UserDataRepository
        >
    with $Provider<UserDataRepository> {
  /// Hive 网关。
  ///
  /// 必须 keepAlive：它被 [Users] 用 `ref.read` 读取（不建立依赖边），
  /// auto-dispose 的 provider 会在 [Users.build] 返回后立刻被销毁。
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

/// 用户数据状态容器。
///
/// 方法名与旧 `InfoStore` 保持一致，视图层可以把 `store.setXxx` 的 tear-off
/// 直接换成 `ref.users.setXxx`（`Notifier` 实例在 provider 生命周期内被保留，
/// keepAlive 保证该生命周期等于容器）。

@ProviderFor(Users)
final usersProvider = UsersProvider._();

/// 用户数据状态容器。
///
/// 方法名与旧 `InfoStore` 保持一致，视图层可以把 `store.setXxx` 的 tear-off
/// 直接换成 `ref.users.setXxx`（`Notifier` 实例在 provider 生命周期内被保留，
/// keepAlive 保证该生命周期等于容器）。
final class UsersProvider extends $NotifierProvider<Users, UsersState> {
  /// 用户数据状态容器。
  ///
  /// 方法名与旧 `InfoStore` 保持一致，视图层可以把 `store.setXxx` 的 tear-off
  /// 直接换成 `ref.users.setXxx`（`Notifier` 实例在 provider 生命周期内被保留，
  /// keepAlive 保证该生命周期等于容器）。
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

String _$usersHash() => r'4d7d6ac57ee7c32d27d90e5ca1780af19aea0ea3';

/// 用户数据状态容器。
///
/// 方法名与旧 `InfoStore` 保持一致，视图层可以把 `store.setXxx` 的 tear-off
/// 直接换成 `ref.users.setXxx`（`Notifier` 实例在 provider 生命周期内被保留，
/// keepAlive 保证该生命周期等于容器）。

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

/// 数据整体替换计数。
///
/// 不可约：它存在的意义就是"值没变但世界变了"——云恢复/本地导入后用户名
/// 可能没变，靠 `select` 无法产生通知。

@ProviderFor(DataVersion)
final dataVersionProvider = DataVersionProvider._();

/// 数据整体替换计数。
///
/// 不可约：它存在的意义就是"值没变但世界变了"——云恢复/本地导入后用户名
/// 可能没变，靠 `select` 无法产生通知。
final class DataVersionProvider extends $NotifierProvider<DataVersion, int> {
  /// 数据整体替换计数。
  ///
  /// 不可约：它存在的意义就是"值没变但世界变了"——云恢复/本地导入后用户名
  /// 可能没变，靠 `select` 无法产生通知。
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

/// 数据整体替换计数。
///
/// 不可约：它存在的意义就是"值没变但世界变了"——云恢复/本地导入后用户名
/// 可能没变，靠 `select` 无法产生通知。

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

/// 各用户「上次在线」展示串（仅内存，不持久化）。
///
/// 语义与旧 `InfoStore._lastOnline` 一致：删除用户也不清除该用户 id 的条目。

@ProviderFor(LastOnlineByUser)
final lastOnlineByUserProvider = LastOnlineByUserProvider._();

/// 各用户「上次在线」展示串（仅内存，不持久化）。
///
/// 语义与旧 `InfoStore._lastOnline` 一致：删除用户也不清除该用户 id 的条目。
final class LastOnlineByUserProvider
    extends $NotifierProvider<LastOnlineByUser, Map<int, String>> {
  /// 各用户「上次在线」展示串（仅内存，不持久化）。
  ///
  /// 语义与旧 `InfoStore._lastOnline` 一致：删除用户也不清除该用户 id 的条目。
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

/// 各用户「上次在线」展示串（仅内存，不持久化）。
///
/// 语义与旧 `InfoStore._lastOnline` 一致：删除用户也不清除该用户 id 的条目。

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
