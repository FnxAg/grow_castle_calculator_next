import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/select_user.dart';
import 'package:grow_castle_calculator_next/view/widget/username_textfield.dart';

/// 首页 tab：独立的 Scaffold，含抽屉、AppBar（汉堡/加号/用户菜单）、
/// 卡片列表与总金币汇总。
///
/// 输入框的控制器与焦点按卡片 id 缓存在 State 中，
/// 切换用户后需调用 [_disposeControllers] 重建。
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.title});

  final String title;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
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

  /// 切换用户后丢弃旧控制器（数据已由 store 持久化，下次重建时重新读取）
  void _disposeControllers() {
    for (final c in _numberControllers.values) {
      c.dispose();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
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

  void _addCard() {
    setState(() {
      final newId = (Stores.infoStore.getCardIds().isEmpty ? 1 : (Stores.infoStore.getCardIds().reduce((a, b) => a > b ? a : b) + 1));
      Stores.infoStore.addNewCard(newId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 抽屉属于首页：AppBar 会因此自动显示汉堡按钮
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: .start,
          children: [
            Text(widget.title),
            Text(
              Stores.infoStore.getCurrentUser(),
              style: const TextStyle(fontSize: 12.0)
            ),
          ],
        ),
        actions: [
          // 新增条目（原 FAB 迁移）
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增条目',
            onPressed: _addCard,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('添加用户'),
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Future.delayed(
                    const Duration(milliseconds: 0),
                    () {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) {
                          final TextEditingController usernameController = TextEditingController();
                          return AlertDialog(
                            title: const Text('添加用户'),
                            content: UsernameTextField(controller: usernameController),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final username = usernameController.text.trim();
                                  if (username.isNotEmpty) {
                                    try {
                                      Stores.infoStore.createUser(username);
                                      Stores.infoStore.setCurrentUser(username);
                                      _textControllers.clear();
                                      _numberControllers.clear();
                                      for (int id in Stores.infoStore.getCardIds()) {
                                        _textControllerFor(id);
                                        _numberControllerFor(id);
                                      }
                                      setState(() {});
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: const Text('添加'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              PopupMenuItem(child: const Text('切换用户'), onTap: () {
                Future.delayed(
                  const Duration(milliseconds: 0),
                  () {
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SelectUserPage()),
                    ).then((_) {
                      _disposeControllers();
                      _textControllers.clear();
                      _numberControllers.clear();
                      setState(() {});
                    });
                  },
                );
              })
            ]
          ),
        ]
      ),
      body: Column(
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
          _buildGoldSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Text('GCC Next', style: TextStyle(fontSize: 24.0)),
          ),
          // 设置入口占位，暂时空置
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('设置'),
            enabled: false,
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'GCC Next',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.castle),
                children: [
                  const Text('GCC Next 是一个用于计算和管理游戏数据的工具。'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 底部总金币汇总条，输入等级时实时更新
  Widget _buildGoldSummaryBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
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
                _formatGold(gold),
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
    );
  }

  /// 格式化金币：整数不带小数，千位加分隔符
  String _formatGold(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
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
