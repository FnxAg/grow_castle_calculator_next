import 'dart:math';

/// 装备等级
enum ItemLevel {
  B,
  A,
  S,
  L,
  E,

  /// 暂无词条数值数据（预留）
  U;
}

/// 装备类型
enum ItemType {
  // 武器
  bow,
  sword,
  staff,
  hammer,

  // 饰品
  ring,
  necklace,
  bracelet,
  earrings;

  /// 是否为武器（决定第 3 条白词条改抽红词条的概率）
  bool get isWeapon => switch (this) {
        ItemType.bow ||
        ItemType.sword ||
        ItemType.staff ||
        ItemType.hammer =>
          true,
        _ => false,
      };
}

/// 装备来源（掉落来源），决定各等级的掉落概率
enum ItemSource {
  dragon1('一龙', {ItemLevel.B: 1.0}),
  dragon2('二龙', {ItemLevel.B: 0.935, ItemLevel.A: 0.065}),
  dragon3('三龙', {ItemLevel.B: 0.885, ItemLevel.A: 0.095, ItemLevel.S: 0.02}),
  dragon4('四龙', {ItemLevel.B: 0.785, ItemLevel.A: 0.15, ItemLevel.S: 0.065}),
  dragon5('五龙', {ItemLevel.A: 0.91, ItemLevel.S: 0.05, ItemLevel.L: 0.04}),
  dragon6('六龙', {ItemLevel.A: 0.915, ItemLevel.S: 0.05, ItemLevel.E: 0.035});

  const ItemSource(this.label, this.dropRates);

  /// 显示名
  final String label;

  /// 各等级的掉落概率（百分数值，总和为 1.0）
  final Map<ItemLevel, double> dropRates;

  /// 按掉落概率随机一个等级
  ItemLevel rollLevel(Random rng) {
    final roll = rng.nextDouble();
    var cumulative = 0.0;
    for (final entry in dropRates.entries) {
      cumulative += entry.value;
      if (roll < cumulative) return entry.key;
    }
    return dropRates.keys.last; // 兜底：浮点累加误差
  }
}

/// 词条颜色（决定词条可出现的槽位：
/// 第 1、2 槽必定白，第 3 槽白或红，第 4 槽必定黄）
enum LineColor {
  white,
  red,
  yellow;
}

/// 词条冲突类型：同类型的词条在一件装备上共享计数。
/// 目前仅有 cooldown 跨颜色共享类型（白词条 cooldown 与红词条 cooldown），
/// 其余词条的冲突类型即其自身（如 damageInt 与 damagePercent 互不冲突）。
enum LineType {
  cooldown;
}

enum LineNumType {
  /// 百分比类型
  percent,
  /// 整数类型
  integer,
  /// 小数类型
  decimal,
  /// 固定值类型
  fixed,
  /// 静态类型
  static;
}

/// 白词条各等级数值范围（最低值, 最高值, 强化每级涨幅）
typedef WhiteLineRange = (double min, double max, double increase);

/// 词条数值范围（最低值, 最高值）
typedef LineRange = (double min, double max);

/// 装备词条（共 47 条：15 白 + 10 红 + 22 黄）
///
/// 机制说明：
/// - 白词条的数值范围随装备等级变化；红词条的数值范围固定；黄词条为技能等级 +1
/// - 红词条中 min == max 的是固定值词条（如 multiShot），不受 itemQuality 加强影响
/// - itemQuality 特殊：数值在 20%~25% 随机，用于加强前 3 条词条
enum ItemLine {
  // ── 白词条（第 1、2 槽）────────────────────────────
  damageInt('Damage +', LineColor.white, LineNumType.integer, perLevel: {
    ItemLevel.B: (10, 80, 3),
    ItemLevel.A: (10, 80, 3),
    ItemLevel.S: (80, 100, 3),
    ItemLevel.L: (80, 100, 3),
    ItemLevel.E: (80, 100, 3),
  }),

  damagePercent('Damage %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (2, 8, 0.1),
    ItemLevel.A: (2, 8, 0.1),
    ItemLevel.S: (8, 10, 0.1),
    ItemLevel.L: (8, 10, 0.1),
    ItemLevel.E: (8, 10, 0.1),
  }),

  coldDamage('Cold Damage %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (5, 12, 0.1),
    ItemLevel.A: (5, 12, 0.1),
    ItemLevel.S: (12, 15, 0.1),
    ItemLevel.L: (12, 15, 0.1),
    ItemLevel.E: (12, 15, 0.1),
  }),

  fireDamage('Fire Damage %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (5, 12, 0.1),
    ItemLevel.A: (5, 12, 0.1),
    ItemLevel.S: (12, 15, 0.1),
    ItemLevel.L: (12, 15, 0.1),
    ItemLevel.E: (12, 15, 0.1),
  }),

  poisonDamage('Poison Damage %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (5, 12, 0.1),
    ItemLevel.A: (5, 12, 0.1),
    ItemLevel.S: (12, 15, 0.1),
    ItemLevel.L: (12, 15, 0.1),
    ItemLevel.E: (12, 15, 0.1),
  }),

  lightningDamage('Lightning Damage %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (5, 12, 0.1),
    ItemLevel.A: (5, 12, 0.1),
    ItemLevel.S: (12, 15, 0.1),
    ItemLevel.L: (12, 15, 0.1),
    ItemLevel.E: (12, 15, 0.1),
  }),

  physicalDamage('Physical Damage %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (5, 12, 0.1),
    ItemLevel.A: (5, 12, 0.1),
    ItemLevel.S: (12, 15, 0.1),
    ItemLevel.L: (12, 15, 0.1),
    ItemLevel.E: (12, 15, 0.1),
  }),

  attackSpeed('Attack Speed %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (2, 8, 0.1),
    ItemLevel.A: (2, 8, 0.1),
    ItemLevel.S: (8, 10, 0.1),
    ItemLevel.L: (8, 10, 0.1),
    ItemLevel.E: (8, 10, 0.1),
  }),

  criticalChance('Critical Chance %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (1, 4, 0.05),
    ItemLevel.A: (1, 4, 0.05),
    ItemLevel.S: (4, 5, 0.05),
    ItemLevel.L: (4, 5, 0.05),
    ItemLevel.E: (4, 5, 0.05),
  }),

  criticalDamage('Critical Damage %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (10, 24, 0.2),
    ItemLevel.A: (10, 24, 0.2),
    ItemLevel.S: (24, 30, 0.2),
    ItemLevel.L: (24, 30, 0.2),
    ItemLevel.E: (24, 30, 0.2),
  }),

  mpCost('MP Cost %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (2, 8, 0.1),
    ItemLevel.A: (2, 8, 0.1),
    ItemLevel.S: (8, 10, 0.1),
    ItemLevel.L: (8, 10, 0.1),
    ItemLevel.E: (8, 10, 0.1),
  }),

  cooldown('Cooldown %', LineColor.white, LineNumType.percent,
      conflictType: LineType.cooldown, perLevel: {
    ItemLevel.B: (1, 4, 0.05),
    ItemLevel.A: (1, 4, 0.05),
    ItemLevel.S: (4, 5, 0.05),
    ItemLevel.L: (4, 5, 0.05),
    ItemLevel.E: (4, 5, 0.05),
  }),

  goldPerHit('Gold per Hit', LineColor.white, LineNumType.integer, perLevel: {
    ItemLevel.B: (10, 25, 1),
    ItemLevel.A: (10, 25, 1),
    ItemLevel.S: (25, 31, 1),
    ItemLevel.L: (25, 31, 1),
    ItemLevel.E: (25, 31, 1),
  }),

  knockbackChance('Knockback Chance %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (2, 8, 0.1),
    ItemLevel.A: (2, 8, 0.1),
    ItemLevel.S: (8, 10, 0.1),
    ItemLevel.L: (8, 10, 0.1),
    ItemLevel.E: (8, 10, 0.1),
  }),

  stunChance('Stun Chance %', LineColor.white, LineNumType.percent, perLevel: {
    ItemLevel.B: (2, 8, 0.1),
    ItemLevel.A: (2, 8, 0.1),
    ItemLevel.S: (8, 10, 0.1),
    ItemLevel.L: (8, 10, 0.1),
    ItemLevel.E: (8, 10, 0.1),
  }),

  // ── 红词条（第 3 槽）────────────────────────────────
  redCooldown('Cooldown -', LineColor.red, LineNumType.decimal,
      range: (1.6, 2.0), conflictType: LineType.cooldown),

  areaSkillDamage('Area Skill Damage %', LineColor.red, LineNumType.percent, range: (80, 100)),

  slow('Slow Seconds', LineColor.red, LineNumType.decimal, range: (1.6, 2.0)),

  airDamage('Air Damage %', LineColor.red, LineNumType.percent, range: (40, 50)),

  bossDamage('Boss Damage %', LineColor.red, LineNumType.percent, range: (40, 50)),

  damageReduced('Damage Reduced %', LineColor.red, LineNumType.percent, range: (20, 25)),

  summonedTime('Summoned Time +', LineColor.red, LineNumType.decimal, range: (1.6, 2.0)),

  /// 固定值词条
  chainLightning('Chain Lightning +', LineColor.red, LineNumType.fixed, range: (2, 2)),

  /// 固定值词条，仅弓类武器与饰品可出现
  arrow('Arrow +', LineColor.red, LineNumType.fixed, 
      range: (1, 1),
      allowedTypes: {
        ItemType.bow,
        ItemType.ring,
        ItemType.necklace,
        ItemType.bracelet,
        ItemType.earrings,
      }),

  /// 固定值词条
  summonedUnits('Summoned Units +', LineColor.red, LineNumType.fixed, range: (1, 1)),

  // ── 金词条（第 4 槽，技能等级 +1）───────────────────
  skillBonusGold('Bonus Gold Skill LV +1', LineColor.yellow, LineNumType.static),
  skillBonusExp('Bonus Exp Skill LV +1', LineColor.yellow, LineNumType.static),
  skillCooldown('Cooldown Skill LV +1', LineColor.yellow, LineNumType.static),
  skillDamage('Damage Skill LV +1', LineColor.yellow, LineNumType.static),
  skillCriticalChance('Critical Chance Skill LV +1', LineColor.yellow, LineNumType.static),
  skillDefense('Defense Skill LV +1', LineColor.yellow, LineNumType.static),
  skillArcherSpeed('Archer Speed Skill LV +1', LineColor.yellow, LineNumType.static),
  skillHeroDamage('Hero Damage Skill LV +1', LineColor.yellow, LineNumType.static),
  skillLeaderDefense('Leader, Summoner Defense Skill LV +1', LineColor.yellow, LineNumType.static),
  skillPhysicalMastery('Physical Mastery Skill LV +1', LineColor.yellow, LineNumType.static),
  skillColonyGold('Colony Gold Skill LV +1', LineColor.yellow, LineNumType.static),
  skillColonyCooldown('Colony Cooldown Skill LV +1', LineColor.yellow, LineNumType.static),
  skillFireMastery('Fire Mastery Skill LV +1', LineColor.yellow, LineNumType.static),
  skillIceMastery('Ice Mastery Skill LV +1', LineColor.yellow, LineNumType.static),
  skillArcherRange('Archer Range Skill LV +1', LineColor.yellow, LineNumType.static),
  skillLightningMastery('Lightning Mastery Skill LV +1', LineColor.yellow, LineNumType.static),
  skillPoisonMastery('Poison Mastery Skill LV +1', LineColor.yellow, LineNumType.static),
  skillCriticalDamage('Critical Damage Skill LV +1', LineColor.yellow, LineNumType.static),
  skillPerfectGold('Perfect Gold Skill LV +1', LineColor.yellow, LineNumType.static),
  skillMimicChance('Mimic Chance Skill LV +1', LineColor.yellow, LineNumType.static),
  skillMpRecovery('MP Recovery Skill LV +1', LineColor.yellow, LineNumType.static),

  /// 特殊词条：数值在 20%~25% 随机，加强前 3 条词条
  itemQuality('Item Quality +', LineColor.yellow, LineNumType.percent, range: (20, 25));

  const ItemLine(
    this.label,
    this.color, 
    this.numType, {
    this.perLevel,
    this.range,
    this.conflictType,
    this.allowedTypes,
  });

  /// 显示名
  final String label;

  /// 词条颜色
  final LineColor color;

  /// 数值类型（整数、百分比、小数），null 表示按 label 判断
  final LineNumType? numType;

  /// 白词条各等级数值范围
  final Map<ItemLevel, WhiteLineRange>? perLevel;

  /// 红词条数值范围
  final LineRange? range;

  /// 冲突类型（跨词条共享计数用），null 表示仅与自身冲突
  final LineType? conflictType;

  /// 可出现的装备类型集合（如 multiShot 仅弓与饰品），null 表示无限制
  final Set<ItemType>? allowedTypes;

  // ── 静态词条池 ──────────────────────────────────────

  /// 全部 47 个词条
  static List<ItemLine> get all => values;

  /// 白词条池
  static List<ItemLine> get whiteLines =>
      values.where((l) => l.color == LineColor.white).toList(growable: false);

  /// 红词条池
  static List<ItemLine> get redLines =>
      values.where((l) => l.color == LineColor.red).toList(growable: false);

  /// 黄词条池
  static List<ItemLine> get yellowLines =>
      values.where((l) => l.color == LineColor.yellow).toList(growable: false);

  // ── 数值 ────────────────────────────────────────────

  /// 指定等级下的数值范围；黄词条（技能 +1）无范围，itemQuality 为 20~25
  LineRange? valueRange(ItemLevel level) {
    switch (color) {
      case LineColor.white:
        final (min, max, _) = perLevel![level]!;
        return (min, max);
      case LineColor.red:
        return range!;
      case LineColor.yellow:
        return this == ItemLine.itemQuality ? (20, 25) : null;
    }
  }

  /// 全部等级下的初始值范围（跨等级取并集，供规则数值校验用）；
  /// 黄词条（技能 +1）无范围，itemQuality 为 20~25
  LineRange? overallValueRange() {
    switch (color) {
      case LineColor.white:
        var min = double.infinity;
        var max = double.negativeInfinity;
        for (final entry in perLevel!.entries) {
          if (entry.value.$1 < min) min = entry.value.$1;
          if (entry.value.$2 > max) max = entry.value.$2;
        }
        return (min, max);
      case LineColor.red:
        return range!;
      case LineColor.yellow:
        return this == ItemLine.itemQuality ? (20, 25) : null;
    }
  }

  /// 是否为固定值词条（红词条中 min == max）
  // bool get isFixed => color == LineColor.red && range!.$1 == range!.$2;
  bool get isFixed => numType == LineNumType.fixed;

  /// 是否为百分比词条（label 带 % 或 itemQuality），精度为 1 位小数（如 4.5）
  // bool get isPercent => label.contains('%') || this == ItemLine.itemQuality;
  bool get isPercent => numType == LineNumType.percent;

  /// 是否只 roll 整数（Damage +、Gold per Hit）
  // bool get rollsInteger =>
  //     this == ItemLine.damageInt || this == ItemLine.goldPerHit;
  bool get rollsInteger => numType == LineNumType.integer;

  /// 随机初始值（范围内均匀随机；固定值词条返回固定值）。
  /// 精度：整数词条 0 位小数，百分比词条 1 位小数（如 4.5），
  /// 其余词条 3 位小数（如 1.653）
  double rollValue(ItemLevel level, Random rng) {
    switch (color) {
      case LineColor.white:
        final (min, max, _) = perLevel![level]!;
        return _roundToPrecision(min + rng.nextDouble() * (max - min));
      case LineColor.red:
        final (min, max) = range!;
        return _roundToPrecision(min + rng.nextDouble() * (max - min));
      case LineColor.yellow:
        return this == ItemLine.itemQuality
            ? _roundToPrecision(20 + rng.nextDouble() * 5)
            : 1;
    }
  }

  /// 按词条类型四舍五入：整数 0 位、百分比 1 位、其余 3 位小数
  double _roundToPrecision(double value) {
    if (rollsInteger) return value.roundToDouble();
    final decimals = isPercent ? 10 : 1000;
    return (value * decimals).roundToDouble() / decimals;
  }

  /// 应用 itemQuality 加成（[qualityPercent] 为 20~25 的百分数值）
  /// - 黄词条（第 4 槽）不受加成
  /// - 固定值红词条加强后只保留整数部分（如 1 × 1.2 → 1，相当于没加强）
  double applyQualityBoost(double value, double qualityPercent) {
    if (color == LineColor.yellow) return value;
    final boosted = value * (1 + qualityPercent / 100);
    return isFixed ? boosted.truncateToDouble() : boosted;
  }

  /// 是否与 [other] 属于同类型（冲突计数用）
  bool sameType(ItemLine other) =>
      this == other ||
      (conflictType != null && conflictType == other.conflictType);
}
