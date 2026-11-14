import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/widget/card/card_field.dart';

/// 设置项通用编辑弹窗
class SettingEditDialog extends StatefulWidget {
  const SettingEditDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.labelText,
    this.helperText,
    required this.onSubmit,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.actionButtons = const [],
  });

  final String title;
  final String initialValue;
  final String? labelText;
  final String? helperText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool obscureText;
  final bool showVisibilityToggle;
  final ValueChanged<String> onSubmit;
  final List<Widget>? actionButtons;

  @override
  State<SettingEditDialog> createState() => _SettingEditDialogState();
}

class _SettingEditDialogState extends State<SettingEditDialog> {
  late final TextEditingController _controller;
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _obscured = widget.obscureText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: CardField(
        controller: _controller,
        title: widget.labelText,
        helperText: widget.helperText,
        autofocus: true,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        obscureText: _obscured,
        suffixIcon: widget.showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _obscured
                    ? l10n.tooltipShowPassword
                    : l10n.tooltipHidePassword,
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
      actions: [
        if (widget.actionButtons != null) ...widget.actionButtons!,
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () {
            widget.onSubmit(_controller.text);
            Navigator.of(context).pop();
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
