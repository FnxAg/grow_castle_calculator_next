import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/pages.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/select_user.dart';
import 'package:grow_castle_calculator_next/view/widget/username_textfield.dart';

/// 首页 tab：抽屉页面的框架（Scaffold + AppBar + 抽屉切换）。
///
/// body 按 [_pageIndex] 显示注册在 [drawerPages] 中的页面；
/// AppBar 操作按钮 = 当前页面声明的 actions + 全局共享的用户菜单；
/// 切换用户时通过更换 [KeyedSubtree] 的 key（当前用户名）强制重建页面，
/// 使各页面重新读取新用户的数据并释放旧的控制器/焦点。
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.title});

  final String title;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  /// 当前抽屉页面索引
  int _pageIndex = 0;

  /// 刷新框架（供页面 AppBar 操作触发 body 重新读取 store）
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final page = drawerPages[_pageIndex];
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
          // 当前页面声明的操作按钮（随抽屉切换变化）
          ...(page.actionsBuilder?.call(context, _refresh) ?? const <Widget>[]),
          // 用户菜单：全局共享，不随页面变化
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
              PopupMenuItem(
                child: const Text('管理用户'), 
                onTap: () {
                  Future.delayed(
                    const Duration(milliseconds: 0),
                    () {
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SelectUserPage()),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                  );
                },
              )
            ]
          ),
        ]
      ),
      // 切换用户后用户名变化 → key 变化 → 页面整体重建（控制器/焦点随之释放）
      body: KeyedSubtree(
        key: ValueKey(Stores.infoStore.getCurrentUser()),
        child: page.builder(context),
      ),
    );
  }

  Widget _buildDrawer() {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: const Text('GCC Next', style: TextStyle(fontSize: 24.0)),
          ),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < drawerPages.length; i++)
                ListTile(
                  leading: Icon(drawerPages[i].icon),
                  title: Text(drawerPages[i].title),
                  // 当前页面以主题色高亮，点击无效
                  selected: i == _pageIndex,
                  selectedTileColor: colorScheme.primaryContainer,
                  onTap: i == _pageIndex
                      ? null
                      : () {
                          setState(() => _pageIndex = i);
                          Navigator.of(context).pop();
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
