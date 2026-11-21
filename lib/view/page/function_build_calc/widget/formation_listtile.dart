import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/divider.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/navigation/app_navigator.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容页卡片行：点击进入编辑页
class FormationCardTile extends ConsumerWidget {
  const FormationCardTile({
    super.key,
    required this.id,
    required this.index,
  });

  final int id;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bool applied = ref.watch(applyFlagProvider(id));
    return CardTile(
      // 显式拖拽句柄，避免长按条目触发重排
      leading: ReorderableDragStartListener(
        index: index,
        child: CircleAvatar(
          radius: 14,
          backgroundColor: applied
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          child: Text(
            (index + 1).toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ),
      ),
      title: _summaryView(context, ref, applied),
      onTap: () => context.openFormationCard(id),
    );
  }

  Widget _summaryView(BuildContext context, WidgetRef ref, bool applied) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(textValueProvider(id));
    final level = int.tryParse(ref.watch(numberValueProvider(id))) ?? 0;
    final gold = ref.watch(unitGoldProvider(id));
    final totalGold = ref.watch(currentUserTotalGoldProvider);
    final wave = ref.watch(currentUserWaveProvider);
    final share = applied && totalGold > 0 ? gold / totalGold * 100 : 0.0;
    final oneOverRatio = level / wave;
    final ratio = 1 / oneOverRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isNotEmpty
                      ? name
                      : id == 1
                      ? l10n.unitNameCastle
                      : id == 2
                      ? l10n.unitNameTownArcher
                      : l10n.unitNameGeneric(id),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: UIs.cardTitleFontSize,
                    fontWeight: FontWeight.w600,
                    decoration: applied ? null : TextDecoration.lineThrough,
                    color: applied
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              AnimatedTextSwitcher(
                child: Text(
                  dividerText([
                    (level.format()),
                    (gold.formatCompact(
                      english: context.isCompactUnitEnglish,
                      traditional: context.isTraditionalChineseLocale,
                    )),
                  ]),
                  style: TextStyle(
                    fontSize: UIs.cardSubtitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: applied
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                  key: ValueKey('$level-$gold-${applied ? 1 : 0}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),
          Wrap(
            spacing: 2.0,
            runSpacing: 1.0,
            children: [
              Tooltip(
                message: l10n.metricShare,
                child: PillChip(
                  text: '${share.format(fractionDigits: 2)}%',
                  backgroundColor: applied ? null : theme.disabledColor,
                ),
              ),
              Tooltip(
                message: l10n.metricOneOverRatio,
                child: PillChip(
                  text: oneOverRatio.format(fractionDigits: 3),
                  backgroundColor: applied ? Colors.green : theme.disabledColor,
                ),
              ),
              Tooltip(
                message: l10n.metricRatio,
                child: PillChip(
                  text: ratio.format(fractionDigits: 2),
                  backgroundColor: applied
                      ? Colors.orange
                      : theme.disabledColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
