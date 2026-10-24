import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grow_castle_calculator_next/view/page/tool/skill_node.dart';
import 'package:grow_castle_calculator_next/view/page/tool/skill_tree_provider.dart';

class SkillNodeWidget extends ConsumerWidget {
  final SkillNode node;
  const SkillNodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skillTreeProvider);
    // 判断前置是否全部解锁（可解锁状态）
    bool canUnlock = node.prerequisiteIds.every((preId) {
      return state.nodes.firstWhere((n) => n.id == preId).isUnlocked;
    });

    return GestureDetector(
      onTap: () {
        ref.read(skillTreeProvider.notifier).tryUnlock(node.id);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: node.isUnlocked
              ? const Color(0xff2288aa)
              : canUnlock
                  ? const Color(0xff444444)
                  : const Color(0xff2a2a2a),
          border: Border.all(
            width: 2,
            color: node.isUnlocked
                ? const Color(0xfffce043)
                : canUnlock
                    ? Colors.grey.shade400
                    : Colors.grey.shade700,
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            node.iconPath,
            width: 26,
            height: 26,
            colorFilter: ColorFilter.mode(
              node.isUnlocked ? Colors.white : Colors.grey.shade500,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
