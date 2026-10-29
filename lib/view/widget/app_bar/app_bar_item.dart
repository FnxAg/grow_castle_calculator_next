import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/season_indicator.dart';
import 'package:material_ui/material_ui.dart';

abstract class AppBarItem extends ConsumerWidget {
  const AppBarItem({super.key});

  static const TextStyle textStyle = TextStyle(fontSize: 12.0);

  static Widget currentUser() => Consumer(
    builder: (context, ref, child) {
      final username = ref.watch(currentUsernameProvider);
      return Text(username, style: textStyle);
    },
  );

  static Widget currentUserGabBonus() => Consumer(
    builder: (context, ref, child) {
      final bonusGold = ref.watch(currentUserGabBonusProvider);
      return Text('${bonusGold.toStringAsFixed(2)}%', style: textStyle);
    },
  );

  static Widget currentUserGuild() => Consumer(
    builder: (context, ref, child) {
      final guild = ref.watch(currentUserGuildProvider);
      if (guild.isEmpty) return Text('-', style: textStyle);
      return Text(guild, style: textStyle);
    },
  );

  static Widget currentUserTotalGold() => Consumer(
    builder: (context, ref, child) {
      final totalGold = ref.watch(currentUserTotalGoldProvider);
      return Text(
        totalGold.formatCompact(
          fractionDigits: 2,
          english: !context.isChineseLocale,
          traditional: context.isTraditionalChineseLocale,
        ),
        style: textStyle,
      );
    },
  );

  static Widget currentUserLastOnline() => Consumer(
    builder: (context, ref, child) {
      final lastOnline = ref.watch(currentUserLastOnlineProvider);
      if (lastOnline.isEmpty) return Text('-', style: textStyle);
      return AnimatedTextSwitcher(
        child: Text(
          '$lastOnline ago',
          style: textStyle,
          key: ValueKey(lastOnline),
        ),
      );
    },
  );

  static Widget seasonIndicator(ValueListenable<SeasonRange?> notifier) =>
      SeasonIndicator(notifier: notifier);
}
