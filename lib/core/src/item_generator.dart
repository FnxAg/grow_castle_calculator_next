import 'dart:math';

import 'item_lines.dart';

/// 一条已生成的词条（词条 + 数值）
class GeneratedLine {
  const GeneratedLine(this.line, this.value, {this.rawValue});

  final ItemLine line;

  /// 最终数值（可能已被 itemQuality 加强）
  final double value;

  /// 未加强的原始数值；null 表示未被加强
  final double? rawValue;

  /// 是否被加强（加强后数值与原始值不同；
  /// 固定值词条加强无效，rawValue == value，视为未加强）
  bool get isBoosted => rawValue != null && rawValue != value;

  @override
  String toString() => '${line.label}: ${value.toStringAsFixed(2)}';
}

/// 生成的一件装备
class GeneratedItem {
  const GeneratedItem({
    required this.level,
    required this.type,
    required this.lines,
  });

  final ItemLevel level;
  final ItemType type;
  final List<GeneratedLine> lines;

  /// itemQuality 的百分数值（20~25），未抽到时为 null
  double? get quality {
    for (final l in lines) {
      if (l.line == ItemLine.itemQuality) return l.value;
    }
    return null;
  }

  @override
  String toString() {
    final buffer = StringBuffer('[$level] ${type.name}\n');
    for (final l in lines) {
      buffer.writeln('  $l');
    }
    final q = quality;
    if (q != null) {
      buffer.writeln('  (itemQuality ${q.toStringAsFixed(2)}% → 前3条 ×${(1 + q / 100).toStringAsFixed(4)})');
    }
    return buffer.toString();
  }
}

/// 抽装备模拟器（草案）
///
/// 生成流程（对应游戏逻辑）：
/// 1. 确定装备的等级与类型（等级由装备来源掉落表随机；
///    类型未指定时按掉落概率随机：武器各 15%、饰品各 10%）
/// 2. 从全部 47 个词条中抽取一个
/// 3. 检查词条颜色是否符合品级要求（第 1、2 槽白 / 第 3 槽白或红 / 第 4 槽黄），不满足回到 2
/// 4. 检查词条类型是否符合装备类型要求（如 multiShot 仅弓与饰品），不满足回到 2
/// 5. 仅在抽第 3 条时：检查是否会出现 3 个同类型词条（含 3 条相同白词条），是则回到 2
/// 6. 仅在抽第 3 条时：抽到红词条直接通过；抽到白词条时，
///    武器 50% / 饰品 25% 概率改从红词条池重抽（重抽时仍校验装备类型与同类型上限）
/// 7. 仅在抽第 4 条时：从黄词条池抽取
/// 8. 全部词条确定后，统一抽取各词条数值（此时才应用 itemQuality 加强）
class ItemGenerator {
  ItemGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// 同类型词条数量上限。
  /// 按步骤 5"不允许出现 3 个重复类型词条"实现（即同类型最多 2 条）；
  /// 若实际规则是"不超过 3 条"，改为 3 即可（此时该检查永不触发）。
  static const int maxSameType = 2;

  /// 装备类型掉落概率（每条龙相同）：武器各 15%，饰品各 10%，总和 100%
  static const Map<ItemType, double> typeDropRates = {
    ItemType.bow: 0.15,
    ItemType.sword: 0.15,
    ItemType.staff: 0.15,
    ItemType.hammer: 0.15,
    ItemType.ring: 0.10,
    ItemType.necklace: 0.10,
    ItemType.bracelet: 0.10,
    ItemType.earrings: 0.10,
  };

  /// 拒绝采样最大尝试次数，防止极端情况下死循环
  static const int _maxTries = 1000;

  /// 生成一件装备
  ///
  /// [source] 与 [level] 二选一：传 [source] 时按来源掉落表随机等级（推荐），
  /// 传 [level] 时直接指定等级（测试用）
  /// [type] 不传时按掉落概率随机（武器各 15%、饰品各 10%）
  ///
  /// 步骤 1~7：先确定全部词条（不 roll 数值）
  /// 步骤 8：再统一抽取各词条数值，并应用 itemQuality 加强
  GeneratedItem generate({
    ItemSource? source,
    ItemLevel? level,
    ItemType? type,
  }) {
    final resolvedLevel = source?.rollLevel(_random) ?? level;
    if (resolvedLevel == null) {
      throw ArgumentError('source 与 level 必须传入一个');
    }
    if (resolvedLevel == ItemLevel.U) {
      throw UnsupportedError('ItemLevel.U 暂无词条数值数据');
    }
    final resolvedType = type ?? rollType();
    final lines = <ItemLine>[];

    // 第 1 条：必定为白（B 级装备仅此一条）
    lines.add(_drawWithChecks(resolvedType, (l) => l.color == LineColor.white));

    // 第 2 条（A 级及以上）：必定为白
    if (resolvedLevel != ItemLevel.B) {
      lines.add(_drawWithChecks(resolvedType, (l) => l.color == LineColor.white));
    }

    // 第 3 条（L/E 级）：白或红，含步骤 5、6
    if (resolvedLevel == ItemLevel.L || resolvedLevel == ItemLevel.E) {
      lines.add(_drawThirdLine(resolvedType, lines));
    }

    // 第 4 条（E 级）：必定为黄
    if (resolvedLevel == ItemLevel.E) {
      lines.add(_drawFrom(ItemLine.yellowLines));
    }

    // 步骤 8：统一 roll 数值
    final generated = [
      for (final l in lines) GeneratedLine(l, l.rollValue(resolvedLevel, _random)),
    ];

    // itemQuality：加强前 3 条词条（黄词条第 4 槽不受加成）
    final qualityLine =
        generated.where((l) => l.line == ItemLine.itemQuality).firstOrNull;
    if (qualityLine != null) {
      final quality = qualityLine.value;
      for (var i = 0; i < generated.length; i++) {
        final l = generated[i];
        // 跳过黄词条（itemQuality 自身与第 4 槽技能词条）
        if (l.line.color == LineColor.yellow) continue;
        generated[i] = GeneratedLine(
          l.line,
          l.line.applyQualityBoost(l.value, quality),
          rawValue: l.value,
        );
      }
    }

    return GeneratedItem(level: resolvedLevel, type: resolvedType, lines: generated);
  }

  /// 第 3 条抽取（步骤 5、6）
  ///
  /// 第 3 条的结构（3 白 / 2 白 + 1 红）由抽取结果决定：
  /// 从白、红词条池中 roll，抽到白即为 3 白结构，抽到红即为 2 白 + 1 红结构
  ItemLine _drawThirdLine(ItemType type, List<ItemLine> existing) {
    // 初始抽取：白或红（步骤 2~5）
    var line = _drawWithChecks(type, (l) {
      // 步骤 3：品级要求（第 3 槽只允许白或红）
      if (l.color != LineColor.white && l.color != LineColor.red) {
        return false;
      }
      // 步骤 5：不允许出现 3 个同类型词条（含 3 条相同白词条）
      return _sameTypeAllowed(l, existing);
    });

    // 步骤 6：白词条按概率改抽红词条。
    // 重抽时仍校验装备类型（非弓武器绝对不能拿到 multiShot）与同类型上限
    // （否则重抽会绕过步骤 5，造出 3 条 cooldown）
    if (line.color == LineColor.white) {
      final redrawChance = type.isWeapon ? 0.5 : 0.25;
      if (_random.nextDouble() < redrawChance) {
        final pool = ItemLine.redLines
            .where(
                (l) => _typeAllowed(l, type) && _sameTypeAllowed(l, existing))
            .toList(growable: false);
        if (pool.isNotEmpty) {
          line = _drawFrom(pool);
        }
      }
    }
    return line;
  }

  /// 从全部 47 个词条中拒绝采样（步骤 2~4）
  /// [accept] 为步骤 3（品级/颜色要求）及后续附加条件的过滤器
  ItemLine _drawWithChecks(ItemType type, bool Function(ItemLine) accept) {
    for (var i = 0; i < _maxTries; i++) {
      final line = _drawFrom(ItemLine.all);
      // 步骤 4：装备类型要求
      if (!_typeAllowed(line, type)) continue;
      if (accept(line)) return line;
    }
    throw StateError('$_maxTries 次内未抽到合法词条，请检查过滤条件');
  }

  /// 步骤 4：词条是否允许出现在该装备类型上（multiShot 仅弓与饰品）
  bool _typeAllowed(ItemLine line, ItemType type) {
    final allowed = line.allowedTypes;
    return allowed == null || allowed.contains(type);
  }

  /// 步骤 5：抽入后同类型词条数是否仍在允许范围内
  bool _sameTypeAllowed(ItemLine line, List<ItemLine> existing) =>
      existing.where((e) => e.sameType(line)).length < maxSameType;

  /// 从词条池中均匀随机抽取一个
  ItemLine _drawFrom(List<ItemLine> pool) => pool[_random.nextInt(pool.length)];

  /// 按掉落概率随机一个装备类型（武器各 15%，饰品各 10%）
  ItemType rollType() {
    final roll = _random.nextDouble();
    var cumulative = 0.0;
    for (final entry in typeDropRates.entries) {
      cumulative += entry.value;
      if (roll < cumulative) return entry.key;
    }
    return ItemType.values.last; // 兜底：浮点累加误差
  }

  /// 草案演示：随机生成并打印 [count] 件装备（来源随机，类型按掉落概率随机）
  static void demo({int count = 10}) {
    final generator = ItemGenerator();
    for (var i = 0; i < count; i++) {
      final source =
          ItemSource.values[Random().nextInt(ItemSource.values.length)];
      // ignore: avoid_print
      print(generator.generate(source: source));
    }
  }
}
