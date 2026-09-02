import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
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
    final List<String> userList = infoStore.getAllUsernames();

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
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
        itemCount: userList.length,
        itemBuilder: (ctx, index) {
          final String username = userList[index];
          final String guild = infoStore.getUserGuild(username);
          return ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(username),
                          if (guild.isNotEmpty)
                            PillChip(
                              text: Text(
                                guild,
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              icon: Icons.flag_circle,
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          PillChip(
                            text: Text(
                              infoStore.getUserWave(username).format(),
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            icon: Icons.emoji_events,
                          ),
                          const SizedBox(width: 1.0),
                          PillChip(
                            text: Text(
                              infoStore.getUserTotalGold(username).formatCompact(fractionDigits: 2, english: false),
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            icon: Icons.monetization_on,
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
            leading: infoStore.getCurrentUsername() == username
                ? const Icon(Icons.check, color: Colors.green)
                : const SizedBox(width: 24.0),
            trailing: !_settingState
                ? null
                : infoStore.getUserId(username) == 0
                    ? null
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: switch (infoStore.getUserId(username)) {
                            0 => () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('默认用户不可重命名')),
                              );
                            },
                            _ => () => _renameDialog(infoStore, username),
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: switch (infoStore.getUserId(username)) {
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
                                  userId: username,
                                  onDeleted: () => setState(() {}),
                                ),
                              );
                            },
                          },
                        ),
                      ],
                    ),
            onTap: () {
              infoStore.setCurrentUser(username);
              Navigator.pop(context);
            },
            // 长按查看该用户的单位汇总（任意用户均可用，含默认用户）
            onLongPress: () {
              final data = infoStore.getUserData(username);
              if (data == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('未找到用户「$username」的数据')),
                );
                return;
              }
              showUnitSummarySheet(context, username: username, data: data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUserDialog,
        icon: const Icon(Icons.add),
        label: const Text('添加用户'),
      ),
    );
  }

  void _addUserDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddUserDialog(
        infoStore: Stores.infoStore,
        onAdded: () => setState(() {}),
      ),
    );
  }

  void _renameDialog(InfoStore infoStore, String username) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _EditUserDialog(
        infoStore: infoStore,
        username: username,
        onSaved: () => setState(() {}),
      ),
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

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({
    required this.infoStore,
    required this.onAdded,
  });

  final InfoStore infoStore;

  final VoidCallback onAdded;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _guildController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    _guildController.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _userController.text.trim();
    if (username.isNotEmpty) {
      try {
        widget.infoStore.createUser(
          username,
          guild: _guildController.text.trim(),
        );
        widget.infoStore.setCurrentUser(username);
        widget.onAdded();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加用户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NameTextField(
            controller: _userController,
            labelText: '用户名',
            autofocus: true,
          ),
          const SizedBox(height: 8.0),
          NameTextField(
            controller: _guildController,
            labelText: '公会（选填）',
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({
    required this.infoStore,
    required this.username,
    required this.onSaved,
  });

  final InfoStore infoStore;

  final String username;

  final VoidCallback onSaved;

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _userController;
  late final TextEditingController _guildController;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.username);
    _guildController = TextEditingController(
      text: widget.infoStore.getUserGuild(widget.username),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _guildController.dispose();
    super.dispose();
  }

  void _submit() {
    final String newUsername = _userController.text.trim();
    final String newGuild = _guildController.text.trim();
    final String oldGuild =
        widget.infoStore.getUserData(widget.username)?.guild ?? '';
    final bool renamed =
        newUsername.isNotEmpty && newUsername != widget.username;
    try {
      if (renamed) {
        widget.infoStore.renameUser(widget.username, newUsername);
      }
      if (newGuild != oldGuild) {
        widget.infoStore.setUserGuild(
          renamed ? newUsername : widget.username,
          newGuild,
        );
      }
      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑用户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NameTextField(
            controller: _userController,
            labelText: '用户名',
            autofocus: true,
          ),
          const SizedBox(height: 8.0),
          NameTextField(
            controller: _guildController,
            labelText: '公会',
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
