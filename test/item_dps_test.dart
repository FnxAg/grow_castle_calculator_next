import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/core/calc/item_dps.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';

/// 基准面板：Base 1000，Inc +500%，More +200%，暴击率 50%，暴击 250%（2.5 倍）
ItemDpsResult baseResult({
  List<ItemDpsLine> lines = const [],
  List<double> moreDmgLines = const [],
  List<double> elementDmgLines = const [],
}) => computeItemDps(
      baseAttack: 1000,
      increasedDmg: 500,
      moreDmg: 200,
      critChance: 50,
      critDmg: 250,
      lines: lines,
      moreDmgLines: moreDmgLines,
      elementDmgLines: elementDmgLines,
    );

void main() {
  test('无装备基准：普通 18000，暴击 45000，DPS 31500', () {
    final r = baseResult();
    expect(r.normalHit, closeTo(18000, 1e-9));
    expect(r.critHit, closeTo(45000, 1e-9));
    // 50% × 45000 + 50% × 18000
    expect(r.dps, closeTo(31500, 1e-9));
  });

  test('Damage % 词条叠加到增伤', () {
    final r = baseResult(lines: [(line: ItemLine.damagePercent, value: 10)]);
    expect(r.normalHit, closeTo(18300, 1e-9)); // 1000 × 6.1 × 3
    expect(r.dps, closeTo(32025, 1e-9));
  });

  test('Damage + 词条叠加到基础攻击', () {
    final r = baseResult(lines: [(line: ItemLine.damageInt, value: 80)]);
    expect(r.normalHit, closeTo(19440, 1e-9)); // 1080 × 6 × 3
    expect(r.dps, closeTo(34020, 1e-9));
  });

  test('Element Damage（元素伤害整合项）视为普通增伤', () {
    final r = baseResult(elementDmgLines: [12]);
    expect(r.normalHit, closeTo(18360, 1e-9)); // 1000 × 6.12 × 3
    expect(r.dps, closeTo(18360 * 1.75, 1e-9));
  });

  test('More Dmg 词条与面板累乘：面板 200% × 词条 30% = 倍率 3.9', () {
    final r = computeItemDps(
      baseAttack: 1000,
      increasedDmg: 500,
      moreDmg: 200,
      critChance: 50,
      critDmg: 250,
      moreDmgLines: [30],
    );
    // (1 + 2) × (1 + 0.3) = 3.9，普通一击 = 1000 × 6 × 3.9
    expect(r.normalHit, closeTo(23400, 1e-9));
    expect(r.dps, closeTo(23400 * 1.75, 1e-9));
  });

  test('多条 More Dmg 词条各自累乘', () {
    final r = computeItemDps(
      baseAttack: 1000,
      increasedDmg: 500,
      moreDmg: 200,
      critChance: 0,
      critDmg: 250,
      moreDmgLines: [30, 20],
    );
    // 3 × 1.3 × 1.2 = 4.68，普通一击 = 1000 × 6 × 4.68
    expect(r.normalHit, closeTo(28080, 1e-9));
  });

  test('无 More Dmg 词条时与面板累乘前一致', () {
    final withPanel = baseResult();
    final withLine = baseResult(lines: [
      (line: ItemLine.damagePercent, value: 10),
    ]);
    // 仅验证累加模型不受 moreDmgLines 默认值影响
    expect(withPanel.dps, closeTo(31500, 1e-9));
    expect(withLine.dps, closeTo(32025, 1e-9));
  });

  test('暴击词条叠加：暴击率 +5，暴击伤害 +30', () {
    final r = baseResult(lines: [
      (line: ItemLine.criticalChance, value: 5),
      (line: ItemLine.criticalDamage, value: 30),
    ]);
    // 普通不变，暴击 18000 × 2.8，DPS = 18000 × (1 + 0.55 × 1.8)
    expect(r.normalHit, closeTo(18000, 1e-9));
    expect(r.critHit, closeTo(50400, 1e-9));
    expect(r.dps, closeTo(35820, 1e-9));
  });

  test('暴击率上限 100%', () {
    final r = baseResult(
      lines: [(line: ItemLine.criticalChance, value: 999)],
    );
    expect(r.dps, closeTo(r.critHit, 1e-9)); // 满暴击时 DPS = 暴击伤害
  });

  test('无关词条不影响结果', () {
    final base = baseResult();
    for (final line in [
      ItemLine.mpCost,
      ItemLine.cooldown,
      ItemLine.goldPerHit,
      ItemLine.knockbackChance,
      ItemLine.stunChance,
    ]) {
      final r = baseResult(lines: [(line: line, value: 50)]);
      expect(r.dps, base.dps, reason: '${line.label} 不应影响 DPS');
    }
  });

  test('攻击速度：面板两项都填写后按攻击次数计算 DPS', () {
    final r = computeItemDps(
      baseAttack: 1000,
      increasedDmg: 500,
      moreDmg: 200,
      critChance: 50,
      critDmg: 250,
      baseAps: 2,
      increasedSpeed: 100,
    );
    // 面板 APS 已是 IS 加成后的最终值，无词条时直接使用
    expect(r.aps, closeTo(2, 1e-9));
    expect(r.dps, closeTo(31500 * 2, 1e-9));
  });

  test('Attack Speed 词条累加到 Increased Speed（反推基础攻击次数）', () {
    final r = computeItemDps(
      baseAttack: 1000,
      increasedDmg: 500,
      moreDmg: 200,
      critChance: 50,
      critDmg: 250,
      baseAps: 2,
      increasedSpeed: 100,
      lines: [(line: ItemLine.attackSpeed, value: 50)],
    );
    // 基础攻击次数 = 2 / (1 + 1) = 1，词条后 IS = 150 → 1 × 2.5 = 2.5
    expect(r.aps, closeTo(2.5, 1e-9));
    expect(r.dps, closeTo(31500 * 2.5, 1e-9));
  });

  test('攻速两项未填齐时回退纯每击数值，Attack Speed 词条不参与', () {
    // 只填 Increased Speed，未填 Attacks Per Second
    final r = computeItemDps(
      baseAttack: 1000,
      increasedDmg: 500,
      moreDmg: 200,
      critChance: 50,
      critDmg: 250,
      increasedSpeed: 100,
      lines: [(line: ItemLine.attackSpeed, value: 50)],
    );
    expect(r.aps, isNull);
    expect(r.dps, closeTo(31500, 1e-9));
  });
}
