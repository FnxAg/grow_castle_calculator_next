import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUserGabBonus extends StatelessWidget {
  /// AppBar 显示当前用户收益
  ///
  /// fontSize: 12.0
  const CurrentUserGabBonus({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Stores.infoStore.gabBonusNotifier,
      builder: (context, bonusGold, _) {
        final TextStyle textStyle = const TextStyle(fontSize: 12.0);
        return Text('${bonusGold.toStringAsFixed(2)}%', style: textStyle);
      },
    );
  }
}
