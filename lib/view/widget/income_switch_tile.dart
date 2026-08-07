import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';

/// 收入页开关行：value 在 builder 内从 store 实时读取，
/// 由 incomeNotifier 驱动回显（切换后立即反映最新持久化值）。
class IncomeSwitchTile extends StatelessWidget {
  const IncomeSwitchTile({
    super.key,
    required this.label,
    required this.readValue,
    required this.onChanged,
  });

  final String label;

  /// 从 store 读取当前值（builder 每次重建时调用）
  final bool Function() readValue;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Stores.infoStore.incomeNotifier,
      builder: (context, _, _) => ListTile(
        title: Text(label),
        trailing: Switch(value: readValue(), onChanged: onChanged),
      ),
    );
  }
}
