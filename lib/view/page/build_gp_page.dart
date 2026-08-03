import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';

/// 阵容经济计算页：卡片列表（名称/等级输入）与底部汇总条。
///
/// 作为抽屉页面由 [HomeTab] 挂载；输入框控制器与焦点按卡片 id 缓存在
/// State 中，切换用户时 HomeTab 通过更换 key 重建本页，控制器随之释放。
class FormationCalcPage extends StatefulWidget {
  const FormationCalcPage({super.key});

  @override
  State<FormationCalcPage> createState() => _FormationCalcPageState();
}

class _FormationCalcPageState extends State<FormationCalcPage> {
  final Map<int, FocusNode> _numberFocusNodes = {};
  final Map<int, FocusNode> _textFocusNodes = {};
  final Map<int, TextEditingController> _numberControllers = {};
  final Map<int, TextEditingController> _textControllers = {};

  FocusNode _focusNodeFor(int id, Map<int, FocusNode> cache) {
    return cache.putIfAbsent(id, () => FocusNode());
  }

  TextEditingController _numberControllerFor(int id) {
    return _numberControllers.putIfAbsent(id, () {
      final c = TextEditingController(text: Stores.infoStore.getNumberValue(id));
      c.addListener(() {
        Stores.infoStore.setNumberValue(id, c.text);
      });
      return c;
    });
  }

  TextEditingController _textControllerFor(int id) {
    return _textControllers.putIfAbsent(id, () {
      final c = TextEditingController(text: Stores.infoStore.getTextValue(id));
      c.addListener(() {
        Stores.infoStore.setTextValue(id, c.text);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final node in _numberFocusNodes.values) {
      node.dispose();
    }
    for (final node in _textFocusNodes.values) {
      node.dispose();
    }
    for (final c in _numberControllers.values) {
      c.dispose();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _removeCard(int id) {
    final idx = Stores.infoStore.getCardIds().indexOf(id);
    if (idx != -1) {
      _numberFocusNodes.remove(id)?.dispose();
      _textFocusNodes.remove(id)?.dispose();
      _numberControllers.remove(id)?.dispose();
      _textControllers.remove(id)?.dispose();
      setState(() {
        Stores.infoStore.removeCard(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stores.infoStore.getCardIds().isEmpty
              ? const Center(
                  child: Text(
                    '暂无条目，点击右上角 + 添加',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: Stores.infoStore.getCardIds().length,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final double elevation = 4.0 * animation.value;
                        return Material(
                          elevation: elevation,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(8.0),
                          child: IgnorePointer(child: child),
                        );
                      },
                      child: child,
                    );
                  },
                  onReorderItem: (oldIndex, newIndex) {
                    // 拖拽前先清除焦点，避免 TextField 的 FocusNode
                    // 在 widget 临时脱离树时产生不一致状态导致崩溃
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      final item = Stores.infoStore.getCardIds().removeAt(oldIndex);
                      Stores.infoStore.getCardIds().insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildCard(Stores.infoStore.getCardIds()[index], index);
                  },
                  buildDefaultDragHandles: false,
                  scrollDirection: .vertical,
                ),
        ),
        _buildSummaryBar(),
      ],
    );
  }

  /// 底部总金币汇总条，输入等级时实时更新
  Widget _buildSummaryBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on_outlined,
                  size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('总金币'),
              const Spacer(),
              ValueListenableBuilder<double>(
                valueListenable: Stores.infoStore.totalGoldNotifier,
                builder: (context, gold, _) {
                  return Text(
                    gold.format(),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.star, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('GP'),
              const Spacer(),
              ValueListenableBuilder<double>(
                valueListenable: Stores.infoStore.gpNotifier,
                builder: (context, gp, _) {
                  return Text(
                    gp.format(fractionDigits: 3),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('指数'),
              const Spacer(),
              ValueListenableBuilder<double>(
                valueListenable: Stores.infoStore.gpCNNotifier,
                builder: (context, gpCN, _) {
                  return Text(
                    gpCN.format(fractionDigits: 3),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _textFieldForTextInput(int id) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0
            )
          ),
      ),
      child: TextField(
        // readOnly: switch (id) {
        //   1 || 2 => true,
        //   _ => !Stores.infoStore.getApplyFlag(id),
        // },
        controller: _textControllerFor(id),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        obscureText: false,
        maxLines: 1,
        focusNode: _focusNodeFor(id, _textFocusNodes),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: '名称${id == 1 ? ' - 城堡专属' : id == 2 ? ' - 城弓专属' : ''}',
          focusedBorder: InputBorder.none,
          // hintText: '输入数字',
          filled: true,
          // fillColor: Theme.of(context).colorScheme.primaryContainer,
          disabledBorder: InputBorder.none,
          enabled: Stores.infoStore.getApplyFlag(id),
        ),
      ),
    );
  }

  Widget _textFieldForNumberInput(int id) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0
            )
          ),
      ),
      child: TextField(
        // readOnly: !(_applyFlags[id] ?? true),
        controller: _numberControllerFor(id),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        obscureText: false,
        maxLines: 1,
        // maxLength: 10,
        // maxLengthEnforcement: MaxLengthEnforcement.enforced,
        focusNode: _focusNodeFor(id, _numberFocusNodes),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: '等级',
          focusedBorder: InputBorder.none,
          // hintText: '输入数字',
          filled: true,
          // fillColor: Theme.of(context).colorScheme.primaryContainer,
          disabledBorder: InputBorder.none,
          enabled: Stores.infoStore.getApplyFlag(id),
        ),
      ),
    );
  }

  Widget _buildCard(int id, int index) {
    return Dismissible( // 左划删除
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (id == 1 || id == 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该条目不可删除，请选择禁用该条目')),
          );
          return false; // 否决滑动，卡片弹回原位
        }
        return true;
      },
      onDismissed: (direction) {
        setState(() {
          _removeCard(id);
        });
      },
      child: Listener(
        onPointerDown: (_) {
          // 必须在拖拽代理创建之前清除焦点，否则持有焦点
          // 的 TextField 被移入 Overlay 时会导致崩溃
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: ListTile(
          // 显式拖拽句柄：避免在 TextField 区域长按触发重排
          leading: ReorderableDragStartListener(
            index: index,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 24),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ),
          // 两个输入框作为主体
          title: Row(
            children: [
              Expanded(flex: 9, child: _textFieldForTextInput(id)),
              const SizedBox(width: 8.0),
              Expanded(flex: 9, child: _textFieldForNumberInput(id)),
            ],
          ),
          // 弹出菜单
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 24),
            child: PopupMenuButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        Stores.infoStore.getApplyFlag(id) ? Icons.done : Icons.block,
                        color: Stores.infoStore.getApplyFlag(id) ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8.0),
                      Text(Stores.infoStore.getApplyFlag(id) ? '已应用' : '未应用'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      Stores.infoStore.setApplyFlag(id, !Stores.infoStore.getApplyFlag(id));
                    });
                  },
                ),
                // 清除表单
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.clear),
                      SizedBox(width: 8.0),
                      Text('清空'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _numberControllerFor(id).clear();
                      // if (id != 1 && id != 2) _textControllerFor(id).clear();
                      _textControllerFor(id).clear();
                    });
                  },
                ),
                PopupMenuItem(
                  enabled: id != 1 && id != 2,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8.0),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _removeCard(id);
                    });
                  },
                ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
      ),
    );
  }
}
