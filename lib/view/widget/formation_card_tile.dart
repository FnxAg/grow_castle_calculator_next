import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
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
    required this.onRemove,
  });

  final int id;
  final int index;
  final TextEditingController textController;
  final TextEditingController numberController;
  final FocusNode textFocusNode;
  final FocusNode numberFocusNode;

  /// 删除回调（菜单删除使用）
  final ValueChanged<int> onRemove;

  @override
  State<FormationCardTile> createState() => _FormationCardTileState();
}

class _FormationCardTileState extends State<FormationCardTile> {
  /// 是否已应用：决定输入框是否可编辑、菜单项展示
  bool get _applied => Stores.infoStore.getApplyFlag(widget.id);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
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
      // 名称 + 等级两个输入框作为主体
      title: Row(
        children: [
          Expanded(flex: 9, child: _nameField()),
          const SizedBox(width: 8.0),
          Expanded(flex: 9, child: _levelField()),
        ],
      ),
      trailing: _menuButton(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 24),
      child: PopupMenuButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        tooltip: '操作',
        itemBuilder: (context) => [
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
        ],
      ),
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
