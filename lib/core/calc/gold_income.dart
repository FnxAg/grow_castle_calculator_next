library;

import 'wave_speed.dart';

const List<double> goldCalcGameSpeed = [2, (200 * 3 + 1240 * 2) / 1440, 3];
const List<double> goldCalcChronoBonus = [0.10, 0.14, 0.20];

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
  final f0 =
      goldCalcGameSpeed[gameSpeed] * (1 + goldCalcChronoBonus[chronoBonus]);
  final rwph = getRwph(
    gameSpeed: gameSpeed,
    chronoBonus: chronoBonus,
    equipHorn: equipHorn,
    equipGoldenHorn: equipGoldenHorn,
  );
  final secondsPerWave = 3600 / rwph;
  final f5 = icGoldSkill + (equipWhip ? 15 : 0);

  // 波间间隔时间 / s
  const double waveInterval = 1.0;

  final goldPerCart =
      (infiniteColony * 5400 + 1374406) / 1.2 * (1.2 + 0.01 * f5);
  final secondsPerCart =
      60 / ((icCooldownSkill * 0.005 + 1.1) + (equipWheel ? 0.15 : 0));
  final cartsPerHour =
      ((secondsPerWave - waveInterval) * f0 + waveInterval) *
      3600 /
      secondsPerWave /
      secondsPerCart;
  final colonyGoldPerDay = goldPerCart * cartsPerHour * 24;

  final adGold = w0 * 2160;
  final gabCost = 456.0 * w0 - 29264;
  final gabBenefitGoldPerWave = gabCost * gabBonus * 0.01;
  final gabBenefitGoldPerHour = 3600 / secondsPerWave * gabBenefitGoldPerWave;
  final gabBenefitGoldPerDay = gabBenefitGoldPerHour * gabTime;

  final tabGoldPerWave = gabCost * (1 + gabBonus * 0.01);
  final tabGoldPerHour = tabGoldPerWave * (3600 / secondsPerWave);
  final tabGoldPerDay = tabGoldPerHour * tabTime;

  final goldenTreeGoldPerHour = 48 / 456 * gabCost * 3600 / secondsPerWave / 2;
  final goldenTreeGoldPerDay = goldenTree
      ? ((gabTime + tabTime) * goldenTreeGoldPerHour)
      : 0.0;

  final seasonalColonyGoldPerHour = 16 * adGold / 24;
  final seasonalColonyGoldPerDay = seasonColony
      ? seasonalColonyGoldPerHour * 24
      : 0.0;

  return (
    colony: colonyGoldPerDay,
    autoBattle: gabBenefitGoldPerDay + tabGoldPerDay,
    other: goldenTreeGoldPerDay + seasonalColonyGoldPerDay,
    total:
        colonyGoldPerDay +
        gabBenefitGoldPerDay +
        tabGoldPerDay +
        goldenTreeGoldPerDay +
        seasonalColonyGoldPerDay,
  );
}

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

int gabCost(int wave) {
  return 456 * wave - 29264;
}

double calcGp({required num wave, required num gold}) {
  return gold / (0.5 * (310 + wave * 310) * wave) * 100;
}

double calcGpCN({required num wave, required num gold}) {
  return gold / (wave * wave);
}
