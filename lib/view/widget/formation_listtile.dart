import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_input_field.dart';

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
    required this.viewMode,
    required this.onRemove,
  });

  final int id;
  final int index;
  final TextEditingController textController;
  final TextEditingController numberController;
  final FocusNode textFocusNode;
  final FocusNode numberFocusNode;
  final bool viewMode;

  /// 删除回调
  final ValueChanged<int> onRemove;

  @override
  ConsumerState<FormationCardTile> createState() => _FormationCardTileState();
}

class _FormationCardTileState extends ConsumerState<FormationCardTile> {
  /// 是否已应用
  bool get _applied => ref.read(applyFlagProvider(widget.id));

  /// 桌面端指针是否悬停在行上
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 订阅本行的应用标志
    final bool applied = ref.watch(applyFlagProvider(widget.id));
    // 桌面端右键整行也可弹出操作菜单
    return GestureDetector(
      onSecondaryTapUp: _showContextMenu,
      child: ListTile(
        // 显式拖拽句柄，避免在 TextField 区域长按触发重排
        leading: Listener(
          onPointerDown: (_) {
            // 拖拽时条目会暂时移入 Overlay，先释放输入框焦点避免 Debug
            // 模式下 EditableText 的焦点与 RenderObject 状态不一致。
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: ReorderableDragStartListener(
            index: widget.index,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 24),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999.0),
                ),
                child: Text(
                  (widget.index + 1).toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              child: child,
            ),
          ),
          child: widget.viewMode ? _summaryView(applied) : _inputView(applied),
        ),
        trailing: _menuButton(applied),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      ),
    );
  }

  Widget _inputView(bool applied) {
    return Row(
      key: const ValueKey('input'),
      children: [
        Expanded(flex: 9, child: _nameField(applied)),
        const SizedBox(width: 8.0),
        Expanded(flex: 9, child: _levelField(applied)),
      ],
    );
  }

  Widget _summaryView(bool applied) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(textValueProvider(widget.id));
    final level = int.tryParse(ref.watch(numberValueProvider(widget.id))) ?? 0;
    final gold = ref.watch(unitGoldProvider(widget.id));
    final totalGold = ref.watch(currentUserTotalGoldProvider);
    final wave = ref.watch(currentUserWaveProvider);
    final share = applied && totalGold > 0 ? gold / totalGold * 100 : 0.0;
    final oneOverRatio = applied && wave > 0 && level > 0 ? level / wave : 0.0;
    final ratio = oneOverRatio > 0 ? 1 / oneOverRatio : 0.0;
    final nameStyle = TextStyle(
      fontWeight: FontWeight.w600,
      decoration: applied ? null : TextDecoration.lineThrough,
      color: applied ? theme.colorScheme.primary : theme.disabledColor,
    );

    return Padding(
      key: const ValueKey('summary'),
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
                      ? l10n.unitNameCastleBow
                      : l10n.unitNameGeneric(widget.id),
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '${level.format()} · '
                '${gold.formatCompact(english: !context.isChineseLocale, traditional: context.isTraditionalChineseLocale)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: applied
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),
          Row(
            children: [
              _metric(
                theme,
                l10n.metricShare,
                '${_formatMetric(share)}%',
                applied,
              ),
              const SizedBox(width: 10.0),
              _metric(
                theme,
                l10n.metricOneOverRatio,
                _formatMetric(oneOverRatio),
                applied,
              ),
              const SizedBox(width: 10.0),
              _metric(theme, l10n.metricRatio, _formatMetric(ratio), applied),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value, bool applied) {
    return Text(
      '$label $value',
      style: theme.textTheme.bodySmall?.copyWith(
        color: applied
            ? theme.colorScheme.onSurfaceVariant
            : theme.disabledColor,
      ),
    );
  }

  String _formatMetric(double value) {
    if (value == 0) return '0';
    final digits = value.abs() < 0.0001
        ? 6
        : value.abs() < 0.01
        ? 4
        : 2;
    return value.format(fractionDigits: digits);
  }

  Widget _nameField(bool applied) {
    final l10n = AppLocalizations.of(context);
    return FormationInputField(
      controller: widget.textController,
      focusNode: widget.textFocusNode,
      enabled: true,
      visualDisabled: !applied,
      labelText: widget.id == 1
          ? l10n.nameLabelCastle
          : widget.id == 2
          ? l10n.nameLabelCastleBow
          : l10n.nameLabelGeneric,
      keyboardType: TextInputType.text,
    );
  }

  Widget _levelField(bool applied) {
    return FormationInputField(
      controller: widget.numberController,
      focusNode: widget.numberFocusNode,
      enabled: true,
      visualDisabled: !applied,
      labelText: AppLocalizations.of(context).labelLevel,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _menuButton(bool applied) {
    final button = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 24),
      child: PopupMenuButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        tooltip: AppLocalizations.of(context).tooltipActions,
        itemBuilder: (context) => _menuItems(applied),
      ),
    );
    if (!isDesktopPlatform()) return button;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IgnorePointer(
        ignoring: !_hovered,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _hovered ? 1.0 : 0.0,
          child: button,
        ),
      ),
    );
  }

  /// 操作菜单
  List<PopupMenuEntry<void>> _menuItems(bool applied) {
    final l10n = AppLocalizations.of(context);
    return [
      PopupMenuItem(
        onTap: () => _toggleApplied(applied),
        child: Row(
          children: [
            Icon(
              applied ? Icons.done : Icons.block,
              color: applied ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8.0),
            Text(applied ? l10n.actionApplied : l10n.actionNotApplied),
          ],
        ),
      ),
      // 清除表单
      PopupMenuItem(
        onTap: _clear,
        child: Row(
          children: [
            const Icon(Icons.clear),
            const SizedBox(width: 8.0),
            Text(l10n.actionClear),
          ],
        ),
      ),
      PopupMenuItem(
        enabled: widget.id != 1 && widget.id != 2,
        onTap: () => widget.onRemove(widget.id),
        child: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 8.0),
            Text(l10n.actionDelete, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }

  /// 右键整行时在指针位置弹出操作菜单
  void _showContextMenu(TapUpDetails details) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: _menuItems(_applied),
    );
  }

  /// 切换应用标志
  void _toggleApplied(bool applied) {
    setState(() {
      ref.users.setApplyFlag(widget.id, !applied);
    });
  }

  /// 清空名称与等级输入
  void _clear() {
    setState(() {
      widget.numberController.clear();
      widget.textController.clear();
    });
  }
}
