/// 跳波状态计算：每小时跳波数（WPH）与各项加成。
///
/// 数值与公式沿用旧项目 grow_castle_calculator 的 wave_speed_query_provider，
/// 纯函数无 Flutter 依赖，便于测试与复用。
library;

/// 基础速度（无任何加成时每小时的跳波数）
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

/// 每小时跳波数（WPH）。
///
/// [gameSpeed] 与 [chronoBonus] 为对应常量列表的下标；
/// [isGoldAutoBattle] 为 true（金挂 GAB）时无 TAB 额外跳波。
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
