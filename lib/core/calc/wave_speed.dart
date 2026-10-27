library;

/// 基础速度
const double baseSpeed = 74;

/// 时挂（TAB）额外跳波数
const double baseTabExtraWave = 44;

/// 游戏速度倍率：2速 / 2速+10广 / 3速
const List<double> gameSpeedRatio = [1, 1.0675, 1.459];

/// 闹钟类型倍率：白 / 黄 / 蓝
const List<double> chronoBonusRatio = [1, 1.037, 1.083];

/// 10%角倍率
const double hornRatio = 1.104;

/// 30%角倍率
const double goldenHornRatio = 1.365;

double getWph({
  required int devilHornSkip,
  required bool isGoldAutoBattle,
  required int gameSpeed,
  required int chronoBonus,
  required bool equipHorn,
  required bool equipGoldenHorn,
}) {
  return (baseSpeed * devilHornSkip + (isGoldAutoBattle ? 0 : baseTabExtraWave)) *
      gameSpeedRatio[gameSpeed] *
      chronoBonusRatio[chronoBonus] *
      (equipHorn ? hornRatio : 1) *
      (equipGoldenHorn ? goldenHornRatio : 1);
}

double getRwph({
  required int gameSpeed,
  required int chronoBonus,
  required bool equipHorn,
  required bool equipGoldenHorn,
}) {
  return baseSpeed *
      gameSpeedRatio[gameSpeed] *
      chronoBonusRatio[chronoBonus] *
      (equipHorn ? hornRatio : 1) *
      (equipGoldenHorn ? goldenHornRatio : 1);
}