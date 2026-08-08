import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/core/src/item_display_rules.dart';
import 'package:grow_castle_calculator_next/core/src/item_generator.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';

/// 手工构造装备（数值无关紧要，规则只看词条组合）
GeneratedItem buildItem(List<ItemLine> lines, {ItemType type = ItemType.bow}) =>
    GeneratedItem(
      level: ItemLevel.E,
      type: type,
      lines: [for (final l in lines) GeneratedLine(l, 1)],
    );

UserHighlightRule buildRule(
  Set<ItemLine> lines, {
  String hint = '测试规则',
  bool pinToTop = true,
}) =>
    UserHighlightRule(
      id: 'rule-$hint',
      hint: hint,
      lines: {for (final line in lines) line: const LineCondition()},
      pinToTop: pinToTop,
    );

/// 按 (词条, 数值) 构造装备（可带 rawValue 模拟加强）
GeneratedItem buildItemWithValues(
  List<(ItemLine, double)> lines, {
  ItemType type = ItemType.bow,
}) =>
    GeneratedItem(
      level: ItemLevel.E,
      type: type,
      lines: [for (final (l, v) in lines) GeneratedLine(l, v)],
    );

void main() {
  group('UserHighlightRule 匹配', () {
    test('装备包含全部所选词条时命中', () {
      final rule = buildRule({
        ItemLine.cooldown,
        ItemLine.redCooldown,
        ItemLine.itemQuality,
      });
      expect(
        rule.matches(buildItem([
          ItemLine.cooldown,
          ItemLine.damageInt,
          ItemLine.redCooldown,
          ItemLine.itemQuality,
        ])),
        isTrue,
      );
    });

    test('缺少任一所选词条时不命中', () {
      final rule = buildRule({
        ItemLine.cooldown,
        ItemLine.redCooldown,
        ItemLine.itemQuality,
      });
      expect(
        rule.matches(buildItem([
          ItemLine.cooldown,
          ItemLine.damageInt,
          ItemLine.redCooldown,
          ItemLine.skillDamage,
        ])),
        isFalse,
      );
    });

    test('装备上多余词条不影响命中', () {
      final rule = buildRule({ItemLine.cooldown});
      expect(
        rule.matches(buildItem([
          ItemLine.cooldown,
          ItemLine.damageInt,
          ItemLine.redCooldown,
          ItemLine.itemQuality,
        ])),
        isTrue,
      );
    });

    test('黄词条 cooldown 与白/红 cooldown 是不同词条，需分别选中', () {
      final rule = buildRule({ItemLine.cooldown, ItemLine.skillCooldown});
      // 只有白 cooldown，没有黄 cooldown
      expect(
        rule.matches(buildItem([ItemLine.cooldown, ItemLine.skillDamage])),
        isFalse,
      );
    });
  });

  group('词条数量要求（白词条可同时出现两条）', () {
    test('要求 2 条白 cooldown 时，只命中出现 2 条的装备', () {
      final rule = UserHighlightRule(
        id: 'double-cd',
        hint: '双白cd',
        lines: {ItemLine.cooldown: const LineCondition(count: 2)},
      );
      expect(
        rule.matches(buildItem([ItemLine.cooldown, ItemLine.cooldown])),
        isTrue,
      );
      expect(
        rule.matches(buildItem([ItemLine.cooldown, ItemLine.damageInt])),
        isFalse,
      );
    });

    test('数量与组合可混合：2 条白cd + itemQuality', () {
      final rule = UserHighlightRule(
        id: 'double-cd-quality',
        hint: '双白cd+加强',
        lines: {
          ItemLine.cooldown: const LineCondition(count: 2),
          ItemLine.itemQuality: const LineCondition(),
        },
      );
      expect(
        rule.matches(buildItem([
          ItemLine.cooldown,
          ItemLine.cooldown,
          ItemLine.redCooldown,
          ItemLine.itemQuality,
        ])),
        isTrue,
      );
      // 只有 1 条白 cd
      expect(
        rule.matches(buildItem([
          ItemLine.cooldown,
          ItemLine.damageInt,
          ItemLine.redCooldown,
          ItemLine.itemQuality,
        ])),
        isFalse,
      );
    });

    test('数量要求超出装备上限时不命中（如要求 3 条白词条）', () {
      final rule = UserHighlightRule(
        id: 'triple-cd',
        hint: '三条cd',
        lines: {ItemLine.cooldown: const LineCondition(count: 3)},
      );
      expect(
        rule.matches(buildItem([
          ItemLine.cooldown,
          ItemLine.cooldown,
          ItemLine.damageInt,
        ])),
        isFalse,
      );
    });
  });

  group('词条数值范围', () {
    test('数值下限：原始值必须大于 minValue（严格大于）', () {
      final rule = UserHighlightRule(
        id: 'min-cd',
        hint: '白cd>3.5',
        lines: {ItemLine.cooldown: const LineCondition(minValue: 3.5)},
      );
      expect(
        rule.matches(buildItemWithValues([(ItemLine.cooldown, 4.0)])),
        isTrue,
      );
      expect(
        rule.matches(buildItemWithValues([(ItemLine.cooldown, 3.5)])),
        isFalse,
      );
      expect(
        rule.matches(buildItemWithValues([(ItemLine.cooldown, 3.0)])),
        isFalse,
      );
    });

    test('同时设置上下限：minValue < 原始值 < maxValue', () {
      final rule = UserHighlightRule(
        id: 'range-cd',
        hint: '范围',
        lines: {
          ItemLine.cooldown:
              const LineCondition(minValue: 3.5, maxValue: 4.5),
        },
      );
      expect(
        rule.matches(buildItemWithValues([(ItemLine.cooldown, 4.0)])),
        isTrue,
      );
      expect(
        rule.matches(buildItemWithValues([(ItemLine.cooldown, 4.5)])),
        isFalse,
      );
      expect(
        rule.matches(buildItemWithValues([(ItemLine.cooldown, 3.5)])),
        isFalse,
      );
    });

    test('数量与数值组合：2 条白cd 且每条都满足下限', () {
      final rule = UserHighlightRule(
        id: 'count-min-cd',
        hint: '双白cd高值',
        lines: {
          ItemLine.cooldown: const LineCondition(count: 2, minValue: 3.5),
        },
      );
      expect(
        rule.matches(buildItemWithValues([
          (ItemLine.cooldown, 4.0),
          (ItemLine.cooldown, 3.8),
        ])),
        isTrue,
      );
      // 其中一条不满足下限
      expect(
        rule.matches(buildItemWithValues([
          (ItemLine.cooldown, 4.0),
          (ItemLine.cooldown, 3.0),
        ])),
        isFalse,
      );
    });

    test('加强词条按加强前的原始值（rawValue）判断', () {
      final rule = UserHighlightRule(
        id: 'raw-check',
        hint: '白cd>3.2',
        lines: {ItemLine.cooldown: const LineCondition(minValue: 3.2)},
      );
      // 加强后 3.6，但原始值 3.0：不满足 > 3.2
      final boostedLow = GeneratedItem(
        level: ItemLevel.E,
        type: ItemType.bow,
        lines: [
          GeneratedLine(ItemLine.cooldown, 3.6, rawValue: 3.0),
          GeneratedLine(ItemLine.damageInt, 61),
        ],
      );
      expect(rule.matches(boostedLow), isFalse);
      // 加强后 4.2，原始值 3.5：满足 > 3.2
      final boostedOk = GeneratedItem(
        level: ItemLevel.E,
        type: ItemType.bow,
        lines: [
          GeneratedLine(ItemLine.cooldown, 4.2, rawValue: 3.5),
          GeneratedLine(ItemLine.damageInt, 61),
        ],
      );
      expect(rule.matches(boostedOk), isTrue);
    });

    test('未设置数值范围时不限制数值', () {
      final rule = UserHighlightRule(
        id: 'no-range',
        hint: '无范围',
        lines: {ItemLine.cooldown: const LineCondition()},
      );
      expect(
        rule.matches(buildItemWithValues([(ItemLine.cooldown, 1.0)])),
        isTrue,
      );
    });
  });

  group('装备类型限制', () {
    test('指定类型时，仅匹配该类型的装备', () {
      final rule =
          buildRule({ItemLine.cooldown}).copyWith(types: {ItemType.bow});
      expect(
        rule.matches(buildItem([ItemLine.cooldown], type: ItemType.bow)),
        isTrue,
      );
      expect(
        rule.matches(buildItem([ItemLine.cooldown], type: ItemType.sword)),
        isFalse,
      );
    });

    test('可指定多个类型', () {
      final rule = buildRule({ItemLine.cooldown})
          .copyWith(types: {ItemType.bow, ItemType.ring});
      expect(
        rule.matches(buildItem([ItemLine.cooldown], type: ItemType.ring)),
        isTrue,
      );
      expect(
        rule.matches(buildItem([ItemLine.cooldown], type: ItemType.staff)),
        isFalse,
      );
    });

    test('未指定类型时匹配所有类型', () {
      final rule = buildRule({ItemLine.cooldown});
      expect(
        rule.matches(buildItem([ItemLine.cooldown], type: ItemType.ring)),
        isTrue,
      );
    });
  });

  group('matchRule 优先级', () {
    test('返回第一条命中规则（列表顺序即优先级）', () {
      final first = buildRule({ItemLine.cooldown}, hint: '第一条');
      final second = buildRule({ItemLine.itemQuality}, hint: '第二条');
      final item = buildItem([ItemLine.cooldown, ItemLine.itemQuality]);
      expect(matchRule(item, [first, second]), same(first));
      expect(matchRule(item, [second, first]), same(second));
    });

    test('规则列表为空返回 null', () {
      expect(matchRule(buildItem([ItemLine.cooldown]), const []), isNull);
    });

    test('未命中任何规则返回 null', () {
      final rule = buildRule({ItemLine.damageInt, ItemLine.damagePercent});
      expect(matchRule(buildItem([ItemLine.cooldown]), [rule]), isNull);
    });

    test('pinToTop 随规则生效', () {
      final rule = buildRule({ItemLine.itemQuality}, pinToTop: false);
      final item = buildItem([ItemLine.itemQuality]);
      expect(matchRule(item, [rule])?.pinToTop, isFalse);
    });

    test('未启用的规则不参与匹配', () {
      final disabled = buildRule({ItemLine.cooldown}, hint: '禁用')
          .copyWith(enabled: false);
      final enabled = buildRule({ItemLine.cooldown}, hint: '启用');
      final item = buildItem([ItemLine.cooldown]);
      // 只有禁用规则时不命中
      expect(matchRule(item, [disabled]), isNull);
      // 禁用规则不阻塞后续启用规则
      expect(matchRule(item, [disabled, enabled]), same(enabled));
    });

    test('新规则默认启用', () {
      expect(buildRule({ItemLine.cooldown}).enabled, isTrue);
    });
  });

  group('序列化', () {
    test('toJson / fromJson 往返一致', () {
      final rule = UserHighlightRule(
        id: 'test-id',
        hint: '红白加强',
        lines: {
          ItemLine.cooldown: const LineCondition(),
          ItemLine.redCooldown: const LineCondition(),
          ItemLine.itemQuality: const LineCondition(),
        },
        pinToTop: false,
      );
      final restored = UserHighlightRule.fromJson(rule.toJson());
      expect(restored.id, rule.id);
      expect(restored.hint, rule.hint);
      expect(restored.lines, rule.lines);
      expect(restored.pinToTop, rule.pinToTop);
    });

    test('数量与数值范围序列化往返一致；旧数据按 1 条、不限数值解析', () {
      final rule = UserHighlightRule(
        id: 'double-cd',
        hint: '双白cd',
        lines: {
          ItemLine.cooldown: const LineCondition(count: 2, minValue: 3.5),
          ItemLine.itemQuality: const LineCondition(),
        },
      );
      expect(
        UserHighlightRule.fromJson(rule.toJson()).lines,
        {
          ItemLine.cooldown: const LineCondition(count: 2, minValue: 3.5),
          ItemLine.itemQuality: const LineCondition(),
        },
      );

      // 模拟旧版本持久化数据（lines 为词条名列表，每条默认 1 条、不限数值）
      final legacyJson = rule.toJson()..['lines'] = ['cooldown', 'itemQuality'];
      expect(
        UserHighlightRule.fromJson(legacyJson).lines,
        {
          ItemLine.cooldown: const LineCondition(),
          ItemLine.itemQuality: const LineCondition(),
        },
      );
    });

    test('copyWith 保留 id 并更新其他字段', () {
      final rule = buildRule({ItemLine.cooldown});
      final updated = rule.copyWith(
        hint: '新提示',
        lines: {ItemLine.damageInt: const LineCondition()},
        pinToTop: false,
        enabled: false,
      );
      expect(updated.id, rule.id);
      expect(updated.hint, '新提示');
      expect(updated.lines, {ItemLine.damageInt: const LineCondition()});
      expect(updated.pinToTop, isFalse);
      expect(updated.enabled, isFalse);
    });

    test('enabled 序列化往返一致；旧数据缺失 enabled 时默认启用', () {
      final rule = buildRule({ItemLine.cooldown}).copyWith(enabled: false);
      expect(UserHighlightRule.fromJson(rule.toJson()).enabled, isFalse);

      // 模拟旧版本持久化数据（无 enabled 字段）
      final legacyJson = rule.toJson()..remove('enabled');
      expect(UserHighlightRule.fromJson(legacyJson).enabled, isTrue);
    });

    test('types 序列化往返一致；旧数据缺失 types 时不限类型', () {
      final rule = buildRule({ItemLine.cooldown})
          .copyWith(types: {ItemType.bow, ItemType.ring});
      expect(
        UserHighlightRule.fromJson(rule.toJson()).types,
        {ItemType.bow, ItemType.ring},
      );

      // 模拟旧版本持久化数据（无 types 字段）
      final legacyJson = rule.toJson()..remove('types');
      expect(UserHighlightRule.fromJson(legacyJson).types, isNull);
    });

    test('copyWith 可更新 types', () {
      final rule = buildRule({ItemLine.cooldown});
      expect(rule.copyWith(types: {ItemType.staff}).types, {ItemType.staff});
    });
  });
}
