import 'package:material_ui/material_ui.dart';

/// AppBar 显示当前页面底部的加载进度条
class LoadingIndicatorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LoadingIndicatorAppBar({super.key, 
    required this.bottom,
    required this.isLoading,
  });

  final PreferredSizeWidget? bottom;
  final bool isLoading;

  @override
  Size get preferredSize => Size.fromHeight(
    (bottom?.preferredSize.height ?? 0) + (isLoading ? 3.0 : 0),
  );

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return bottom ?? const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: 3.0,
          child: LinearProgressIndicator(minHeight: 3.0),
        ),
        ?bottom,
      ],
    );
  }
}
