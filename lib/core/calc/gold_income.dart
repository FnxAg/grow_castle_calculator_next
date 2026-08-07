/// 每日收入计算：按收入来源分项汇总（殖民地 / 金挂 / 时挂 / 大树 / 赛季殖民地）。
///
/// 公式沿用旧项目 grow_castle_calculator 的 gold_calculator_provider，
/// 纯函数无 Flutter 依赖，便于测试与复用。
/// 新增「鞭子」：启用时完全等同于额外殖民地G +15。
library;

import 'wave_speed.dart';

/// 游戏速度数值（f0 的速度部分）：2速 / 2速+10广 / 3速
///
/// “2速+10广”= 每天看 10 个广告（每个 20 分钟三倍速），即 200 分钟 3 速 +
/// 1240 分钟 2 速的时间加权平均：(200 * 3 + 1240 * 2) / 1440 = 2.138888…
const List<double> goldCalcGameSpeed = [2, (200 * 3 + 1240 * 2) / 1440, 3];

/// 闹钟加成（f0 的加成部分）：白 +10% / 黄 +14% / 蓝 +20%
const List<double> goldCalcChronoBonus = [0.10, 0.14, 0.20];

/// 每日收入分项汇总（金币）。
///
/// 返回按收入来源分组的四项：
/// - [colony] 殖民地收入（殖民地 tab）
/// - [autoBattle] 挂机收入（金挂 + 时挂，推波 tab）
/// - [other] 其他收入（金币大树 + 赛季殖民地，其他 tab）
/// - [total] 每日总收入
///
/// 与旧项目 gold_calculator_provider.computeDailyIncome 的字段对应关系：
/// - [wave] 当前总波数 → w0（旧项目手填，默认 100 万；本项目用联网同步的真实波数）
/// - [gameSpeed] 游戏速度下标与 [chronoBonus] 闹钟下标共同决定
///   f0 = goldCalcGameSpeed[gameSpeed] * (1 + goldCalcChronoBonus[chronoBonus])
///   （如 2速+白闹钟 = 2 × 1.10 = 2.2；旧项目为手填倍率）
/// - 单波时间 f2（s）由当前跳波参数推导：f2 = 3600 / rwph，故恒 > 0，
///   旧项目里 `f2 == 0` 的兜底分支不再需要
/// - [infiniteColony] 殖民地等级 → f3；[icCooldownSkill] 额外殖民地C → f4
/// - [icGoldSkill] 额外殖民地G → f5；[equipWhip] 鞭子 → f5 额外 +15
/// - [gabTime] 每日金挂时间（h）→ f6；[gabBonus] 金挂平均收益（%）→ f7
/// - [tabTime] 每日时挂时间（h）→ f8
/// - [equipWheel] 车轮 / [goldenTree] 金币大树 / [seasonColony] 赛季殖民地
({double colony, double autoBattle, double other, double total})
    getDailyIncomeBreakdown({
  required int wave,
  required int gameSpeed,
  required int chronoBonus,
  required bool equipHorn,
  required bool equipGoldenHorn,
  required int infiniteColony,
  required int icCooldownSkill,
  required int icGoldSkill,
  required bool equipWheel,
  required bool equipWhip,
  required double gabTime,
  required double gabBonus,
  required double tabTime,
  required bool seasonColony,
  required bool goldenTree,
}) {
  final w0 = wave;
  // f0 = 游戏速度数值 × (1 + 闹钟加成)，两值均来自跳波状态页的选择
  final f0 = goldCalcGameSpeed[gameSpeed] * (1 + goldCalcChronoBonus[chronoBonus]);
  final rwph = getRwph(
    gameSpeed: gameSpeed,
    chronoBonus: chronoBonus,
    equipHorn: equipHorn,
    equipGoldenHorn: equipGoldenHorn,
  );
  final secondsPerWave = 3600 / rwph;
  final f5 = icGoldSkill + (equipWhip ? 15 : 0);

  // 波间间隔
  const double waveInterval = 1.0;

  // 殖民地：单次车收益 × 每小时车数 × 24h
  final goldPerCart = (infiniteColony * 5400 + 1374406) / 1.2 * (1.2 + 0.01 * f5);
  final secondsPerCart =
      60 / ((icCooldownSkill * 0.005 + 1.1) + (equipWheel ? 0.15 : 0));
  final cartsPerHour = ((secondsPerWave - waveInterval) * f0 + waveInterval) * 3600 / secondsPerWave / secondsPerCart;
  final colonyGoldPerDay = goldPerCart * cartsPerHour * 24;

  // 金挂 / 时挂：以金挂成本为基准
  final adGold = w0 * 2160;
  final gabCost = 456.0 * w0 - 29264;
  final gabBenefitGoldPerWave = gabCost * gabBonus * 0.01;
  final gabBenefitGoldPerHour = 3600 / secondsPerWave * gabBenefitGoldPerWave;
  final gabBenefitGoldPerDay = gabBenefitGoldPerHour * gabTime;

  final tabGoldPerWave = gabCost * (1 + gabBonus * 0.01);
  final tabGoldPerHour = tabGoldPerWave * (3600 / secondsPerWave);
  final tabGoldPerDay = tabGoldPerHour * tabTime;

  // 金币大树：收益随金挂+时挂时长线性增长
  final goldenTreeGoldPerHour = 48 / 456 * gabCost * 3600 / secondsPerWave / 2;
  final goldenTreeGoldPerDay =
      goldenTree ? ((gabTime + tabTime) * goldenTreeGoldPerHour) : 0.0;

  // 赛季殖民地
  final seasonalColonyGoldPerHour = 16 * adGold / 24;
  final seasonalColonyGoldPerDay =
      seasonColony ? seasonalColonyGoldPerHour * 24 : 0.0;

  return (
    colony: colonyGoldPerDay,
    autoBattle: gabBenefitGoldPerDay + tabGoldPerDay,
    other: goldenTreeGoldPerDay + seasonalColonyGoldPerDay,
    total: colonyGoldPerDay +
        gabBenefitGoldPerDay +
        tabGoldPerDay +
        goldenTreeGoldPerDay +
        seasonalColonyGoldPerDay,
  );
}

/// 每日总收入（金币），为 [getDailyIncomeBreakdown] 的 total 分项。
double getDailyIncome({
  required int wave,
  required int gameSpeed,
  required int chronoBonus,
  required bool equipHorn,
  required bool equipGoldenHorn,
  required int infiniteColony,
  required int icCooldown,
  required int icGold,
  required bool equipWheel,
  required bool equipWhip,
  required double gabTime,
  required double gabBonus,
  required double tabTime,
  required bool seasonColony,
  required bool goldenTree,
}) {
  return getDailyIncomeBreakdown(
    wave: wave,
    gameSpeed: gameSpeed,
    chronoBonus: chronoBonus,
    equipHorn: equipHorn,
    equipGoldenHorn: equipGoldenHorn,
    infiniteColony: infiniteColony,
    icCooldownSkill: icCooldown,
    icGoldSkill: icGold,
    equipWheel: equipWheel,
    equipWhip: equipWhip,
    gabTime: gabTime,
    gabBonus: gabBonus,
    tabTime: tabTime,
    seasonColony: seasonColony,
    goldenTree: goldenTree,
  ).total;
}
