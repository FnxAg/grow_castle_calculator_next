import 'item_generator.dart';
import 'item_lines.dart';

/// 单个词条的要求：数量 + 数值范围（null 表示不限）
class LineCondition {
  const LineCondition({this.count = 1, this.minValue, this.maxValue});

  /// 至少出现的条数（白词条可同时出现两条）
  final int count;

  /// 数值下限：词条的原始值（加强前的值）须大于 [minValue]；null 表示不限
  final double? minValue;

  /// 数值上限：词条的原始值（加强前的值）须小于 [maxValue]；null 表示不限
  final double? maxValue;

  /// 数值（加强前的原始值）是否满足范围
  bool valueSatisfies(double value) {
    final min = minValue;
    if (min != null && !(value > min)) return false;
    final max = maxValue;
    if (max != null && !(value < max)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'minValue': minValue,
        'maxValue': maxValue,
      };

  factory LineCondition.fromJson(Map<String, dynamic> json) => LineCondition(
        count: json['count'] is int && json['count'] >= 1
            ? json['count'] as int
            : 1,
        minValue: (json['minValue'] as num?)?.toDouble(),
        maxValue: (json['maxValue'] as num?)?.toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is LineCondition &&
      other.count == count &&
      other.minValue == minValue &&
      other.maxValue == maxValue;

  @override
  int get hashCode => Object.hash(count, minValue, maxValue);
}

/// 用户自定义高亮规则：选择一组必须出现的词条（可指定数量与数值范围），
/// 可指定装备类型。装备的类型符合限制，且每个所选词条中
/// 至少有要求数量条满足数值范围（未设范围则不限数值）即命中，
/// 由界面高亮并可置顶。
///
/// 数值判断使用词条的原始值（itemQuality 加强前的值）。
///
/// 规则由用户在"高亮规则"管理页自行配置，可设置多条；
/// 同一件装备命中多条规则时，列表顺序靠前者生效（顺序即优先级）。
class UserHighlightRule {
  const UserHighlightRule({
    required this.id,
    required this.hint,
    required this.lines,
    this.pinToTop = true,
    this.enabled = true,
    this.types,
  });

  /// 唯一标识
  final String id;

  /// 提示文本（界面徽标显示；可留空）
  final String hint;

  /// 必须出现的词条组合及要求（数量 + 数值范围）。
  /// 白词条可同时出现两条，如 {ItemLine.cooldown: LineCondition(count: 2)}
  final Map<ItemLine, LineCondition> lines;

  /// 命中后是否置顶显示
  final bool pinToTop;

  /// 是否启用；未启用的规则不参与匹配（高亮与 roll到死 均忽略）
  final bool enabled;

  /// 指定装备类型限制；null 或空表示不限类型。
  /// 注意：copyWith 传 null 表示保持原值，无法借此清空限制，清空请直接构造新规则
  final Set<ItemType>? types;

  /// 装备是否命中：类型符合限制，且每个所选词条中
  /// 至少有要求数量条满足数值范围（数值判断用加强前的原始值）
  bool matches(GeneratedItem item) {
    final allowedTypes = types;
    if (allowedTypes != null && !allowedTypes.contains(item.type)) {
      return false;
    }
    for (final entry in lines.entries) {
      var matched = 0;
      for (final line in item.lines) {
        if (line.line != entry.key) continue;
        // 加强词条用 rawValue（加强前的原始值）判断
        if (!entry.value.valueSatisfies(line.rawValue ?? line.value)) continue;
        matched++;
      }
      if (matched < entry.value.count) return false;
    }
    return true;
  }

  UserHighlightRule copyWith({
    String? hint,
    Map<ItemLine, LineCondition>? lines,
    bool? pinToTop,
    bool? enabled,
    Set<ItemType>? types,
  }) =>
      UserHighlightRule(
        id: id,
        hint: hint ?? this.hint,
        lines: lines ?? this.lines,
        pinToTop: pinToTop ?? this.pinToTop,
        enabled: enabled ?? this.enabled,
        types: types ?? this.types,
      );

  Map<String, dynamic> toJson() {
    final types = this.types;
    return {
      'id': id,
      'hint': hint,
      'lines': [
        for (final entry in lines.entries)
          {'name': entry.key.name, ...entry.value.toJson()},
      ],
      'pinToTop': pinToTop,
      'enabled': enabled,
      'types': types == null ? null : [for (final type in types) type.name],
    };
  }

  factory UserHighlightRule.fromJson(Map<String, dynamic> json) {
    // 词条组合：新格式为 [{name, count, minValue, maxValue}]，
    // 旧格式为 [词条名...]（每条按 1 条、不限数值解析）
    final rawLines = json['lines'];
    final lines = <ItemLine, LineCondition>{};
    if (rawLines is List) {
      for (final raw in rawLines) {
        if (raw is String) {
          for (final line in ItemLine.values) {
            if (line.name == raw) lines[line] = const LineCondition();
          }
        } else if (raw is Map) {
          final name = raw['name'];
          if (name is String) {
            for (final line in ItemLine.values) {
              if (line.name == name) {
                lines[line] = LineCondition.fromJson(
                  Map<String, dynamic>.from(raw),
                );
              }
            }
          }
        }
      }
    }
    // 缺失、null 或空列表均视为不限类型
    final rawTypes = json['types'];
    Set<ItemType>? types;
    if (rawTypes is List && rawTypes.isNotEmpty) {
      types = {
        for (final name in rawTypes)
          if (name is String)
            for (final type in ItemType.values)
              if (type.name == name) type,
      };
    }
    return UserHighlightRule(
      id: json['id'] as String? ?? newRuleId(),
      hint: json['hint'] as String? ?? '',
      lines: lines,
      pinToTop: json['pinToTop'] as bool? ?? true,
      enabled: json['enabled'] as bool? ?? true,
      types: types,
    );
  }
}

/// 生成规则唯一标识
String newRuleId() => DateTime.now().microsecondsSinceEpoch.toString();

/// 匹配命中装备的第一条已启用规则（列表顺序即优先级）；未命中返回 null。
/// 未启用的规则（[UserHighlightRule.enabled] 为 false）自动跳过。
UserHighlightRule? matchRule(
  GeneratedItem item,
  List<UserHighlightRule> rules,
) {
  for (final rule in rules) {
    if (!rule.enabled) continue;
    if (rule.matches(item)) return rule;
  }
  return null;
}
