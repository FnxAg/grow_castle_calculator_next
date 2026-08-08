import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grow_castle_calculator_next/core/src/item_display_rules.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';

/// 用户高亮规则存储（全局生效，与应用设置同级，Hive 持久化）
class ItemRuleStore {
  static const String _boxName = 'item_rules';
  static const String _rulesKey = 'rules';

  final Box _box;
  final ValueNotifier<List<UserHighlightRule>> rulesNotifier;

  ItemRuleStore()
      : _box = Hive.box(_boxName),
        rulesNotifier = ValueNotifier<List<UserHighlightRule>>(
          _load(Hive.box(_boxName)),
        );

  List<UserHighlightRule> get rules => rulesNotifier.value;

  /// 首次使用预置示例规则：白 cd + 红 cd + 加强
  static UserHighlightRule _exampleRule() => UserHighlightRule(
        id: 'example-red-white-quality',
        hint: '红白加强',
        lines: {
          ItemLine.cooldown: const LineCondition(),
          ItemLine.redCooldown: const LineCondition(),
          ItemLine.itemQuality: const LineCondition(),
        },
      );

  static List<UserHighlightRule> _load(Box box) {
    final raw = box.get(_rulesKey);
    if (raw is String && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      return [
        for (final entry in list)
          UserHighlightRule.fromJson(entry as Map<String, dynamic>),
      ];
    }
    // 未设置过（用户删空后已持久化空列表，不会重新预置）
    return [_exampleRule()];
  }

  void addRule(UserHighlightRule rule) {
    rulesNotifier.value = [...rules, rule];
    _persist();
  }

  void updateRule(UserHighlightRule rule) {
    rulesNotifier.value = [
      for (final r in rules) r.id == rule.id ? rule : r,
    ];
    _persist();
  }

  void removeRule(String id) {
    rulesNotifier.value = rules.where((r) => r.id != id).toList();
    _persist();
  }

  void _persist() {
    _box.put(_rulesKey, jsonEncode([for (final r in rules) r.toJson()]));
  }
}
