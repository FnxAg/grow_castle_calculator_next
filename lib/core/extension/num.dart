extension IntNumFormat on int {
  /// 千位分隔符格式化
  String format() => _thousands(toString());
}

extension DoubleNumFormat on double {
  /// 千位分隔符格式化
  /// [fractionDigits] 小数位数，默认为 2
  String format({int fractionDigits = 2}) {
    if (isNaN || isInfinite) return toString();
    final text = this == roundToDouble()
        ? toStringAsFixed(0)
        : toStringAsFixed(fractionDigits);
    return _thousands(text);
  }

  /// 数量级缩写：中文语境用 万/亿/万亿/亿亿，英文语境用 K/M/B/T/P/E，
  /// 用于汇总表等紧凑场景，避免大额金币占用过多横向空间
  String formatCompact({int fractionDigits = 2, bool english = false}) {
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
        : const <(double, String)>[
            (1e16, '亿亿'),
            (1e12, '万亿'),
            (1e8, '亿'),
            (1e4, '万'),
          ];
    for (final (threshold, suffix) in units) {
      if (this >= threshold) {
        final scaled = this / threshold;
        final text = scaled == scaled.roundToDouble()
            ? scaled.toStringAsFixed(0)
            : scaled.toStringAsFixed(fractionDigits);
        return '$text$suffix';
      }
    }
    return toStringAsFixed(0);
  }
}

/// 千位加分隔符（仅作用于整数部分，避免小数位被错误插入逗号）
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