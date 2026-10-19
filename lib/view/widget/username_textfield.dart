import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 用户名/公会输入框
class NameTextField extends StatelessWidget {
  const NameTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.helperText,
    this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SelectAllTextField(
      controller: controller,
      maxLines: 1,
      maxLength: 14,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      autofocus: autofocus,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-_ ]')),
      ],
      decoration: InputDecoration(
        labelText: labelText ?? l10n.labelUsername,
        helperText: helperText ?? l10n.labelUsernameHint,
      ),
    );
  }
}
