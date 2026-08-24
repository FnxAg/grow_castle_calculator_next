import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 收入来源「推波」tab：金挂/时挂时长与收益输入。
///
/// 输入实时写入 store（data 字段持久化），结果汇总见页面底部 IncomeSummaryBar。
class WaveTab extends StatefulWidget {
  const WaveTab({super.key});

  @override
  State<WaveTab> createState() => _WaveTabState();
}

class _WaveTabState extends State<WaveTab> {
  final Map<String, TextEditingController> _controllers = {};

  /// 双精度输入框控制器：创建时带 store 持久化初值，
  /// 编辑实时写入 store（空/非法输入回退 0）
  TextEditingController _doubleController(
    String key,
    double value,
    ValueChanged<double> onSave,
  ) {
    return _controllers.putIfAbsent(key, () {
      final c = TextEditingController(
        text: value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toString(),
      );
      c.addListener(() => onSave(double.tryParse(c.text) ?? 0.0));
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Stores.infoStore;
    return ListView(
      children: [
        ListTile(
          title: const Text('每日金挂时间'),
          trailing: SizedBox(
            width: 80,
            child: SelectAllTextField(
              controller: _doubleController(
                'gabTime',
                store.getCurrentUserGabTime(),
                store.setCurrentUserGabTime,
              ),
              decoration: const InputDecoration(isDense: true, suffixText: 'h'),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
        ListTile(
          title: const Text('金挂平均收益'),
          trailing: SizedBox(
            width: 80,
            child: SelectAllTextField(
              controller: _doubleController(
                'gabBonus',
                store.getCurrentUserGabBonus(),
                store.setCurrentUserGabBonus,
              ),
              decoration: const InputDecoration(isDense: true, suffixText: '%'),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
        ListTile(
          title: const Text('每日时挂时间'),
          trailing: SizedBox(
            width: 80,
            child: SelectAllTextField(
              controller: _doubleController(
                'tabTime',
                store.getCurrentUserTabTime(),
                store.setCurrentUserTabTime,
              ),
              decoration: const InputDecoration(isDense: true, suffixText: 'h'),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      ],
    );
  }
}
