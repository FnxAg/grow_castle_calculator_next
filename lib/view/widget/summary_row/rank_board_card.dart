import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// 排名面板中的一行数据
class RankBoardRow {
  const RankBoardRow({
    required this.rank,
    required this.name,
    this.value,
    this.gapText,
    this.gapColor,
    this.highlight = false,
  });

  /// 名次；未加载时为 null
  final int? rank;

  /// 玩家 / 公会名称
  final String name;

  /// 右侧主数值（当前行使用）
  final String? value;

  /// 右侧差值文本（上一名 / 下一名使用）
  final String? gapText;

  /// 差值胶囊底色
  final Color? gapColor;

  /// 是否高亮当前名次
  final bool highlight;
}

/// 排名概览卡片：标题 + 上一名 / 自己 / 下一名
///
/// 所有行都按比例伸缩并省略超长文本，窄屏不会横向溢出。
class RankBoardCard extends StatelessWidget {
  const RankBoardCard({
    super.key,
    required this.icon,
    required this.title,
    this.previous,
    this.current,
    this.next,
    this.previousAnimation,
    this.nextAnimation,
  });

  final IconData icon;
  final String title;
  final RankBoardRow? previous;
  final RankBoardRow? current;
  final RankBoardRow? next;
  final Animation<double>? previousAnimation;
  final Animation<double>? nextAnimation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SummaryCard(
      children: [
        Row(
          children: [
            Icon(icon, size: SummaryRow.leadingIconSize, color: scheme.primary),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        if (previous != null)
          _RankRow(row: previous!, animation: previousAnimation),
        if (current != null) _RankRow(row: current!),
        if (next != null) _RankRow(row: next!, animation: nextAnimation),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row, this.animation});

  final RankBoardRow row;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: row.highlight
            ? BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8.0),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 48.0,
              child: Text(
                row.rank == null ? '—' : '#${row.rank}',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: row.highlight
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              flex: 3,
              child: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: row.highlight ? FontWeight.w600 : FontWeight.w400,
                  color: row.highlight ? scheme.onPrimaryContainer : null,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: row.gapText != null
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: _GapChip(text: row.gapText!, color: row.gapColor),
                    )
                  : Text(
                      row.value ?? '',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: row.highlight
                            ? scheme.onPrimaryContainer
                            : scheme.primary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    final anim = animation;
    if (anim == null) return content;
    return SizeTransition(
      sizeFactor: anim,
      fixedCrossAxisSizeFactor: 1.0,
      child: content,
    );
  }
}

class _GapChip extends StatelessWidget {
  const _GapChip({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return PillChip(
      text: text,
      backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      textStyle: const TextStyle(fontSize: 10.0),
    );
  }
}
