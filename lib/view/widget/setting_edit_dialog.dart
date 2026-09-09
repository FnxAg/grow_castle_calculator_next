import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 设置项通用编辑弹窗：聚焦自动全选的输入框 + 取消/保存。
///
/// 自 setting_page.dart 私有 _SettingEditDialog 提取，供设置页与
/// 数据备份页共用。密码等敏感输入传 [obscureText]；再传
/// [showVisibilityToggle] 时输入框尾部提供明文/密文切换按钮。
class SettingEditDialog extends StatefulWidget {
  const SettingEditDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.decoration,
    required this.onSubmit,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.obscureText = false,
    this.showVisibilityToggle = false,
  });

  final String title;

  final String initialValue;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final InputDecoration decoration;

  /// 是否以密码形式输入（内容打点显示）
  final bool obscureText;

  /// 为 true 时在输入框尾部提供明文/密文切换按钮（与 [obscureText] 配合）
  final bool showVisibilityToggle;

  final ValueChanged<String> onSubmit;

  @override
  State<SettingEditDialog> createState() => _SettingEditDialogState();
}

class _SettingEditDialogState extends State<SettingEditDialog> {
  late final TextEditingController _controller;

  /// 当前是否密文显示（有显隐按钮时随点击切换）
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
    var decoration = widget.decoration;
    if (widget.showVisibilityToggle) {
      decoration = decoration.copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          tooltip: _obscured ? '显示' : '隐藏',
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      );
    }
    return AlertDialog(
      title: Text(widget.title),
      content: SelectAllTextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        obscureText: _obscured,
        decoration: decoration,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onSubmit(_controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
