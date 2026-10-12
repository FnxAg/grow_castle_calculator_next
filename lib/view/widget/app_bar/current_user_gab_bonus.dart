import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUserGabBonus extends ConsumerWidget {
  /// AppBar 显示当前用户收益
  ///
  /// fontSize: 12.0
  const CurrentUserGabBonus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    final bonusGold = ref.watch(currentUserGabBonusProvider);
    return Text('${bonusGold.toStringAsFixed(2)}%', style: textStyle);
  }
}
