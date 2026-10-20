library;

import 'dart:math' as math;

/// 由波数与总金币得到 GP
double gpFromWaveGold(double wave, double gold) =>
    gold * 100 / (155 * wave * (wave + 1));

/// 由波数与总金币得到指数
double gpCNFromWaveGold(double wave, double gold) => gold / (wave * wave);

/// 由波数与 GP 得到总金币
double goldFromWaveGp(double wave, double gp) =>
    gp * 155 * wave * (wave + 1) / 100;

/// 由波数与指数得到总金币
double goldFromWaveGpCN(double wave, double gpCN) => gpCN * wave * wave;

/// 由总金币与 GP 得到波数；无正解时返回 null
double? waveFromGoldGp(double gold, double gp) {
  if (gold <= 0 || gp <= 0) return null;
  // 解 w² + w - 20g/(31p) = 0
  final c = 20 * gold / (31 * gp);
  final wave = (math.sqrt(1 + 4 * c) - 1) / 2;
  return wave > 0 ? wave : null;
}

/// 由总金币与指数得到波数；无正解时返回 null
double? waveFromGoldGpCN(double gold, double gpCN) {
  if (gold <= 0 || gpCN <= 0) return null;
  return math.sqrt(gold / gpCN);
}

/// 由 GP 与指数得到波数；无正解时返回 null
double? waveFromGpGpCN(double gp, double gpCN) {
  if (gp <= 0 || gpCN <= 0) return null;
  // gp / 指数 = 20w / (31(w + 1))
  final ratio = gp / gpCN;
  final denominator = 20 - 31 * ratio;
  if (denominator <= 0) return null;
  final wave = 31 * ratio / denominator;
  return wave > 0 ? wave : null;
}
