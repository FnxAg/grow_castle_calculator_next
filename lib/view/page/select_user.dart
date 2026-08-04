import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';
import 'package:grow_castle_calculator_next/view/widget/unit_summary_sheet.dart';
import 'package:grow_castle_calculator_next/view/widget/username_textfield.dart';

class SelectUserPage extends StatefulWidget {
  const SelectUserPage({super.key});

  @override
  State<SelectUserPage> createState() => _SelectUserPageState();
}

class _SelectUserPageState extends State<SelectUserPage> {
  bool _settingState = false;

  @override
  Widget build(BuildContext context) {
    final InfoStore infoStore = Stores.infoStore;
    final List<String> usernames = infoStore.getAllUsernames();

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择用户'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              !_settingState ? Icons.edit : Icons.edit_off,
            ),
            onPressed: () {
              setState(() {
                _settingState = !_settingState;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: usernames.length,
        itemBuilder: (ctx, index) {
          final String userId = usernames[index];
          return ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(userId),
                      Text(
                        infoStore.getTotalGold(userId).format(fractionDigits: 0),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            leading: infoStore.getCurrentUser() == userId
                ? const Icon(Icons.check, color: Colors.green)
                : const SizedBox(width: 24.0),
            trailing: !_settingState
                ? null
                : infoStore.getUserId(userId) == 0
                    ? null
                    : Row(
                      // 必须收缩到内容宽度：默认 max 会占满整行触发 ListTile 断言
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: switch (infoStore.getUserId(userId)) {
                            0 => () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('默认用户不可重命名')),
                              );
                            },
                            _ => () => _showRenameDialog(infoStore, userId),
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: switch (infoStore.getUserId(userId)) {
                            0 => () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('默认用户不可删除')),
                              );
                            },
                            _ => () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => _DeleteUserDialog(
                                  infoStore: infoStore,
                                  userId: userId,
                                  onDeleted: () => setState(() {}),
                                ),
                              );
                            },
                          },
                        ),
                      ],
                    ),
            onTap: () {
              infoStore.setCurrentUser(userId);
              Navigator.pop(context);
            },
            // 长按查看该用户的单位汇总（任意用户均可用，含默认用户）
            onLongPress: () {
              final data = infoStore.getUserData(userId);
              if (data == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('未找到用户「$userId」的数据')),
                );
                return;
              }
              showUnitSummarySheet(context, username: userId, data: data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 添加用户对话框
  void _showAddUserDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加用户'),
          content: UsernameTextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final username = controller.text.trim();
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
  }

  /// 重命名用户对话框（默认用户不可重命名，由调用方拦截）
  void _showRenameDialog(InfoStore infoStore, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller =
            TextEditingController(text: userId);
        return AlertDialog(
          title: const Text('编辑用户名'),
          content: UsernameTextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final String newUsername = controller.text.trim();
                if (newUsername.isNotEmpty && newUsername != userId) {
                  try {
                    infoStore.renameUser(userId, newUsername);
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

/// 删除用户确认对话框：弹出后先 3 秒倒计时（红色数字、不可删除），
/// 倒计时结束才允许点击"删除"，防止误触误删。
class _DeleteUserDialog extends StatefulWidget {
  const _DeleteUserDialog({
    required this.infoStore,
    required this.userId,
    required this.onDeleted,
  });

  final InfoStore infoStore;
  final String userId;
  final VoidCallback onDeleted;

  @override
  State<_DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<_DeleteUserDialog> {
  static const int _countdownSeconds = 3;
  Timer? _timer;
  int _remaining = _countdownSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _remaining <= 0;
    return AlertDialog(
      title: const Text('删除用户'),
      content: Text('确定要删除用户 "${widget.userId}" 吗？'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        // 倒计时中：红色剩余秒数、禁用；倒计时结束：红色"删除"、可点击
        TextButton(
          onPressed: ready
              ? () {
                  widget.infoStore.deleteUser(widget.userId);
                  widget.onDeleted();
                  Navigator.of(context).pop();
                }
              : null,
          child: Text(
            ready ? '删除' : '$_remaining s',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
