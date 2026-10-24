import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:grow_castle_calculator_next/view/page/tool/skill_node.dart';

part 'skill_tree_provider.g.dart';

@riverpod
class SkillTreeNotifier extends _$SkillTreeNotifier {
  // 总波数，用来计算下一个技能点
  static const int waveForNextPoint = 5000;

  @override
  SkillTreeState build() {
    // 初始化节点，这里模拟你截图里闪电分支
    final List<SkillNode> initNodes = [
      SkillNode(
        id: "s0",
        x: 400,
        y: 220,
        iconPath: "assets/svg/box.svg",
        prerequisiteIds: [],
        isUnlocked: true,
      ),
      SkillNode(
        id: "s1",
        x: 460,
        y: 140,
        iconPath: "assets/svg/box.svg",
        prerequisiteIds: ["s0"],
      ),
      SkillNode(
        id: "s2",
        x: 340,
        y: 140,
        iconPath: "assets/svg/box.svg",
        prerequisiteIds: ["s0"],
      ),
      SkillNode(
        id: "s3",
        x: 520,
        y: 220,
        iconPath: "assets/svg/box.svg",
        prerequisiteIds: ["s1"],
      ),
      SkillNode(
        id: "s4",
        x: 400,
        y: 300,
        iconPath: "assets/svg/box.svg",
        prerequisiteIds: ["s0"],
      ),
    ];

    return SkillTreeState(
      nodes: initNodes,
      totalWaves: 39 * waveForNextPoint,
      skillPoints: 39,
    );
  }

  /// 尝试解锁技能
  void tryUnlock(String nodeId) {
    final nodeIndex = state.nodes.indexWhere((e) => e.id == nodeId);
    if (nodeIndex < 0) return;
    final targetNode = state.nodes[nodeIndex];

    // 已经解锁直接返回
    if (targetNode.isUnlocked) return;

    // 校验前置全部解锁
    final allPrereqOk = targetNode.prerequisiteIds.every((preId) {
      return state.nodes.firstWhere((n) => n.id == preId).isUnlocked;
    });
    if (!allPrereqOk) return;

    // 技能点充足
    if (state.skillPoints <= 0) return;

    // 解锁
    final newNodes = [...state.nodes];
    newNodes[nodeIndex] = newNodes[nodeIndex].copyWith(isUnlocked: true);

    state = state.copyWith(
      nodes: newNodes,
      skillPoints: state.skillPoints - 1,
    );
  }

  /// 增加波数，自动获得技能点
  void addWave(int add) {
    final newTotalWave = state.totalWaves + add;
    int newPoints = newTotalWave ~/ waveForNextPoint;
    state = state.copyWith(
      totalWaves: newTotalWave,
      skillPoints: newPoints,
    );
  }
}

class SkillTreeState {
  final List<SkillNode> nodes;
  final int totalWaves;
  final int skillPoints;

  SkillTreeState({
    required this.nodes,
    required this.totalWaves,
    required this.skillPoints,
  });

  SkillTreeState copyWith({
    List<SkillNode>? nodes,
    int? totalWaves,
    int? skillPoints,
  }) {
    return SkillTreeState(
      nodes: nodes ?? this.nodes,
      totalWaves: totalWaves ?? this.totalWaves,
      skillPoints: skillPoints ?? this.skillPoints,
    );
  }
}
