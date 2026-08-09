import '../src/item_lines.dart';

/// 装备对比中的一条词条加成（词条类型 + 装备上显示的数值）
typedef ItemDpsLine = ({ItemLine line, double value});

/// 单件装备的期望 DPS 计算结果
class ItemDpsResult {
  const ItemDpsResult({
    required this.normalHit,
    required this.critHit,
    required this.dps,
    this.aps,
  });

  /// 普通一击伤害
  final double normalHit;

  /// 暴击一击伤害
  final double critHit;

  /// 期望 DPS（暴击与非暴击的加权平均）
  final double dps;

  /// 每秒攻击次数；面板 Attacks Per Second 与 Increased Speed
  /// 未填齐时为 null（此时 DPS 为纯每击数值，Attack Speed 词条不参与）
  final double? aps;
}

/// 计算装备词条加成后的期望 DPS。
///
/// 模型（暴击伤害为倍率形式）：
/// - 每击伤害 = (基础攻击 + 词条固定伤害) × (1 + 增伤/100) × More 倍率
/// - 增伤累加：[increasedDmg] 与 [elementDmgLines]（元素伤害，与普通增伤
///   无差异）及 Damage % 词条累加；More 倍率 = Π(1 + 每条 More Dmg/100)，
///   面板 More Dmg 与 [moreDmgLines] 各自累乘，如面板 200% + 词条 30%
///   的倍率为 (1 + 200/100) × (1 + 30/100) = 3.9
/// - 暴击一击 = 普通一击 × 暴击伤害/100（如 250 表示暴击造成 2.5 倍普通伤害）
/// - DPS = 暴击率 × 暴击一击 + (1 − 暴击率) × 普通一击（暴击率上限 100%）
///
/// 攻击速度：[baseAps]（面板 Attacks Per Second，已是 Increased Speed
/// 加成后的每秒攻击次数）与 [increasedSpeed]（面板 Increased Speed）都传入
/// （非 null）时，先反推基础攻击次数 = [baseAps] / (1 + [increasedSpeed] / 100)，
/// 再叠加词条 Attack Speed：每秒攻击次数 =
/// 基础攻击次数 × (1 + (词条 Attack Speed + [increasedSpeed]) / 100)，
/// DPS 乘以攻击次数；缺少任一则为纯每击数值，Attack Speed 词条不参与。
///
/// [increasedDmg]、[moreDmg]、[critChance] 为百分比数值（如 500 表示 +500%）。
/// [lines] 为装备的 DPS 相关白词条及数值；无关词条会被忽略。
/// [moreDmgLines]、[elementDmgLines] 为白词条池外的特殊词条数值
/// （More Dmg / 整合的 Element Damage）。
ItemDpsResult computeItemDps({
  required double baseAttack,
  required double increasedDmg,
  required double moreDmg,
  required double critChance,
  required double critDmg,
  List<ItemDpsLine> lines = const [],
  List<double> moreDmgLines = const [],
  List<double> elementDmgLines = const [],
  double? baseAps,
  double? increasedSpeed,
}) {
  var effBase = baseAttack;
  var effIncreased = increasedDmg;
  var effCritChance = critChance;
  var effCritDmg = critDmg;
  var effSpeed = 0.0;

  for (final (:line, :value) in lines) {
    switch (line) {
      case ItemLine.damageInt:
        effBase += value;
      case ItemLine.damagePercent:
        effIncreased += value;
      case ItemLine.criticalChance:
        effCritChance += value;
      case ItemLine.criticalDamage:
        effCritDmg += value;
      case ItemLine.attackSpeed:
        effSpeed += value;
      default:
        break; // 其余词条不影响本 DPS 模型
    }
  }
  for (final value in elementDmgLines) {
    effIncreased += value; // 元素伤害与普通增伤无差异
  }
  effCritChance = effCritChance.clamp(0, 100);

  // More Dmg 累乘：面板 1 条 + 装备词条若干条
  var moreMultiplier = 1 + moreDmg / 100;
  for (final value in moreDmgLines) {
    moreMultiplier *= 1 + value / 100;
  }

  final normalHit = effBase * (1 + effIncreased / 100) * moreMultiplier;
  final critHit = normalHit * effCritDmg / 100;
  var dps = normalHit * (1 + effCritChance / 100 * (effCritDmg / 100 - 1));

  // 攻击速度：面板两项都填写后才计算，否则回退纯每击数值。
  // 面板 APS 已是 IS 加成后的每秒攻击次数，无词条时直接使用（与面板一致）；
  // 有词条时反推基础攻击次数再叠加词条 IS
  double? aps;
  if (baseAps != null && increasedSpeed != null) {
    if (effSpeed == 0) {
      aps = baseAps;
    } else {
      final baseAttacks = baseAps / (1 + increasedSpeed / 100);
      aps = baseAttacks * (1 + (increasedSpeed + effSpeed) / 100);
    }
    dps *= aps;
  }

  return ItemDpsResult(normalHit: normalHit, critHit: critHit, dps: dps, aps: aps);
}
