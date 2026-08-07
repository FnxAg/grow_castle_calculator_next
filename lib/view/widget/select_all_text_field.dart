import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 点击即全选内容的输入框。
///
/// 数值输入场景（等级/时间/百分比）常用：用户点一下全选，直接输入即可覆盖
/// 旧值，无需手动删除。已聚焦后再点同样重新全选。
class SelectAllTextField extends StatelessWidget {
  const SelectAllTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: decoration,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      // 点击（含已聚焦后再点）都全选现有内容，直接输入即覆盖
      onTap: () {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      },
    );
  }
}
