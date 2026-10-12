import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUserGuild extends ConsumerWidget {
  /// AppBar 显示当前用户所属公会
  ///
  /// fontSize: 12.0
  const CurrentUserGuild({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    final guild = ref.watch(currentUserGuildProvider);
    if (guild.isEmpty) return Text('-', style: textStyle);
    return Text(guild, style: textStyle);
  }
}
