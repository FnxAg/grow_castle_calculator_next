import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsernameTextField extends StatelessWidget {
  const UsernameTextField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 1,
      maxLength: 14,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      autofocus: true,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-_ ]')),
      ],
      decoration: const InputDecoration(
        labelText: '用户名',
        helperText: '0-9, a-z, A-Z, -, _, space',
      ),
    );
  }
}
