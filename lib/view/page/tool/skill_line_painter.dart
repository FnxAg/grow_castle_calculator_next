import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/page/tool/skill_node.dart';

class SkillLinePainter extends CustomPainter {
  final List<SkillNode> nodes;

  SkillLinePainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..strokeWidth = 2.5..style = PaintingStyle.stroke;

    for (final node in nodes) {
      for (final preId in node.prerequisiteIds) {
        final parent = nodes.firstWhere((e) => e.id == preId);
        // 圆心位置（节点宽高48，半径24）
        final from = Offset(parent.x + 24, parent.y + 24);
        final to = Offset(node.x + 24, node.y + 24);

        // 父子都解锁：黄色，否则灰色
        if (parent.isUnlocked && node.isUnlocked) {
          linePaint.color = const Color(0xfffce043);
        } else if (parent.isUnlocked) {
          linePaint.color = const Color(0xff999999);
        } else {
          linePaint.color = const Color(0xff555555);
        }
        canvas.drawLine(from, to, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkillLinePainter oldDelegate) {
    // 节点解锁状态变化时重绘
    return true;
  }
}
