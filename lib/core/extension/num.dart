/// 英文缩写单位的显示风格
enum CompactEnglishStyle {
  /// 标准
  standard,

  /// 游戏内
  game,
}

extension IntNumFormat on int {
  /// 千位分隔符格式化
  String format() => _thousands(toString());

  String formatCompact({
    int fractionDigits = 2,
    bool english = false,
    bool traditional = false,
    CompactEnglishStyle englishStyle = CompactEnglishStyle.standard,
  }) => (toDouble()).formatCompact(
    fractionDigits: fractionDigits,
    english: english,
    traditional: traditional,
    englishStyle: englishStyle,
  );
}

extension DoubleNumFormat on double {
  String format({int fractionDigits = 2}) {
    if (isNaN || isInfinite) return toString();
    final text = this == roundToDouble()
        ? toStringAsFixed(0)
        : toStringAsFixed(fractionDigits);
    return _thousands(text);
  }

  /// 数量级缩写
  String formatCompact({
    int fractionDigits = 2,
    bool english = false,
    bool traditional = false,
    CompactEnglishStyle englishStyle = CompactEnglishStyle.standard,
  }) {
    if (isNaN || isInfinite) return toString();
    final units = english
        ? const <(double, String)>[
            (1e18, 'E'),
            (1e15, 'P'),
            (1e12, 'T'),
            (1e9, 'B'),
            (1e6, 'M'),
            (1e3, 'K'),
          ]
        : traditional
        ? const <(double, String)>[
            (1e16, '億億'),
            (1e12, '萬億'),
            (1e8, '億'),
            (1e4, '萬'),
          ]
        : const <(double, String)>[
            (1e16, '亿亿'),
            (1e12, '万亿'),
            (1e8, '亿'),
            (1e4, '万'),
          ];
    final gameStyle = english && englishStyle == CompactEnglishStyle.game;
    for (var i = 0; i < units.length; i++) {
      final (threshold, suffix) = units[i];
      if (this < threshold) continue;
      if (gameStyle) {
        // 单位降一档，只保留整数部分；K 以下不再带单位
        final (lowerThreshold, lowerSuffix) = i + 1 < units.length
            ? units[i + 1]
            : (1.0, '');
        final scaled = this / lowerThreshold;
        final text = scaled.truncateToDouble().toStringAsFixed(0);
        return '${_thousands(text)}$lowerSuffix';
      }
      final scaled = this / threshold;
      final text = scaled == scaled.roundToDouble()
          ? scaled.toStringAsFixed(0)
          : scaled.toStringAsFixed(fractionDigits);
      return '$text$suffix';
    }
    return gameStyle ? truncateToDouble().toStringAsFixed(0) : toStringAsFixed(0);
  }
}

/// 千位加分隔符
String _thousands(String text) {
  final dot = text.indexOf('.');
  final intPart = dot < 0 ? text : text.substring(0, dot);
  final fracPart = dot < 0 ? '' : text.substring(dot);
  final formatted = intPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '$formatted$fracPart';
}
