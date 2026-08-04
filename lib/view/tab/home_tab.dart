import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/pages.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/select_user.dart';

/// 首页 tab：抽屉页面的框架（Scaffold + AppBar + 抽屉切换）。
///
/// body 按 [_pageIndex] 显示注册在 [drawerPages] 中的页面；
/// AppBar 操作按钮 = 当前页面声明的 actions + 全局共享的用户菜单；
/// 切换用户时通过更换 [KeyedSubtree] 的 key（当前用户名）强制重建页面，
/// 使各页面重新读取新用户的数据并释放旧的控制器/焦点。
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  /// 当前抽屉页面索引
  int _pageIndex = 0;

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
            // 大标题跟随抽屉选中的页面
            Text(drawerPages[_pageIndex].title),
            // 用户名 + 联网查询到的"上次在线"时间（查询时格式化并固定，仅内存）
            ValueListenableBuilder<String>(
              valueListenable: Stores.infoStore.lastOnlineNotifier,
              builder: (context, lastOnline, _) {
                return Text(
                  '${Stores.infoStore.getCurrentUser()}'
                  '${lastOnline.isEmpty ? '' : '（$lastOnline）'}',
                  style: const TextStyle(fontSize: 12.0),
                );
              },
            ),
          ],
        ),
        actions: [
          // 当前页面声明的操作按钮（随抽屉切换变化）
          ...(page.actionsBuilder?.call(context) ?? const <Widget>[]),
          // 用户管理入口：全局共享，不随页面变化
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: '用户管理',
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SelectUserPage()),
              ).then((_) {
                setState(() {});
              });
            },
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
