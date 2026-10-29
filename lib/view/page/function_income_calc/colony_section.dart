import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_edit_tile.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_field.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

/// 收入来源「殖民地」
class ColonySection extends ConsumerWidget {
  const ColonySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final wave = ref.watch(currentUserWaveProvider);
    final infiniteColony = ref.watch(
      currentUserProvider.select((u) => u.infiniteColony),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IncomeEditTile(
          field: IncomeField.infiniteColony,
          titleTrailing: Tooltip(
            message: l10n.tooltipInfiniteColonyRatio,
            child: PillChip(
              text: Text(
                wave > 0 ? (infiniteColony / wave * 1000).format() : '0',
                style: PillChip.textStyle,
              ),
            ),
          ),
        ),
        const IncomeEditTile(field: IncomeField.icCooldown),
        const IncomeEditTile(field: IncomeField.icGold),
        SwitchListTile(
          title: Text(l10n.labelWheel),
          value: ref.watch(currentUserProvider.select((u) => u.equipWheel)),
          onChanged: ref.users.setCurrentUserEquipWheel,
        ),
        SwitchListTile(
          title: Text(l10n.labelWhip),
          value: ref.watch(currentUserProvider.select((u) => u.equipWhip)),
          onChanged: ref.users.setCurrentUserEquipWhip,
        ),
      ],
    );
  }
}
