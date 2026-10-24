import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/view/page/tool/skill_line_painter.dart';
import 'package:grow_castle_calculator_next/view/page/tool/skill_node_widget.dart';
import 'package:grow_castle_calculator_next/view/page/tool/skill_tree_provider.dart';

class SkillTreePage extends ConsumerWidget {
  const SkillTreePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skillTreeProvider);
    final nextWavePoint = SkillTreeNotifier.waveForNextPoint - (state.totalWaves % SkillTreeNotifier.waveForNextPoint);

    return Scaffold(
      backgroundColor: const Color(0xff2c2c2c),
      body: Column(
        children: [
          // 顶部状态栏，和截图样式一致
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black45,
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  "${state.skillPoints} / ${state.skillPoints}",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const Spacer(),
                Text(
                  "下一个技能点: $nextWavePoint 波",
                  style: const TextStyle(color: Color(0xff89ff6c), fontSize: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.3,
              maxScale: 2.2,
              boundaryMargin: const EdgeInsets.all(2000),
              child: Stack(
                children: [
                  // 底层连线
                  CustomPaint(
                    painter: SkillLinePainter(nodes: state.nodes),
                    size: const Size(2000, 2000),
                  ),
                  // 所有节点
                  ...state.nodes.map((node) {
                    return Positioned(
                      left: node.x,
                      top: node.y,
                      child: SkillNodeWidget(node: node),
                    );
                  })
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
