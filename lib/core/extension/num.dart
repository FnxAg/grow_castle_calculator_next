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
}

/// 千位加分隔符
String _thousands(String text) {
  return text.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
}