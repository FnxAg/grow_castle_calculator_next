import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/widget/card/card_field.dart';
import 'package:material_ui/material_ui.dart';

/// 卡片搜索框：搜索图标 + 输入框 + 一键清空
class CardSearchField extends StatelessWidget {
  const CardSearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CardField(
      controller: controller,
      hintText: hintText ?? l10n.labelName,
      autofocus: autofocus,
      maxLength: 14,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      showCounter: false,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-_ ]')),
      ],
      leading: const Icon(Icons.search),
      trailing: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => controller.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: l10n.actionClear,
                visualDensity: VisualDensity.compact,
                iconSize: 20.0,
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
              ),
      ),
    );
  }
}
