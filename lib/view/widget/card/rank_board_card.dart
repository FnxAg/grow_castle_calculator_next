import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/ranking/ranking_milestones.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/notice/top_notice.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
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
    this.cardType = CardType.normal,
    this.selfScore,
    this.milestones,
    this.formatScore,
  });

  final IconData icon;
  final String title;
  final RankBoardRow? previous;
  final RankBoardRow? current;
  final RankBoardRow? next;
  final Animation<double>? previousAnimation;
  final Animation<double>? nextAnimation;
  final CardType cardType;

  /// 自己的分数，与里程碑分数求差
  final int? selfScore;

  /// 里程碑名次 -> 榜单条目（名称与分数）
  final Map<int, RankMilestone>? milestones;

  /// 分数格式，需与卡片当前数值一致；默认千分位
  final String Function(int value)? formatScore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CardX(
      cardType: cardType,
      child: InkWell(
        onTap: current == null ? null : () => _showSummary(context),
        child: Padding(
          padding: UIs.inCardPadding,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: SummaryRow.leadingIconSize,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (previous != null)
                _RankRow(row: previous!, animation: previousAnimation),
              if (current != null) _RankRow(row: current!),
              if (next != null) _RankRow(row: next!, animation: nextAnimation),
            ],
          ),
        ),
      ),
    );
  }

  String _format(int value) => formatScore?.call(value) ?? value.format();

  void _showSummary(BuildContext context) {
    showTopNotice(
      context,
      duration: const Duration(seconds: 5),
      content: _buildSummary(),
      noticeType: NoticeType.content,
    );
  }

  /// 沿用卡片行样式：上一里程碑 / 自己 / 下一里程碑，右侧显示分数差
  ///
  /// 未进榜或排名超过全部里程碑时，上一行仍显示最低里程碑（300）的条目。
  Widget _buildSummary() {
    final rank = current?.rank;
    // 榜单只返回前 300 名，rank 为空即未进榜，按超过全部里程碑处理
    final effectiveRank =
        rank ?? (milestones == null ? null : rankMilestoneRanks.last + 1);
    final (previousMilestone, nextMilestone) = effectiveRank == null
        ? (null, null)
        : milestonesAround(effectiveRank);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (previousMilestone != null)
          _milestoneRow(previousMilestone, isPrevious: true),
        _RankRow(
          row: RankBoardRow(
            rank: rank,
            name: current?.name ?? '',
            value: selfScore == null
                ? current?.value ?? '—'
                : _format(selfScore!),
            highlight: true,
          ),
        ),
        if (nextMilestone != null)
          _milestoneRow(nextMilestone, isPrevious: false),
      ],
    );
  }

  Widget _milestoneRow(int milestone, {required bool isPrevious}) {
    final entry = milestones?[milestone];
    final ownScore = selfScore ?? 0;
    String? gapText;
    if (entry != null) {
      final gap = entry.score - ownScore;
      gapText = gap > 0
          ? '+${_format(gap)}'
          : gap < 0
          ? '-${_format(-gap)}'
          : _format(0);
    }
    return _RankRow(
      row: RankBoardRow(
        rank: milestone,
        name: entry?.name ?? '—',
        value: gapText == null ? '—' : null,
        gapText: gapText,
        gapColor: isPrevious ? Colors.red : Colors.green,
      ),
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
              child: AnimatedTextSwitcher(
                alignment: Alignment.centerRight,
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
                  key: ValueKey(row.rank == null ? '—' : '#${row.rank}'),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              flex: 3,
              child: AnimatedTextSwitcher(
                alignment: Alignment.centerLeft,
                child: Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: row.highlight
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: row.highlight ? scheme.onPrimaryContainer : null,
                  ),
                  key: ValueKey(row.name),
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
                  : AnimatedTextSwitcher(
                      alignment: Alignment.centerRight,
                      child: Text(
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
                        key: ValueKey(row.value),
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
