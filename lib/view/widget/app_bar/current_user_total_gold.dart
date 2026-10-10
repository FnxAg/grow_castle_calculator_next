import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:material_ui/material_ui.dart';

class CurrentUserTotalGold extends ConsumerWidget {
  /// AppBar 显示当前用户总金币数
  ///
  /// fontSize: 12.0
  const CurrentUserTotalGold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    return Text(
      ref.watch(currentUserTotalGoldProvider).formatCompact(
            fractionDigits: 2,
            english: !context.isChineseLocale,
            traditional: context.isTraditionalChineseLocale,
          ),
      style: textStyle,
    );
  }
}
