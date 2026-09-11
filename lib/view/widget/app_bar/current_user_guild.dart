import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUserGuild extends StatelessWidget {
  /// AppBar 显示当前用户所属公会
  /// 
  /// fontSize: 12.0
  const CurrentUserGuild({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    return ListenableBuilder(
      listenable: Stores.infoStore.guildNotifier,
      builder: (context, _) {
        final guild = Stores.infoStore.guildNotifier.value;
        if (guild.isEmpty) return Text('-', style: textStyle);
        return Text(guild, style: textStyle);
      },
    );
  }
}
