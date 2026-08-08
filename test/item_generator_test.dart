import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/core/src/item_generator.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';

void main() {
  final rng = Random(42);

  /// 抽取 [count] 件装备，用于统计验证
  List<GeneratedItem> generateMany({
    required int count,
    required ItemType type,
    ItemSource? source,
    ItemLevel? level,
  }) {
    final generator = ItemGenerator(random: rng);
    return [
      for (var i = 0; i < count; i++)
        generator.generate(type: type, source: source, level: level),
    ];
  }

  group('数据完整性', () {
    test('共 47 个词条：15 白 + 10 红 + 22 黄', () {
      expect(ItemLine.all.length, 47);
      expect(ItemLine.whiteLines.length, 15);
      expect(ItemLine.redLines.length, 10);
      expect(ItemLine.yellowLines.length, 22);
    });

    test('白词条各等级均有数值范围（不含 U）', () {
      for (final line in ItemLine.whiteLines) {
        for (final level in ItemLevel.values) {
          if (level == ItemLevel.U) continue;
          expect(line.valueRange(level), isNotNull,
              reason: '${line.label} 缺少 $level 的数值范围');
        }
      }
    });

    test('itemQuality 范围固定为 20~25', () {
      expect(ItemLine.itemQuality.valueRange(ItemLevel.E), (20, 25));
      for (var i = 0; i < 1000; i++) {
        final v = ItemLine.itemQuality.rollValue(ItemLevel.E, rng);
        expect(v, inInclusiveRange(20, 25));
      }
    });

    test('整体 roll 值范围（跨等级并集）正确', () {
      // damageInt：B/A (10,80)，S/L/E (80,100) → 并集 (10,100)
      expect(ItemLine.damageInt.overallValueRange(), (10, 100));
      // cooldown：B/A (1,4)，S/L/E (4,5) → 并集 (1,5)
      expect(ItemLine.cooldown.overallValueRange(), (1, 5));
      expect(ItemLine.redCooldown.overallValueRange(), (1.6, 2.0));
      expect(ItemLine.itemQuality.overallValueRange(), (20, 25));
      // 黄词条（技能 +1）无范围
      expect(ItemLine.skillDamage.overallValueRange(), isNull);
      // 固定值红词条：范围即固定值
      expect(ItemLine.arrow.overallValueRange(), (1, 1));
    });

    test('掉落表概率总和为 1', () {
      for (final source in ItemSource.values) {
        final sum = source.dropRates.values.reduce((a, b) => a + b);
        expect((sum - 1).abs(), lessThan(1e-9), reason: '${source.label} 概率总和不为 1');
      }
    });
  });

  group('槽位结构', () {
    test('B 级只有 1 条白词条；A/S 级 2 条白词条', () {
      for (final level in [ItemLevel.B, ItemLevel.A, ItemLevel.S]) {
        final items = generateMany(count: 500, type: ItemType.bow, level: level);
        for (final item in items) {
          final expectCount = level == ItemLevel.B ? 1 : 2;
          expect(item.lines.length, expectCount, reason: '$level 词条数错误');
          expect(item.lines.every((l) => l.line.color == LineColor.white),
              isTrue, reason: '$level 第 1/2 条必须是白词条');
        }
      }
    });

    test('L 级 3 条，前 2 条白，第 3 条白或红', () {
      final items = generateMany(count: 2000, type: ItemType.bow, level: ItemLevel.L);
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.lines.length, 3);
        expect(item.lines[0].line.color, LineColor.white);
        expect(item.lines[1].line.color, LineColor.white);
        expect(item.lines[2].line.color, anyOf(LineColor.white, LineColor.red));
      }
      // 两种结构都应出现
      final redCount = items.where((i) => i.lines[2].line.color == LineColor.red).length;
      expect(redCount, greaterThan(0));
      expect(redCount, lessThan(items.length));
    });

    test('E 级 4 条，第 4 条必定黄词条', () {
      final items = generateMany(count: 1000, type: ItemType.sword, level: ItemLevel.E);
      for (final item in items) {
        expect(item.lines.length, 4);
        expect(item.lines[3].line.color, LineColor.yellow);
        expect(item.lines[0].line.color, LineColor.white);
        expect(item.lines[1].line.color, LineColor.white);
      }
    });
  });

  group('词条限制', () {
    test('multiShot 绝不出现于剑/杖/锤', () {
      for (final type in [ItemType.sword, ItemType.staff, ItemType.hammer]) {
        final items = generateMany(count: 3000, type: type, level: ItemLevel.E);
        for (final item in items) {
          expect(item.lines.any((l) => l.line == ItemLine.arrow), isFalse,
              reason: '$type 上出现了 multiShot');
        }
      }
    });

    test('multiShot 可出现于弓与饰品', () {
      for (final type in [
        ItemType.bow,
        ItemType.ring,
        ItemType.necklace,
        ItemType.bracelet,
        ItemType.earrings,
      ]) {
        final items = generateMany(count: 3000, type: type, level: ItemLevel.E);
        expect(
          items.any((i) => i.lines.any((l) => l.line == ItemLine.arrow)),
          isTrue,
          reason: '$type 在 3000 件中未抽到 multiShot',
        );
      }
    });

    test('同类型词条最多 2 条（不会出现 3 条 cooldown 或 3 条相同白词条）', () {
      final items = generateMany(count: 5000, type: ItemType.bow, level: ItemLevel.E);
      for (final item in items) {
        for (var i = 0; i < item.lines.length; i++) {
          final count = item.lines
              .where((l) => l.line.sameType(item.lines[i].line))
              .length;
          expect(count, lessThanOrEqualTo(2), reason: '${item.lines[i].line.label} 出现 $count 次');
        }
      }
    });

    test('第 4 条黄词条不会与白/红词条冲突', () {
      final items = generateMany(count: 2000, type: ItemType.ring, level: ItemLevel.E);
      for (final item in items) {
        final yellow = item.lines[3].line;
        for (final other in item.lines.take(3)) {
          expect(yellow.sameType(other.line), isFalse);
        }
      }
    });
  });

  group('掉落概率', () {
    test('装备类型按掉落概率分布：武器各 15%，饰品各 10%', () {
      final generator = ItemGenerator(random: rng);
      const total = 10000;
      final counts = <ItemType, int>{};
      for (var i = 0; i < total; i++) {
        final item = generator.generate(source: ItemSource.dragon4);
        counts.update(item.type, (c) => c + 1, ifAbsent: () => 1);
      }
      for (final type in ItemType.values) {
        final expected = type.isWeapon ? 0.15 : 0.10;
        final actual = counts[type]! / total;
        expect((actual - expected).abs(), lessThan(0.02),
            reason: '${type.name} 实际 $actual 预期 $expected');
      }
    });
  });

  group('数值与 itemQuality', () {
    test('白词条数值在对应等级范围内', () {
      final items = generateMany(count: 3000, type: ItemType.bow, level: ItemLevel.L);
      for (final item in items) {
        for (final line in item.lines.take(3)) {
          final range = line.line.valueRange(item.level)!;
          expect(line.value, inInclusiveRange(range.$1, range.$2),
              reason: '${line.line.label} 数值越界');
        }
      }
    });

    test('itemQuality 加强前 3 条，且不加强第 4 条（固定值红词条只留整数部分）', () {
      final items = generateMany(count: 10000, type: ItemType.bow, level: ItemLevel.E);
      final withQuality =
          items.where((i) => i.quality != null).take(50).toList();
      expect(withQuality, isNotEmpty, reason: '样本量不足，未抽到 itemQuality');

      for (final boosted in withQuality) {
        final quality = boosted.quality!;
        final multiplier = 1 + quality / 100;
        for (final line in boosted.lines.take(3)) {
          final range = line.line.valueRange(boosted.level)!;
          if (line.line.isFixed) {
            // 固定值词条：加强后只保留整数部分，即 truncate(固定值 × 倍率)
            expect(line.value, (range.$1 * multiplier).truncateToDouble(),
                reason: '${line.line.label} 加强结果错误');
          } else {
            // 还原加强后，原始值应落在词条范围内（roll 已四舍五入，容差 1e-3）
            final original = line.value / multiplier;
            expect(original, greaterThanOrEqualTo(range.$1 - 1e-3),
                reason: '${line.line.label} 还原值低于下限');
            expect(original, lessThanOrEqualTo(range.$2 + 1e-3),
                reason: '${line.line.label} 还原值高于上限');
          }
        }
        // 第 4 条（黄词条）不受加强：非 itemQuality 的值为 1（技能等级 +1），
        // itemQuality 本身为 20~25
        if (boosted.lines[3].line == ItemLine.itemQuality) {
          expect(boosted.lines[3].value, inInclusiveRange(20, 25));
        } else {
          expect(boosted.lines[3].value, 1);
        }
      }
    });

    test('固定值词条数值等于其固定值', () {
      for (final line in ItemLine.redLines.where((l) => l.isFixed)) {
        for (var i = 0; i < 100; i++) {
          expect(line.rollValue(ItemLevel.E, rng), line.valueRange(ItemLevel.E)!.$1);
        }
      }
    });

    test('数值精度：百分比词条 1 位小数，非百分比 3 位小数（未加强）', () {
      final items =
          generateMany(count: 2000, type: ItemType.bow, level: ItemLevel.E);
      for (final item in items) {
        // 精度规则只约束未加强的 roll 值，加强后的值为乘积
        if (item.quality != null) continue;
        for (final line in item.lines) {
          final l = line.line;
          if (l.isFixed || l.color == LineColor.yellow) continue;
          final scaled = line.value * (l.isPercent ? 10 : 1000);
          expect(scaled, closeTo(scaled.roundToDouble(), 1e-6),
              reason: '${l.label} 精度错误: ${line.value}');
        }
      }
    });

    test('Damage + 与 Gold per Hit 只 roll 整数', () {
      final items =
          generateMany(count: 2000, type: ItemType.bow, level: ItemLevel.L);
      for (final item in items) {
        for (final line in item.lines) {
          if (line.line != ItemLine.damageInt &&
              line.line != ItemLine.goldPerHit) {
            continue;
          }
          // 加强后的值可能是小数，检查原始 roll 值
          final roll = line.rawValue ?? line.value;
          expect(roll, roll.roundToDouble(),
              reason: '${line.line.label} 应为整数: $roll');
        }
      }
    });

    test('加强后保留原始值（rawValue），黄词条与 itemQuality 不受加强', () {
      final items =
          generateMany(count: 10000, type: ItemType.bow, level: ItemLevel.E);
      final withQuality =
          items.where((i) => i.quality != null).take(20).toList();
      expect(withQuality, isNotEmpty, reason: '样本量不足，未抽到 itemQuality');

      for (final item in withQuality) {
        for (final line in item.lines) {
          if (line.line.color == LineColor.yellow) {
            // 黄词条（第 4 槽与 itemQuality）不被加强
            expect(line.rawValue, isNull, reason: '${line.line.label} 不应被加强');
            continue;
          }
          expect(line.rawValue, isNotNull, reason: '${line.line.label} 缺少原始值');
        }
      }
    });
  });
}
