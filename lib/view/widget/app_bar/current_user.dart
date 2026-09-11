import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUser extends StatelessWidget {
  /// AppBar 显示当前用户名
  /// 
  /// fontSize: 12.0
  const CurrentUser({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    return ListenableBuilder(
      listenable: Stores.infoStore.currentUserNotifier,
      builder: (context, _) {
        final currentUser = Stores.infoStore.getCurrentUsername();
        return Text(currentUser, style: textStyle);
      },
    );
  }
}