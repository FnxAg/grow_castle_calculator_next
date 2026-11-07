import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// 卡片输入框：标题与输入框都在卡片内
class CardField extends StatelessWidget {
  const CardField({
    super.key,
    required this.title,
    required this.controller,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
  });

  final String title;
  final TextEditingController controller;
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: UIs.cardMargin,
      color: ListTileTheme.of(context).tileColor,
      shape: UIs.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: UIs.cardFieldPadding,
        child: SelectAllTextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: UIs.cardFieldContentPadding,
            labelText: title,
            prefixText: prefixText,
            suffixText: suffixText,
            helperText: helperText,
            helperMaxLines: 2,
            errorText: errorText,
            errorMaxLines: 3,
          ),
        ),
      ),
    );
  }
}
