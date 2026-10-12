import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUser extends ConsumerWidget {
  /// AppBar 显示当前用户名
  ///
  /// fontSize: 12.0
  const CurrentUser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    return Text(ref.watch(currentUsernameProvider), style: textStyle);
  }
}
