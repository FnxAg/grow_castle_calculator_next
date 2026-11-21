import 'package:grow_castle_calculator_next/view/shell/shell_transition.dart';
import 'package:material_ui/material_ui.dart';

/// 分支 Navigator 容器：全部 children 常驻，切换时旧页滑出、新页滑入
class ShellBranchContainer extends StatelessWidget {
  const ShellBranchContainer({super.key, required this.children});

  /// go_router 提供的分支 Navigator 代理，顺序与 branches 一致
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final transition = ShellTransitionScope.of(context);
    // 每帧 tick 只重建 Stack，不重建 Navigator 子树
    final branches = <Widget>[
      for (final child in children) RepaintBoundary(child: child),
    ];
    return ClipRect(
      child: AnimatedBuilder(
        animation: Listenable.merge([transition, transition.controller]),
        builder: (context, _) {
          final active = transition.activeIndex;
          final outgoing = transition.outgoingVisibleIndex;
          final t = transition.controller.value;
          final shift = transition.slideDirection * transition.pageWidth;
          return Stack(
            children: [
              for (var i = 0; i < branches.length; i++)
                Positioned.fill(
                  key: ValueKey(i),
                  child: Offstage(
                    offstage: i != active && i != outgoing,
                    child: IgnorePointer(
                      ignoring: i != active,
                      child: TickerMode(
                        enabled: i == active,
                        child: Transform.translate(
                          offset: i == active
                              ? (outgoing == null
                                    ? Offset.zero
                                    : Offset((1 - t) * shift, 0))
                              : i == outgoing
                              ? Offset(-t * shift, 0)
                              : Offset.zero,
                          child: branches[i],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
