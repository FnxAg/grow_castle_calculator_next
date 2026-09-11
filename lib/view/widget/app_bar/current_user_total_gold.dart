import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUserTotalGold extends StatelessWidget {
  /// AppBar 显示当前用户总金币数
  ///
  /// fontSize: 12.0
  const CurrentUserTotalGold({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    return ValueListenableBuilder(
      valueListenable: Stores.infoStore.totalGoldNotifier,
      builder: (context, totalGold, _) {
        return Text(
          totalGold.formatCompact(fractionDigits: 2, english: false),
          style: textStyle,
        );
      },
    );
  }
}
