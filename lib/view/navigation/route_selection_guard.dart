import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// 非当前路由退出文本选择。
///
/// Overlay 不布局被 opaque 路由盖住的下层路由，其文本若仍注册到
/// SelectionArea，选区排序取 boundingBoxes 会命中未布局断言。
class RouteSelectionGuardTransitions extends PageTransitionsTheme {
  const RouteSelectionGuardTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return super.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      _RouteSelectionScope(enabled: route.isCurrent, child: child),
    );
  }
}

class _RouteSelectionScope extends StatelessWidget {
  const _RouteSelectionScope({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static const SelectionRegistrar _disabledRegistrar =
      _NoopSelectionRegistrar();

  @override
  Widget build(BuildContext context) {
    final registrar = SelectionContainer.maybeOf(context);
    // 始终包一层同类型作用域，启用状态变化时页面子树不重建
    return SelectionRegistrarScope(
      registrar: enabled && registrar != null ? registrar : _disabledRegistrar,
      child: child,
    );
  }
}

/// 只接收注册、不参与选区计算的占位 registrar
class _NoopSelectionRegistrar implements SelectionRegistrar {
  const _NoopSelectionRegistrar();

  @override
  void add(Selectable selectable) {}

  @override
  void remove(Selectable selectable) {}
}
