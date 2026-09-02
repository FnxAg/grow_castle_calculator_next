import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';

/// 与当前用户数据相关页面的公共框架（首页三个 tab：阵容/收入/公会）：
/// AppBar = 页面标题 + 用户名/上次在线/所属公会 + 页面声明的操作按钮，
/// 可选 [bottom]（如 TabBar）挂在 AppBar 底部。
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
    this.bottom,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  /// AppBar 底部组件，透传给 AppBar.bottom
  final PreferredSizeWidget? bottom;

  @override
  State<UserPageScaffold> createState() => _UserPageScaffoldState();
}

class _UserPageScaffoldState extends State<UserPageScaffold> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Stores.infoStore.currentUserNotifier,
      builder: (context, currentUser, _) {
        return Scaffold(
          appBar: AppBar(
            bottom: widget.bottom,
            title: Column(
              crossAxisAlignment: .start,
              children: [
                Text(widget.title),
                // 用户名  ·  "上次在线"时间  ·  所属公会，
                ListenableBuilder(
                  listenable: Listenable.merge([
                    Stores.infoStore.lastOnlineNotifier,
                    Stores.infoStore.guildNotifier,
                  ]),
                  builder: (context, _) {
                    final lastOnline =
                        Stores.infoStore.lastOnlineNotifier.value;
                    final guild = Stores.infoStore.guildNotifier.value;
                    final segments = <Widget>[
                      Text(
                        currentUser, 
                        style: const TextStyle(fontSize: 12.0)
                      ),
                      if (lastOnline.isNotEmpty)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            '$lastOnline ago',
                            key: ValueKey(lastOnline),
                            style: const TextStyle(fontSize: 12.0),
                          ),
                        ),
                      if (guild.isNotEmpty)
                        Text(
                          guild, 
                          style: const TextStyle(fontSize: 12.0)
                        ),
                    ];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < segments.length; i++) ...[
                          if (i > 0)
                            Text(
                              '  ·  ',
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          segments[i],
                        ],
                        if (Stores.infoStore.getCurrentUserId() == 0) ...[
                          const SizedBox(width: 4.0),
                          SizedBox(
                            height: 12.0,
                            width: 12.0,
                            child: IconButton(
                              icon: const Icon(Icons.info_outline, size: 12.0),
                              tooltip: '使用说明',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showDefaultUserHint(context),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
            actions: [...widget.actions],
          ),
          body: KeyedSubtree(key: ValueKey(currentUser), child: widget.body),
        );
      },
    );
  }

  void _showDefaultUserHint(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('默认用户'),
        content: const Text(
          '当前为默认用户，仅用于体验基础功能。\n\n'
          '请前往「设置」页的「用户管理」，填写游戏账号信息。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(dialogContext);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => const SelectUserPage()
                ),
              );
            },
            child: const Text('前往用户管理'),
          ),
        ],
      ),
    );
  }
}
