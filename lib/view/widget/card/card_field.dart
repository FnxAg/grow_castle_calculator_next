import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

/// 卡片输入框：标题与输入框都在卡片内
class CardField extends StatefulWidget {
  const CardField({
    super.key,
    this.title,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.suffix,
    this.suffixIcon,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.showCounter = true,
  });

  final String? title;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final Widget? suffix;
  final Widget? suffixIcon;

  /// 输入框两侧的独立组件
  final Widget? leading;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// maxLength 不为空时是否显示右下角计数
  final bool showCounter;

  @override
  State<CardField> createState() => _CardFieldState();
}

class _CardFieldState extends State<CardField> {
  /// 未传入 [CardField.focusNode] 时内部自建；传入时复用调用方的
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
  /// 之后聚焦不再处理，由 TextField 默认行为放置光标。桌面端保持默认行为。
  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_selectedOnce && isMobile) {
      _selectedOnce = true;
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: UIs.cardFieldContentPadding,
        labelText: widget.title,
        hintText: widget.hintText,
        prefixText: widget.prefixText,
        suffixText: widget.suffixText,
        helperText: widget.helperText,
        helperMaxLines: 2,
        errorText: widget.errorText,
        errorMaxLines: 3,
        suffix: widget.suffix,
        suffixIcon: widget.suffixIcon,
        counterText: widget.showCounter ? null : '',
      ),
    );

    return Card(
      elevation: 0,
      margin: UIs.cardMargin,
      color: ListTileTheme.of(context).tileColor,
      shape: UIs.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: UIs.cardFieldPadding,
        child: widget.leading == null && widget.trailing == null
            ? field
            : Row(
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 8.0),
                  ],
                  Expanded(child: field),
                  ?widget.trailing,
                ],
              ),
      ),
    );
  }
}
