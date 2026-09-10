import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_input_field.dart';

/// 阵容页的卡片行：拖拽排序句柄 + 名称/等级输入 + 操作菜单（应用/清空/删除）。
///
/// 输入框的控制器与焦点由页面 State 按卡片 id 缓存并负责释放，通过构造参数
/// 传入；[onRemove] 由页面 State 实现（释放控制器缓存并写入 store）。
class FormationCardTile extends StatefulWidget {
  const FormationCardTile({
    super.key,
    required this.id,
    required this.index,
    required this.textController,
    required this.numberController,
    required this.textFocusNode,
    required this.numberFocusNode,
    required this.viewMode,
    required this.dataVersion,
    required this.onRemove,
  });

  final int id;
  final int index;
  final TextEditingController textController;
  final TextEditingController numberController;
  final FocusNode textFocusNode;
  final FocusNode numberFocusNode;
  final bool viewMode;
  final ValueListenable<int> dataVersion;

  /// 删除回调（菜单删除使用）
  final ValueChanged<int> onRemove;

  @override
  State<FormationCardTile> createState() => _FormationCardTileState();
}

class _FormationCardTileState extends State<FormationCardTile> {
  /// 是否已应用：决定输入框是否可编辑、菜单项展示
  bool get _applied => Stores.infoStore.getApplyFlag(widget.id);

  /// 桌面端指针是否悬停在行上：菜单按钮 hover 显露用
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 桌面端右键整行也可弹出操作菜单（左键菜单按钮不变）
    return GestureDetector(
      onSecondaryTapUp: _showContextMenu,
      child: ListTile(
      // 显式拖拽句柄：避免在 TextField 区域长按触发重排
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
      title: ListenableBuilder(
        listenable: Listenable.merge([
          widget.dataVersion,
          Stores.infoStore.totalGoldNotifier,
          Stores.infoStore.waveNotifier,
        ]),
        builder: (context, _) => AnimatedSwitcher(
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
          child: widget.viewMode ? _summaryView() : _inputView(),
        ),
      ),
      trailing: _menuButton(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      ),
    );
  }

  Widget _inputView() {
    return Row(
      key: const ValueKey('input'),
      children: [
        Expanded(flex: 9, child: _nameField()),
        const SizedBox(width: 8.0),
        Expanded(flex: 9, child: _levelField()),
      ],
    );
  }

  Widget _summaryView() {
    final theme = Theme.of(context);
    final store = Stores.infoStore;
    final applied = _applied;
    final name = store.getTextValue(widget.id);
    final level = int.tryParse(store.getNumberValue(widget.id)) ?? 0;
    final gold = store.getCurrentUserUnitGold(widget.id);
    final totalGold = store.totalGoldNotifier.value;
    final wave = store.waveNotifier.value;
    final share = applied && totalGold > 0 ? gold / totalGold * 100 : 0.0;
    final oneOverRatio = applied && wave > 0 && level > 0
        ? level / wave
        : 0.0;
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
                      ? '城堡'
                      : widget.id == 2
                      ? '城弓'
                      : '单位 ${widget.id}',
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '${level.format()} · ${gold.formatCompact(english: false)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: applied ? theme.colorScheme.primary : theme.disabledColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),
          Row(
            children: [
              _metric(theme, '占比', '${_formatMetric(share)}%', applied),
              const SizedBox(width: 10.0),
              _metric(theme, '1/比例', _formatMetric(oneOverRatio), applied),
              const SizedBox(width: 10.0),
              _metric(theme, '比例', _formatMetric(ratio), applied),
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
        color: applied ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
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

  Widget _nameField() {
    return FormationInputField(
      controller: widget.textController,
      focusNode: widget.textFocusNode,
      enabled: true,
      visualDisabled: !_applied,
      labelText: '${widget.id == 1 ? '城堡' : widget.id == 2 ? '城弓' : ''}名称',
      keyboardType: TextInputType.text,
    );
  }

  Widget _levelField() {
    return FormationInputField(
      controller: widget.numberController,
      focusNode: widget.numberFocusNode,
      enabled: true,
      visualDisabled: !_applied,
      labelText: '等级',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _menuButton() {
    final button = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 24),
      child: PopupMenuButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        tooltip: '操作',
        itemBuilder: (context) => _menuItems(),
      ),
    );
    // 移动端菜单常显（触屏无 hover）；桌面端 hover 才显露，行面更干净
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

  /// 操作菜单项：左键菜单按钮与右键整行菜单共用
  List<PopupMenuEntry<void>> _menuItems() {
    return [
      PopupMenuItem(
        onTap: _toggleApplied,
        child: Row(
          children: [
            Icon(
              _applied ? Icons.done : Icons.block,
              color: _applied ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8.0),
            Text(_applied ? '已应用' : '未应用'),
          ],
        ),
      ),
      // 清除表单
      PopupMenuItem(
        onTap: _clear,
        child: const Row(
          children: [
            Icon(Icons.clear),
            SizedBox(width: 8.0),
            Text('清空'),
          ],
        ),
      ),
      PopupMenuItem(
        enabled: widget.id != 1 && widget.id != 2,
        onTap: () => widget.onRemove(widget.id),
        child: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8.0),
            Text('删除', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }

  /// 右键整行：在指针位置弹出操作菜单
  void _showContextMenu(TapUpDetails details) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: _menuItems(),
    );
  }

  /// 切换应用标志：store 的 notifier 会驱动汇总条重建，
  /// 输入框 enabled 状态与菜单展示依赖本组件重建，需 setState
  void _toggleApplied() {
    setState(() {
      Stores.infoStore.setApplyFlag(widget.id, !_applied);
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
