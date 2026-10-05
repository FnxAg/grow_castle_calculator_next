import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// 收入页底部汇总条
class IncomeSummaryBar extends StatelessWidget {
  const IncomeSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: Stores.infoStore.incomeNotifier,
      builder: (context, _, _) {
        final l10n = AppLocalizations.of(context);
        final english = !context.isChineseLocale;
        final income = Stores.infoStore.getCurrentUserDailyIncomeBreakdown();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: SummaryCard(
            children: <Widget>[
              SummaryRow(
                leadingIcon: Icons.terrain,
                title: Text(l10n.tabIncomeColony),
                trailing: SummaryRowValueText(
                  text: income.colony.formatCompact(
                    fractionDigits: 2,
                    english: english,
                  ),
                ),
              ),
              SummaryRow(
                leadingIcon: Icons.bolt,
                title: Text(l10n.tabIncomeWave),
                trailing: SummaryRowValueText(
                  text: income.autoBattle.formatCompact(
                    fractionDigits: 2,
                    english: english,
                  ),
                ),
              ),
              SummaryRow(
                leadingIcon: Icons.park,
                title: Text(l10n.tabIncomeOther),
                trailing: SummaryRowValueText(
                  text: income.other.formatCompact(
                    fractionDigits: 2,
                    english: english,
                  ),
                ),
              ),
              SummaryRow(
                leadingIcon: Icons.monetization_on_outlined,
                title: Text(l10n.incomeTotal),
                trailing: SummaryRowValueText(
                  text: income.total.formatCompact(
                    fractionDigits: 2,
                    english: english,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
