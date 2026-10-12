import 'package:material_ui/material_ui.dart';

/// 收入页开关行
class IncomeSwitchTile extends StatelessWidget {
  const IncomeSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
