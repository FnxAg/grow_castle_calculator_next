import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/select_user.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Map<int, FocusNode> _numberFocusNodes = {};
  final Map<int, FocusNode> _textFocusNodes = {};
  final Map<int, TextEditingController> _numberControllers = {};
  final Map<int, TextEditingController> _textControllers = {};

  final _selectIndex = ValueNotifier(0);

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
    return Scaffold(
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
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('添加用户'),
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Future.delayed(
                    const Duration(milliseconds: 0),
                    () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final TextEditingController usernameController = TextEditingController();
                          return AlertDialog(
                            title: const Text('添加用户'),
                            content: TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(hintText: '输入用户名'),
                            ),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SelectUserPage()),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                );
              })
            ]
          ),
        ]
      ),
      body: ReorderableListView.builder(
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                final newId = (Stores.infoStore.getCardIds().isEmpty ? 1 : (Stores.infoStore.getCardIds().reduce((a, b) => a > b ? a : b) + 1));
                Stores.infoStore.addNewCard(newId);
              });
            },
            tooltip: '新增条目',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: 
        ListenableBuilder(
          listenable: _selectIndex, 
          builder: (context, child) {
            return NavigationBar(
              selectedIndex: _selectIndex.value,
              height: kBottomNavigationBarHeight * 1.1,
              animationDuration: const Duration(milliseconds: 250),
              onDestinationSelected: (index) {
                setState(() {
                  _selectIndex.value = index;
                });
              },
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings),
                  label: '设置',
                ),
              ],
            );
          }
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
        onDismissed: (direction) {
          setState(() {
            _removeCard(id);
          });
        },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Listener(
          onPointerDown: (_) {
            // 必须在拖拽代理创建之前清除焦点，否则持有焦点
            // 的 TextField 被移入 Overlay 时会导致崩溃
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Row(
            children: [
              // 显式拖拽句柄：避免在 TextField 区域长按触发重排
              Expanded(
                flex: 2,
                child: ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    alignment: Alignment.center,  // 内容居中
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      (index + 1).toString(), 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16.0
                      )
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(flex: 11, child: _textFieldForTextInput(id)),
              const SizedBox(width: 8.0),
              Expanded(flex: 7, child: _textFieldForNumberInput(id)),
              const SizedBox(width: 8.0),
              Expanded(
                flex: 2,
                child: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Stores.infoStore.getApplyFlag(id) ? Icons.done : Icons.block, color: Stores.infoStore.getApplyFlag(id) ? Colors.green : Colors.red),
                          const SizedBox(width: 8.0),
                          Text(Stores.infoStore.getApplyFlag(id) ? '已应用' : '未应用'),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          Stores.infoStore.setApplyFlag(id, !Stores.infoStore.getApplyFlag(id));
                        });
                      }
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
                          id != 1 && id != 2 ? _textControllerFor(id).clear() : null;
                          // _textControllerFor(id).clear();
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
            ],
          ),
        ),
      ),
    );
  }
}