import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/divider.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容页卡片行
class FormationCardTile extends ConsumerStatefulWidget {
  const FormationCardTile({
    super.key,
    required this.id,
    required this.index,
    required this.textController,
    required this.numberController,
    required this.textFocusNode,
    required this.numberFocusNode,
    required this.onRemove,
  });

  final int id;
  final int index;
  final TextEditingController textController;
  final TextEditingController numberController;
  final FocusNode textFocusNode;
  final FocusNode numberFocusNode;

  /// 删除回调
  final ValueChanged<int> onRemove;

  @override
  ConsumerState<FormationCardTile> createState() => _FormationCardTileState();
}

class _FormationCardTileState extends ConsumerState<FormationCardTile> {
  /// 是否展开编辑项
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final bool applied = ref.watch(applyFlagProvider(widget.id));
    return ExpansionCardTile(
      // 独立 key：避免展开状态的 bool 与列表滚动位置的 double 共用存储槽
      key: PageStorageKey('formation_card_${widget.id}'),
      // 显式拖拽句柄，避免在 TextField 区域长按触发重排
      leading: Listener(
        onPointerDown: (_) {
          // 拖拽时条目会暂时移入 Overlay，先释放输入框焦点避免 Debug
          // 模式下 EditableText 的焦点与 RenderObject 状态不一致。
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: ReorderableDragStartListener(
          index: widget.index,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: applied
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            child: Text(
              (widget.index + 1).toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      ),
      title: _summaryView(applied),
      trailing: AnimatedRotation(
        turns: _expanded ? 0.5 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.expand_more),
      ),
      // PageStorage 恢复展开状态时回调发生在构建期，延后一帧再更新箭头
      onExpansionChanged: (value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _expanded != value) {
            setState(() => _expanded = value);
          }
        });
      },
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardField(
          // 输入框内部滚动位置也走 PageStorage，需与展开状态的存储槽区分
          key: PageStorageKey('formation_name_${widget.id}'),
          title: _nameLabel(l10n),
          controller: widget.textController,
          focusNode: widget.textFocusNode,
          keyboardType: TextInputType.text,
        ),
        CardField(
          key: PageStorageKey('formation_level_${widget.id}'),
          title: l10n.labelLevel,
          controller: widget.numberController,
          focusNode: widget.numberFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SwitchCardTile(
          title: Text(applied ? l10n.actionApplied : l10n.actionNotApplied),
          value: applied,
          onChanged: (value) => ref.users.setApplyFlag(widget.id, value),
        ),
        if (widget.id != 1 && widget.id != 2)
          CardTile(
            enabled: widget.id != 1 && widget.id != 2,
            title: Text(
              l10n.actionDelete,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.actionDelete),
                content: Text(l10n.dialogDelete),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.actionCancel),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onRemove(widget.id);
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.actionDelete),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _nameLabel(AppLocalizations l10n) => widget.id == 1
      ? l10n.nameLabelCastle
      : widget.id == 2
      ? l10n.nameLabelTownArcher
      : l10n.nameLabelGeneric;

  Widget _summaryView(bool applied) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(textValueProvider(widget.id));
    final level = int.tryParse(ref.watch(numberValueProvider(widget.id))) ?? 0;
    final gold = ref.watch(unitGoldProvider(widget.id));
    final totalGold = ref.watch(currentUserTotalGoldProvider);
    final wave = ref.watch(currentUserWaveProvider);
    final share = applied && totalGold > 0 ? gold / totalGold * 100 : 0.0;
    final oneOverRatio = level / wave;
    final ratio = 1 / oneOverRatio;
    final nameStyle = TextStyle(
      fontWeight: FontWeight.w600,
      decoration: applied ? null : TextDecoration.lineThrough,
      color: applied ? theme.colorScheme.primary : theme.disabledColor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isNotEmpty
                      ? name
                      : widget.id == 1
                      ? l10n.unitNameCastle
                      : widget.id == 2
                      ? l10n.unitNameTownArcher
                      : l10n.unitNameGeneric(widget.id),
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
              ),
              const SizedBox(width: 8.0),
              AnimatedTextSwitcher(
                child: Text(
                  dividerText([
                    (level.format()),
                    (gold.formatCompact(
                      english: !context.isChineseLocale,
                      traditional: context.isTraditionalChineseLocale,
                    )),
                  ]),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: applied
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                  key: ValueKey('$level-$gold-${applied ? 1 : 0}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),
          Wrap(
            spacing: 4.0,
            runSpacing: 1.0,
            children: [
              Tooltip(
                message: l10n.metricShare,
                child: PillChip(
                  text: '${share.format(fractionDigits: 2)}%',
                  backgroundColor: applied
                      ? null
                      : theme.disabledColor,
                ),
              ),
              Tooltip(
                message: l10n.metricOneOverRatio,
                child: PillChip(
                  text: oneOverRatio.format(fractionDigits: 3),
                  backgroundColor: applied ? Colors.green : theme.disabledColor,
                ),
              ),
              Tooltip(
                message: l10n.metricRatio,
                child: PillChip(
                  text: ratio.format(fractionDigits: 2),
                  backgroundColor: applied ? Colors.orange : theme.disabledColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value, bool applied) {
    return AnimatedTextSwitcher(
      child: Text(
        '$label $value',
        style: theme.textTheme.bodySmall?.copyWith(
          color: applied
              ? theme.colorScheme.onSurfaceVariant
              : theme.disabledColor,
        ),
        key: ValueKey('$label-$value-${applied ? 1 : 0}'),
      ),
    );
  }

  String _formatMetric(double value) {
    if (value == 0) return '0';
    final digits = value.abs() < 0.0001
        ? 6
        : value.abs() < 0.01
        ? 5
        : 3;
    return value.format(fractionDigits: digits);
  }
}
