library;

double heroLevelSpendGold(int level) {
  if (level <= 0) return 0;

  const thresholds = [
    10000, 5000, 200, 180, 160, 140, 120, 100, 80, 60, 40, 20, 1,
  ];
  const baseGold = [
    187458432500, 37468432500, 35632500, 26157500, 18530000, 12530000,
    7997500, 4712500, 2475000, 1085000, 342500, 47500, 0,
  ];
  const baseMultiplier = [
    50000000, 20000000, 600000, 450000, 360000, 280000, 210000, 150000,
    100000, 60000, 30000, 10000, 250,
  ];
  const increment = [
    5000, 4000, 3000, 2500, 2250, 2000, 1750, 1500, 1250, 1000, 750, 500, 250,
  ];

  for (int i = 0; i < thresholds.length; i++) {
    if (level > thresholds[i]) {
      final diff = level - thresholds[i];
      return ((baseMultiplier[i] * 2 + increment[i] * (diff - 1)) / 2 * diff) +
          baseGold[i];
    }
  }

  return 0;
}

double unitLevelSpendGold(int level, int id) {
  switch (id) {
    case 1:
      return level * level * 1250;
    case 2:
      return level * level * 500;
    default:
      return heroLevelSpendGold(level);
  }
}
