import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/widget/income_switch_tile.dart';
import 'package:material_ui/material_ui.dart';

/// 收入来源「其他」tab
class OtherTab extends ConsumerWidget {
  const OtherTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    var otherIncomeWidgets = [
      IncomeSwitchTile(
        label: l10n.labelSeasonColony,
        value: ref.watch(currentUserProvider.select((u) => u.seasonColony)),
        onChanged: ref.users.setCurrentUserSeasonColony,
      ),
      IncomeSwitchTile(
        label: l10n.labelGoldenTree,
        value: ref.watch(currentUserProvider.select((u) => u.goldenTree)),
        onChanged: ref.users.setCurrentUserGoldenTree,
      ),
    ];
    return isMobile
        ? ListView(children: otherIncomeWidgets)
        : Column(children: otherIncomeWidgets);
  }
}
