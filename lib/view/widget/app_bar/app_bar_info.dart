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
    // AppBar 标题区宽度有限（还要让位给返回键与右侧按钮），而用户名/公会名/
    // 上次在线都是不定长文本，英文下更容易顶出去。用 FittedBox 在放不下时整体
    // 等比缩小：既不溢出也不换行（AppBar 高度固定，换行会纵向溢出）
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
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
      ),
    );
  }
}
