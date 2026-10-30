import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
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
      final l10n = AppLocalizations.of(context);
      final totalGold = ref.watch(currentUserTotalGoldProvider);
      return Tooltip(
        message: l10n.totalGold,
        child: AnimatedTextSwitcher(
          child: Text(
            totalGold.formatCompact(
              fractionDigits: 2,
              english: !context.isChineseLocale,
              traditional: context.isTraditionalChineseLocale,
            ),
            style: textStyle,
            key: ValueKey(totalGold),
          ),
        ),
      );
    },
  );

  static Widget currentUserLastOnline() => Consumer(
    builder: (context, ref, child) {
      final l10n = AppLocalizations.of(context);
      final lastOnline = ref.watch(currentUserLastOnlineProvider);
      return Tooltip(
        message: l10n.lastOnline,
        child: AnimatedTextSwitcher(
          child: Text(
            lastOnline.isEmpty ? '-' : '$lastOnline ago',
            style: textStyle,
            key: ValueKey(lastOnline),
          ),
        ),
      );
    },
  );

  static Widget currentUserDailyIncome() => Consumer(
    builder: (context, ref, child) {
      final l10n = AppLocalizations.of(context);
      final dailyIncome = ref.watch(dailyIncomeProvider).total;
      return Tooltip(
        message: l10n.dailyIncome,
        child: AnimatedTextSwitcher(
          child: Text(
            dailyIncome.formatCompact(
              fractionDigits: 2,
              english: !context.isChineseLocale,
              traditional: context.isTraditionalChineseLocale,
            ),
            style: textStyle,
            key: ValueKey(dailyIncome),
          ),
        ),
      );
    },
  );

  static Widget currentUserGp() => Consumer(
    builder: (context, ref, child) {
      final l10n = AppLocalizations.of(context);
      final gp = ref.watch(currentUserGpProvider);
      return Tooltip(
        message: l10n.gp,
        child: AnimatedTextSwitcher(
          child: Text(
            gp.toStringAsFixed(3),
            style: textStyle,
            key: ValueKey(gp),
          ),
        ),
      );
    },
  );

  static Widget currentUserGpCn() => Consumer(
    builder: (context, ref, child) {
      final l10n = AppLocalizations.of(context);
      final gpCN = ref.watch(currentUserGpCnProvider);
      return Tooltip(
        message: l10n.gpCN,
        child: AnimatedTextSwitcher(
          child: Text(
            gpCN.toStringAsFixed(3),
            style: textStyle,
            key: ValueKey(gpCN),
          ),
        ),
      );
    },
  );

  static Widget seasonIndicator(ValueListenable<SeasonRange?> notifier) =>
      SeasonIndicator(notifier: notifier);
}
