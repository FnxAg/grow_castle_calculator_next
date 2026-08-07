import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 首次聚焦即全选内容的输入框。
///
/// 首次获得焦点（点击或 autofocus）时自动全选现有内容，直接输入即可覆盖
/// 旧值；之后再次点击恢复 [TextField] 默认的光标行为。
/// 除首次全选外与 [TextField] 等价，参数原样透传。
class SelectAllTextField extends StatefulWidget {
  const SelectAllTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.maxLengthEnforcement,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final bool enabled;
  final bool autofocus;

  @override
  State<SelectAllTextField> createState() => _SelectAllTextFieldState();
}

class _SelectAllTextFieldState extends State<SelectAllTextField> {
  /// 未传入 [SelectAllTextField.focusNode] 时内部自建；传入时复用调用方的
  FocusNode? _internalFocusNode;

  /// 首次聚焦是否已执行过全选：只全选一次，之后点击恢复光标默认行为
  bool _selectedOnce = false;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  /// 首次获得焦点（点击/autofocus 都经由 FocusNode 通知）时全选当前内容，
  /// 之后聚焦不再处理，由 TextField 默认行为放置光标
  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_selectedOnce) {
      _selectedOnce = true;
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      // 不接管 onTap：首次聚焦由 FocusNode 监听覆盖，之后点击走默认光标行为
    );
  }
}
