import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容页底部汇总条
class FormationSummaryBar extends ConsumerWidget {
  const FormationSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDefaultUser = ref.watch(currentUserIdProvider) == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: SummaryCard(
        children: <Widget>[
          SummaryRow(
            leading: Icon(Icons.emoji_events),
            title: Text(l10n.totalWave),
            actions: [
              if (isDefaultUser)
                _SmallIconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.tooltipEditTotalWave,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    showWaveEditDialog(
                      context,
                      title: l10n.dialogSetTotalWave,
                      labelText: l10n.totalWave,
                      fallback: 1,
                      onSave: ref.users.setUserWave,
                    );
                  },
                ),
            ],
            trailing: SummaryRowValueText(
              text: ref.watch(currentUserWaveProvider).format(),
            ),
          ),
          SummaryRow(
            leading: Icon(Icons.eco),
            title: Text(l10n.seasonWave),
            actions: [
              if (isDefaultUser)
                _SmallIconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.tooltipEditSeasonWave,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    showWaveEditDialog(
                      context,
                      title: l10n.dialogSetSeasonWave,
                      labelText: l10n.seasonWave,
                      fallback: 0,
                      onSave: ref.users.setCurrentUserSeasonWave,
                    );
                  },
                ),
            ],
            trailing: SummaryRowValueText(
              text: ref.watch(currentUserSeasonWaveProvider).format(),
            ),
          ),
          SummaryRow(
            leading: Icon(Icons.monetization_on),
            title: Text(l10n.totalGold),
            trailing: SummaryRowValueText(
              text: ref
                  .watch(currentUserTotalGoldProvider)
                  .formatCompact(
                    fractionDigits: 2,
                    english: !context.isChineseLocale,
                    traditional: context.isTraditionalChineseLocale,
                  ),
            ),
          ),
          SummaryRow(
            leading: Icon(Icons.star),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(l10n.goldPower)],
            ),
            trailing: SummaryRowValueText(
              text:
                  '${ref.watch(currentUserGpProvider).format(fractionDigits: 3)}'
                  ' · '
                  '${ref.watch(currentUserGpCnProvider).format(fractionDigits: 3)}',
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showWaveEditDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required int fallback,
  required ValueChanged<int> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _WaveEditDialog(
      title: title,
      labelText: labelText,
      fallback: fallback,
      onSave: onSave,
    ),
  );
}

class _WaveEditDialog extends StatefulWidget {
  const _WaveEditDialog({
    required this.title,
    required this.labelText,
    required this.fallback,
    required this.onSave,
  });

  final String title;
  final String labelText;

  final int fallback;
  final ValueChanged<int> onSave;

  @override
  State<_WaveEditDialog> createState() => _WaveEditDialogState();
}

class _WaveEditDialogState extends State<_WaveEditDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SelectAllTextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.labelText,
          helperText: '0-9',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).actionCancel),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? widget.fallback;
            widget.onSave(value);
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).actionSave),
        ),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: IconButton(
        icon: icon,
        iconSize: 20.0,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: Theme.of(context).colorScheme.primary,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
