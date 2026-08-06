import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/select_user_page.dart';

/// 与当前用户数据相关页面的公共框架（首页三个 tab：阵容/收入/公会）：
/// AppBar = 页面标题 + 用户名/上次在线 + 页面声明的操作按钮 + 用户管理入口。
///
/// 全局监听 store 的 currentUserNotifier：切换用户时所有用户页外壳一起重建
/// （PageView 保活的其他页面同样收到通知），通过更换 [KeyedSubtree] 的 key
/// （当前用户名）强制重建页面，使各页面重新读取新用户的数据并释放旧的控制器/焦点。
class UserPageScaffold extends StatefulWidget {
  const UserPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  State<UserPageScaffold> createState() => _UserPageScaffoldState();
}

class _UserPageScaffoldState extends State<UserPageScaffold> {
  @override
  Widget build(BuildContext context) {
    // 全局监听当前用户：切换用户时所有用户页外壳一起重建（PageView 保活的
    // 其他页面同样收到通知），AppBar 用户名与 body 的 KeyedSubtree key 同步
    // 更新，各页面 State 随之重新读取新用户数据并释放旧控制器/焦点
    return ValueListenableBuilder<String>(
      valueListenable: Stores.infoStore.currentUserNotifier,
      builder: (context, currentUser, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: .start,
              children: [
                Text(widget.title),
                // 用户名 + 联网查询到的"上次在线"时间（查询时格式化并固定，仅内存）
                ValueListenableBuilder<String>(
                  valueListenable: Stores.infoStore.lastOnlineNotifier,
                  builder: (context, lastOnline, _) {
                    return Text(
                      '$currentUser${lastOnline.isEmpty ? '' : '（$lastOnline）'}',
                      style: const TextStyle(fontSize: 12.0),
                    );
                  },
                ),
              ],
            ),
            actions: [
              // 当前页面声明的操作按钮
              ...widget.actions,
              // 用户管理入口：三个用户页面共享
              IconButton(
                icon: const Icon(Icons.group),
                tooltip: '用户管理',
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SelectUserPage()),
                  );
                },
              ),
            ],
          ),
          // 切换用户后用户名变化 → key 变化 → 页面整体重建（控制器/焦点随之释放）
          body: KeyedSubtree(
            key: ValueKey(currentUser),
            child: widget.body,
          ),
        );
      },
    );
  }
}
