import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:material_ui/material_ui.dart';

class LastOnline extends ConsumerWidget {
  /// AppBar 显示当前用户上次在线时间
  ///
  /// fontSize: 12.0
  const LastOnline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    final lastOnline = ref.watch(currentUserLastOnlineProvider);
    if (lastOnline.isEmpty) return Text('-', style: textStyle);
    return Text('$lastOnline ago', style: textStyle);
  }
}
