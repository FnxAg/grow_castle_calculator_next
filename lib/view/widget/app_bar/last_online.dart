import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:material_ui/material_ui.dart';

class LastOnline extends StatelessWidget {
  /// AppBar 显示当前用户上次在线时间
  /// 
  /// fontSize: 12.0
  const LastOnline({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    return ListenableBuilder(
      listenable: Stores.infoStore.lastOnlineNotifier,
      builder: (context, _) {
        final lastOnline = Stores.infoStore.lastOnlineNotifier.value;
        if (lastOnline.isEmpty) return Text('-', style: textStyle);
        return Text('$lastOnline ago', style: textStyle);
      },
    );
  }
}
