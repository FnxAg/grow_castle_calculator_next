import 'package:material_ui/material_ui.dart';

class AppBarInfo extends StatelessWidget {
  /// AppBar 拼接信息
  const AppBarInfo({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Text(
              '  ·  ',
              style: const TextStyle(fontSize: 12.0),
            ),
          children[i],
        ],
      ],
    );
  }
}
