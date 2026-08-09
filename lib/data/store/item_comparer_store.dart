import 'dart:convert';

import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 装备对比页的一条词条输入（词条类型 + 数值文本）
class ItemComparerLineInput {
  ItemComparerLineInput({
    this.line,
    this.isMoreDmg = false,
    this.isElementDamage = false,
    this.value = '',
  });

  /// 已选择的词条类型；null 表示尚未选择
  ItemLine? line;

  /// 是否为 More Dmg 词条（白词条池中没有 More Dmg，作为特殊选项）
  bool isMoreDmg;

  /// 是否为 Element Damage 词条（5 种元素伤害的整合项）
  bool isElementDamage;

  /// 数值输入框的文本（原样保存，避免解析后丢失格式）
  String value;

  Map<String, dynamic> toJson() => {
        'line': line?.name,
        'isMoreDmg': isMoreDmg,
        'isElementDamage': isElementDamage,
        'value': value,
      };

  /// 词条名非法（词条池调整过）时按未选择处理
  static ItemComparerLineInput fromJson(Map<String, dynamic> json) {
    final lineName = json['line'];
    return ItemComparerLineInput(
      line: lineName is String
          ? ItemLine.values.where((l) => l.name == lineName).firstOrNull
          : null,
      isMoreDmg: json['isMoreDmg'] as bool? ?? false,
      isElementDamage: json['isElementDamage'] as bool? ?? false,
      value: json['value'] as String? ?? '',
    );
  }
}

/// 装备对比页的输入数据（Hive 持久化）。
///
/// 装备对比是应用级工具数据，与当前用户无关，复用应用设置的 app_meta box
/// （key 为 [itemComparerKey]，与 AppSettingsStore 的其他 key 互不冲突）。
class ItemComparerStore {
  /// 与 AppSettingsStore 共用同一个 box，避免按功能无限新增 box
  static const String boxName = 'app_meta';
  static const String itemComparerKey = 'item_comparer';

  final Box _box = Hive.box(boxName);

  /// 无装备面板各输入框的文本
  String baseAttack = '';
  String increasedDmg = '';
  String moreDmg = '';
  String critChance = '';
  String critDmg = '';
  String baseAps = '';
  String speed = '';

  /// 两件装备的词条输入（词条类型 + 数值文本）
  final List<ItemComparerLineInput> item1 = [];
  final List<ItemComparerLineInput> item2 = [];

  ItemComparerStore() {
    _load();
  }

  void _load() {
    final raw = _box.get(itemComparerKey);
    if (raw is! String || raw.isEmpty) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    baseAttack = json['baseAttack'] as String? ?? '';
    increasedDmg = json['increasedDmg'] as String? ?? '';
    moreDmg = json['moreDmg'] as String? ?? '';
    critChance = json['critChance'] as String? ?? '';
    critDmg = json['critDmg'] as String? ?? '';
    baseAps = json['baseAps'] as String? ?? '';
    speed = json['speed'] as String? ?? '';
    item1
      ..clear()
      ..addAll([
        for (final entry in json['item1'] as List? ?? const [])
          ItemComparerLineInput.fromJson(entry as Map<String, dynamic>),
      ]);
    item2
      ..clear()
      ..addAll([
        for (final entry in json['item2'] as List? ?? const [])
          ItemComparerLineInput.fromJson(entry as Map<String, dynamic>),
      ]);
  }

  /// 持久化当前输入（每次输入变化后调用，数据量小，直接写盘）
  void save() {
    _box.put(
      itemComparerKey,
      jsonEncode({
        'baseAttack': baseAttack,
        'increasedDmg': increasedDmg,
        'moreDmg': moreDmg,
        'critChance': critChance,
        'critDmg': critDmg,
        'baseAps': baseAps,
        'speed': speed,
        'item1': [for (final l in item1) l.toJson()],
        'item2': [for (final l in item2) l.toJson()],
      }),
    );
  }
}
