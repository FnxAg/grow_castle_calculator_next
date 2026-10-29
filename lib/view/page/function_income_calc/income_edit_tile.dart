import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/model/userdata/user_data.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_field.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// 收入参数行：显示当前值，点击后弹出对话框编辑
class IncomeEditTile extends ConsumerWidget {
  const IncomeEditTile({super.key, required this.field, this.titleTrailing});

  final IncomeField field;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final error = field.error(user);
    final label = Text(field.label(l10n));
    return ListTile(
      title: titleTrailing == null
          ? label
          : Row(children: [label, const Spacer(), titleTrailing!]),
      subtitle: error == null
          ? null
          : Text(error, style: TextStyle(color: scheme.error)),
      trailing: Text(
        field.display(user),
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
      ),
      onTap: () => showIncomeEditDialog(
        context,
        field: field,
        user: user,
        onSave: (text) => field.save(ref.read(usersProvider.notifier), text),
      ),
    );
  }
}

/// 弹出数值编辑对话框，确认后把输入文本交给 [onSave]
Future<void> showIncomeEditDialog(
  BuildContext context, {
  required IncomeField field,
  required UserData user,
  required ValueChanged<String> onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _IncomeEditDialog(field: field, user: user, onSave: onSave),
  );
}

class _IncomeEditDialog extends StatefulWidget {
  const _IncomeEditDialog({
    required this.field,
    required this.user,
    required this.onSave,
  });

  final IncomeField field;
  final UserData user;
  final ValueChanged<String> onSave;

  @override
  State<_IncomeEditDialog> createState() => _IncomeEditDialogState();
}

class _IncomeEditDialogState extends State<_IncomeEditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.field.inputText(widget.user),
  );
  String? _error;

  @override
  void initState() {
    super.initState();
    // 附加按钮可能改写输入内容，用监听而不是 onChanged
    _controller.addListener(_clearError);
  }

  @override
  void dispose() {
    _controller.removeListener(_clearError);
    _controller.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _submit() {
    final field = widget.field;
    final text = _controller.text.trim();
    // 小数输入没有输入限制，需要自行校验
    if (!field.digitsOnly && text.isNotEmpty && double.tryParse(text) == null) {
      setState(() => _error = AppLocalizations.of(context).errorValueNotNumber);
      return;
    }
    final error = field.validate(widget.user, text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    widget.onSave(text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = widget.field;
    final extraContent = field.extraDialogContent(context, _controller);
    final extraActions = field.extraDialogActions(context, _controller);
    return AlertDialog(
      title: Text(field.label(l10n)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectAllTextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(
              decimal: !field.digitsOnly,
            ),
            inputFormatters: field.digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              prefixText: field.prefixText.isEmpty ? null : field.prefixText,
              suffixText: field.suffixText.isEmpty ? null : field.suffixText,
              errorText: _error,
            ),
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 12.0),
            extraContent,
          ],
        ],
      ),
      actions: [
        ...extraActions,
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }
}
