import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:material_ui/material_ui.dart';

/// 让页面在「当前用户的数据变了」时重新加载。
///
/// 废弃 UserPageScaffold 后页面 State 不再随用户名换 key 重建：PageView 保活
/// 的 tab、宽屏内层 Navigator 里已 push 的页面，在别处切换用户时都不会重新
/// mount，[State.initState] 里读到的仍是上一个用户的数据；按 id 缓存的
/// TextEditingController 更会把旧用户的输入写回新用户。
///
/// 覆盖两种情况：
/// - [InfoStore.currentUserNotifier]：切换/重命名用户；
/// - [InfoStore.dataVersionNotifier]：云端恢复/本地导入把当前用户的数据整体
///   换掉（用户名没变，只靠前者不会触发，缓存的输入框会留着恢复前的旧值）。
///
/// 用法：页面 State 混入本 mixin 并实现 [reloadForCurrentUser]，在其中丢弃旧
/// 的缓存状态并重新读取 store：
///
/// ```dart
/// class _FooPageState extends State<FooPage> with CurrentUserReload {
///   @override
///   void reloadForCurrentUser() => setState(_load);
/// }
/// ```
///
/// 两个 notifier 触发时 store 都已换完（前者排在 [_loadUserState] 所有字段之后，
/// 后者在 `reload()` 重载完之后），因此这里可以直接同步读。页面自身 State 被
/// 保留，需要连子组件 State 一起重建的（如 tab 里按字段名缓存了控制器）另行用
/// `KeyedSubtree` 包一层——key 里要同时带上用户名与 dataVersion。
mixin CurrentUserReload<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    final store = Stores.infoStore;
    store.currentUserNotifier.addListener(_handleStoreChanged);
    store.dataVersionNotifier.addListener(_handleStoreChanged);
  }

  @override
  void dispose() {
    final store = Stores.infoStore;
    store.currentUserNotifier.removeListener(_handleStoreChanged);
    store.dataVersionNotifier.removeListener(_handleStoreChanged);
    super.dispose();
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    setState(reloadForCurrentUser);
  }

  /// 当前用户的数据已整体换掉（切换/重命名用户，或云恢复/导入）：
  /// 丢弃按旧数据缓存的状态并重新加载
  void reloadForCurrentUser();
}
