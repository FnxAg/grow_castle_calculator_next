import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/calc/gold_income.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

class IncomeTrendPage extends ConsumerStatefulWidget {
  const IncomeTrendPage({super.key});

  @override
  ConsumerState<IncomeTrendPage> createState() => _IncomeTrendPageState();
}

class _IncomeTrendPageState extends ConsumerState<IncomeTrendPage> {
  static int _selectedOptionIndex = 0;
  final List<int> _trendMinutesOptions = const [
    1440,
    10080,
    43200,
    129600,
    259200,
    525600,
  ];
  final List<String> _dropdownOptions = const [
    '24h',
    '7d',
    '30d',
    '90d',
    '180d',
    '365d',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    final afterTime = _trendMinutesOptions[_selectedOptionIndex];
    final user = ref.watch(currentUserProvider);
    final startWave = user.wave;
    final gabBonus = user.gabBonus;
    final gabTime = user.gabTime;
    final tabTime = user.tabTime;
    final wph = ref.watch(theoreticalWphProvider);
    final rwph = ref.watch(theoreticalRwphProvider);
    final passedWave = afterTime / 60 * wph * (gabTime + tabTime) / 24;
    final endWave = startWave + passedWave.toInt();
    final startWaveGabCost = gabCost(startWave);
    final endWaveGabCost = gabCost(endWave);
    final startWaveTotalGold = user.totalGold;
    final income = ref.watch(dailyIncomeProvider);
    final gabIncome =
        (startWaveGabCost + endWaveGabCost) /
        2 *
        gabBonus /
        100 *
        rwph *
        (afterTime / 60) *
        (gabTime / 24);
    final tabIncome =
        (startWaveGabCost + endWaveGabCost) /
        2 *
        (100 + gabBonus) /
        100 *
        rwph *
        (afterTime / 60) *
        (tabTime / 24);
    final waveIncome = gabIncome + tabIncome;
    final colonyIncome =
        income.colony * (afterTime / 1440) * (gabTime + tabTime) / 24;
    final otherIncome =
        income.other *
        (1 + (endWave - startWave) / startWave) *
        (afterTime / 1440) *
        (gabTime + tabTime) /
        24;
    final totalIncome = colonyIncome + otherIncome + waveIncome;
    final endWaveTotalGold = startWaveTotalGold + totalIncome;
    final startGp = user.gp;
    final startGpCN = user.gpCN;
    final endGp = calcGp(wave: endWave, gold: endWaveTotalGold);
    final endGpCN = calcGpCN(wave: endWave, gold: endWaveTotalGold);
    final goodColor = Colors.green;
    final badColor = Colors.red;

    final timeSelector = Wrap(
      alignment: .center,
      spacing: 8,
      runSpacing: 4,
      children: _trendMinutesOptions.map((minutes) {
        final index = _trendMinutesOptions.indexOf(minutes);
        final isSelected = index == _selectedOptionIndex;
        return ChoiceChip(
          label: Text(_dropdownOptions[index]),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedOptionIndex = index;
              });
            }
          },
        );
      }).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.incomeTrend), _AppBarInfo()],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: timeSelector),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(l10n.incomeTrendNow),
                SummaryCard(
                  children: [
                    SummaryRow(
                      leading: const Icon(Icons.waves),
                      title: Text(l10n.totalWave),
                      trailing: SummaryRow.text(startWave.format()),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.money),
                      title: Text(l10n.labelGabCost),
                      trailing: SummaryRow.text(
                        startWaveGabCost.formatCompact(
                          english: english,
                          traditional: traditional,
                        ),
                      ),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.monetization_on),
                      title: Text(l10n.totalGold),
                      trailing: SummaryRow.text(
                        startWaveTotalGold.formatCompact(
                          english: english,
                          traditional: traditional,
                        ),
                      ),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.star),
                      title: Text(l10n.gp),
                      trailing: SummaryRow.text(
                        startGp.format(fractionDigits: 3),
                      ),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.star),
                      title: Text(l10n.gpCN),
                      trailing: SummaryRow.text(
                        startGpCN.format(fractionDigits: 3),
                      ),
                    ),
                  ],
                ),
                SectionHeader(l10n.incomeTrendEnd),
                SummaryCard(
                  children: [
                    SummaryRow(
                      leading: const Icon(Icons.waves),
                      title: Text(l10n.totalWave),
                      trailing: Row(
                        children: [
                          PillChip(
                            leading: Icon(
                              Icons.arrow_upward,
                              size: PillChip.leadingIconSize,
                            ),
                            text: passedWave.format(),
                          ),
                          const SizedBox(width: 8),
                          SummaryRow.text(endWave.format()),
                        ],
                      ),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.money),
                      title: Text(l10n.labelGabCost),
                      trailing: Row(
                        children: [
                          PillChip(
                            leading: Icon(
                              Icons.arrow_upward,
                              size: PillChip.leadingIconSize,
                            ),
                            text: (endWaveGabCost - startWaveGabCost)
                                .formatCompact(
                                  english: english,
                                  traditional: traditional,
                                ),
                          ),
                          const SizedBox(width: 8),
                          SummaryRow.text(
                            endWaveGabCost.formatCompact(
                              english: english,
                              traditional: traditional,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.monetization_on),
                      title: Text(l10n.totalGold),
                      trailing: Row(
                        children: [
                          PillChip(
                            leading: Icon(
                              Icons.arrow_upward,
                              size: PillChip.leadingIconSize,
                            ),
                            text: totalIncome.formatCompact(
                              english: english,
                              traditional: traditional,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SummaryRow.text(
                            endWaveTotalGold.formatCompact(
                              english: english,
                              traditional: traditional,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.star),
                      title: Text(l10n.gp),
                      trailing: Row(
                        children: [
                          PillChip(
                            leading: Icon(
                              endGp - startGp < 0
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: PillChip.leadingIconSize,
                            ),
                            text: (endGp - startGp).abs().format(
                              fractionDigits: 3,
                            ),
                            backgroundColor: (endGp - startGp) >= 0
                                ? goodColor
                                : badColor,
                          ),
                          const SizedBox(width: 8),
                          SummaryRow.text(endGp.format(fractionDigits: 3)),
                        ],
                      ),
                    ),
                    SummaryRow(
                      leading: const Icon(Icons.star),
                      title: Text(l10n.gpCN),
                      trailing: Row(
                        children: [
                          PillChip(
                            leading: Icon(
                              endGpCN - startGpCN < 0
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: PillChip.leadingIconSize,
                            ),
                            text: (endGpCN - startGpCN).abs().format(
                              fractionDigits: 3,
                            ),
                            backgroundColor: (endGpCN - startGpCN) >= 0
                                ? goodColor
                                : badColor,
                          ),
                          const SizedBox(width: 8),
                          SummaryRow.text(endGpCN.format(fractionDigits: 3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.dataDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[
      AppBarItem.currentUser(),
      AppBarItem.currentUserGabBonus(),
    ];
    return AppBarInfo(children: segments);
  }
}
