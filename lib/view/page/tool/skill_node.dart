class SkillNode {
  final String id;
  final double x;
  final double y;
  final String iconPath; // svg路径
  final List<String> prerequisiteIds; // 前置技能id
  bool isUnlocked;

  SkillNode({
    required this.id,
    required this.x,
    required this.y,
    required this.iconPath,
    required this.prerequisiteIds,
    this.isUnlocked = false,
  });

  /// 复制，用于状态更新
  SkillNode copyWith({
    String? id,
    double? x,
    double? y,
    String? iconPath,
    List<String>? prerequisiteIds,
    bool? isUnlocked,
  }) {
    return SkillNode(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      iconPath: iconPath ?? this.iconPath,
      prerequisiteIds: prerequisiteIds ?? this.prerequisiteIds,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}
