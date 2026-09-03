import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/income_switch_tile.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 收入来源「殖民地」tab：殖民地等级/额外殖民地与装备输入。
///
/// 输入实时写入 store（data 字段持久化），结果汇总见页面底部 IncomeSummaryBar。
class ColonyTab extends StatefulWidget {
  const ColonyTab({super.key});

  @override
  State<ColonyTab> createState() => _ColonyTabState();
}

class _ColonyTabState extends State<ColonyTab> {
  final Map<String, TextEditingController> _controllers = {};

  /// 整数输入框控制器：创建时带 store 持久化初值，
  /// 编辑实时写入 store（空/非法输入回退 0）
  TextEditingController _intController(
    String key,
    int value,
    ValueChanged<int> onSave,
  ) {
    return _controllers.putIfAbsent(key, () {
      final c = TextEditingController(text: '$value');
      c.addListener(() => onSave(int.tryParse(c.text) ?? 0));
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
          title: Row(
            children: [
              const Text('殖民地等级'),
              const Spacer(),
              ValueListenableBuilder<int>(
                valueListenable: Stores.infoStore.incomeNotifier,
                builder: (context, _, _) {
                  final style = Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      );
                  final wave = store.getCurrentUserWave();
                  final value = wave > 0
                      ? (store.getCurrentUserInfiniteColony() / wave * 1000)
                            .format()
                      : '0';
                  return Text(value, style: style);
                },
              ),
            ],
          ),
          trailing: SizedBox(
            width: 80,
            child: SelectAllTextField(
              controller: _intController(
                'infiniteColony',
                store.getCurrentUserInfiniteColony(),
                store.setCurrentUserInfiniteColony,
              ),
              decoration: const InputDecoration(
                isDense: true,
                prefixText: 'Lv.',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
        ListTile(
          title: const Text('额外殖民地C'),
          trailing: SizedBox(
            width: 80,
            child: SelectAllTextField(
              controller: _intController(
                'icCooldown',
                store.getCurrentUserIcCooldown(),
                store.setCurrentUserIcCooldown,
              ),
              decoration: const InputDecoration(isDense: true),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
        ListTile(
          title: const Text('额外殖民地G'),
          trailing: SizedBox(
            width: 80,
            child: SelectAllTextField(
              controller: _intController(
                'icGold',
                store.getCurrentUserIcGold(),
                store.setCurrentUserIcGold,
              ),
              decoration: const InputDecoration(isDense: true),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
        IncomeSwitchTile(
          label: '车轮',
          readValue: store.getCurrentUserEquipWheel,
          onChanged: store.setCurrentUserEquipWheel,
        ),
        IncomeSwitchTile(
          label: '鞭子',
          readValue: store.getCurrentUserEquipWhip,
          onChanged: store.setCurrentUserEquipWhip,
        ),
      ],
    );
  }
}
