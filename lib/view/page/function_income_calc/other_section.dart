import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:material_ui/material_ui.dart';

/// 收入来源「其他」
class OtherSection extends ConsumerWidget {
  const OtherSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(l10n.labelSeasonColony),
          value: ref.watch(currentUserProvider.select((u) => u.seasonColony)),
          onChanged: ref.users.setCurrentUserSeasonColony,
        ),
        SwitchListTile(
          title: Text(l10n.labelGoldenTree),
          value: ref.watch(currentUserProvider.select((u) => u.goldenTree)),
          onChanged: ref.users.setCurrentUserGoldenTree,
        ),
      ],
    );
  }
}
