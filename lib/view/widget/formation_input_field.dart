import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 阵容页卡片中的输入框（名称 / 等级）：左侧主题色描边 + 填充底色。
///
/// 控制器与焦点由页面 State 按卡片 id 缓存持有并负责释放，
/// 本组件只负责展示与输入行为，不做任何状态管理。
/// 聚焦时自动全选内容（见 SelectAllTextField）。
class FormationInputField extends StatelessWidget {
  const FormationInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.keyboardType,
    this.inputFormatters,
    required this.enabled,
    this.visualDisabled = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// 是否可编辑；与视觉禁用状态分离，允许“看起来禁用但依然可输入”。
  final bool enabled;

  /// 是否以禁用样式显示，且不影响实质可编辑状态。
  final bool visualDisabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVisualDisabled = visualDisabled || !enabled;

    return Container(
      decoration: BoxDecoration(
        color: isVisualDisabled
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primaryContainer,
        border: Border(
          left: BorderSide(
            color: isVisualDisabled ? colorScheme.outlineVariant : colorScheme.primary,
            width: 2.0,
          ),
        ),
      ),
      child: SelectAllTextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        obscureText: false,
        maxLines: 1,
        focusNode: focusNode,
        inputFormatters: inputFormatters,
        enabled: enabled,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: labelText,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          enabled: enabled,
          isDense: true,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
        ),
      ),
    );
  }
}
