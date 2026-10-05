import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 用户名/公会等短文本输入框：共用同一套输入约束
/// （单行、≤14 字符、仅允许 0-9 a-z A-Z - _ 空格），
/// 通过 [labelText]/[helperText] 区分用途。
/// 聚焦时自动全选内容（见 SelectAllTextField）。
class NameTextField extends StatelessWidget {
  const NameTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.helperText,
    this.autofocus = true,
  });

  final TextEditingController controller;

  /// 为空时取词条的「用户名」
  final String? labelText;

  /// 为空时取词条的输入约束提示
  final String? helperText;

  /// 弹窗中多个输入框同时使用时，仅第一个保持自动聚焦
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
