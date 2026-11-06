import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/build_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_bonus_gold_calc/bonus_gold_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_game_track/game_track_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_trend/income_trend_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_wave_status/wave_status_page.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
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
        children: [
          ListTile(
            leading: const Icon(Icons.castle),
            title: Text(l10n.tabFormation),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BuildCalcPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bolt),
            title: Text(l10n.waveStatus),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WaveStatusPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.percent),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.wavePushIncomeCalc,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  '${ref.watch(currentUserGabBonusProvider).toStringAsFixed(2)}%',
                  style: style,
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BonusGoldCalcPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_graph),
            title: Row(
              children: [
                Expanded(
                  child: Text(l10n.tabIncome, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8.0),
                Text(
                  ref
                      .watch(dailyIncomeProvider)
                      .total
                      .formatCompact(
                        fractionDigits: 2,
                        english: !context.isChineseLocale,
                        traditional: context.isTraditionalChineseLocale,
                      ),
                  style: style,
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const IncomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text(l10n.incomeTrend),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IncomeTrendPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.timeline),
            title: Text(l10n.gameTrack),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const GameTrackPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
