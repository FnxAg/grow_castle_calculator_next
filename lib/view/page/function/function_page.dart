import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/navigation/app_navigator.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:material_ui/material_ui.dart';

/// 当前用户的功能页
class FunctionPage extends ConsumerWidget {
  const FunctionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    final appBarInfo = AppBarInfo(
      children: <Widget>[
        AppBarItem.currentUser(),
        AppBarItem.currentUserLastOnline(),
        AppBarItem.currentUserGuild(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(l10n.tabFunction), appBarInfo],
        ),
      ),
      body: ListView(
        padding: UIs.padding,
        children: [
          CardTile(
            leading: const Icon(Icons.castle),
            title: Text(l10n.tabFormation),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.openBuildCalc(),
          ),
          CardTile(
            leading: const Icon(Icons.bolt),
            title: Text(l10n.waveStatus),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.openWaveStatus(),
          ),
          CardTile(
            leading: const Icon(Icons.percent),
            title: Text(
              l10n.wavePushIncomeCalc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${ref.watch(currentUserGabBonusProvider).toStringAsFixed(2)}%',
                  style: style,
                ),
                const SizedBox(width: 4.0),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.openBonusGold(),
          ),
          CardTile(
            leading: const Icon(Icons.auto_graph),
            title: Text(
              l10n.tabIncome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ref
                      .watch(dailyIncomeProvider)
                      .total
                      .formatCompact(
                        fractionDigits: 2,
                        english: context.isCompactUnitEnglish,
                        traditional: context.isTraditionalChineseLocale,
                      ),
                  style: style,
                ),
                const SizedBox(width: 4.0),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.openIncome(),
          ),
          CardTile(
            leading: const Icon(Icons.trending_up),
            title: Text(l10n.incomeTrend),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.openIncomeTrend(),
          ),
          CardTile(
            leading: const Icon(Icons.timeline),
            title: Text(l10n.gameTrack),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.openGameTrack(),
          ),
        ],
      ),
    );
  }
}
