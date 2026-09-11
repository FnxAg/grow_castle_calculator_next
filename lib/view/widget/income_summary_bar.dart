import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';

/// 收入页底部汇总条
class IncomeSummaryBar extends StatelessWidget {
  const IncomeSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: Stores.infoStore.incomeNotifier,
      builder: (context, _, _) {
        final income = Stores.infoStore.getCurrentUserDailyIncomeBreakdown();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: SummaryCard(
            children: <Widget>[
              SummaryRow(
                leadingIcon: Icons.terrain,
                title: Text('殖民地'),
                trailing: SummaryRowValueText(
                  text: income.colony.formatCompact(
                    fractionDigits: 2,
                    english: false,
                  ),
                ),
              ),
              SummaryRow(
                leadingIcon: Icons.bolt,
                title: Text('推波'),
                trailing: SummaryRowValueText(
                  text: income.autoBattle.formatCompact(
                    fractionDigits: 2,
                    english: false,
                  ),
                ),
              ),
              SummaryRow(
                leadingIcon: Icons.park,
                title: Text('其他'),
                trailing: SummaryRowValueText(
                  text: income.other.formatCompact(
                    fractionDigits: 2,
                    english: false,
                  ),
                ),
              ),
              SummaryRow(
                leadingIcon: Icons.monetization_on_outlined,
                title: Text('总收入'),
                trailing: SummaryRowValueText(
                  text: income.total.formatCompact(
                    fractionDigits: 2,
                    english: false,
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
