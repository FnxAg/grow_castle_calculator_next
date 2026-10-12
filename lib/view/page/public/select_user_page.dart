import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/unit_summary_sheet.dart';
import 'package:grow_castle_calculator_next/view/widget/username_textfield.dart';
import 'package:material_ui/material_ui.dart';

class SelectUserPage extends ConsumerStatefulWidget {
  const SelectUserPage({super.key});

  @override
  ConsumerState<SelectUserPage> createState() => _SelectUserPageState();
}

class _SelectUserPageState extends ConsumerState<SelectUserPage> {
  bool _settingState = false;

  @override
  Widget build(BuildContext context) {
    // 整体 watch：用户列表与每个用户的波数/总金币都从这里渲染，
    // 增删改切之后本页自动重建，不再需要子对话框回调 setState
    final state = ref.watch(usersProvider);
    final List<String> userList = state.usernames;
    final String currentUsername = state.currentUser.username;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsUserManagement),
        actions: [
          IconButton(
            icon: Icon(!_settingState ? Icons.edit : Icons.edit_off),
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
          final user = state.findByUsername(username);
          final String guild = user?.guild ?? '';
          // 桌面端右键也可打开单位汇总，同时保留触屏长按入口
          return GestureDetector(
            onSecondaryTapUp: (_) => _showUnitSummary(username),
            child: ListTile(
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
                                (user?.wave ?? 1).format(),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                              icon: Icons.emoji_events,
                            ),
                            const SizedBox(width: 1.0),
                            PillChip(
                              text: Text(
                                (user?.totalGold ?? 0.0).formatCompact(
                                  fractionDigits: 2,
                                  english: !context.isChineseLocale,
                                  traditional:
                                      context.isTraditionalChineseLocale,
                                ),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
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
              leading: currentUsername == username
                  ? const Icon(Icons.check, color: Colors.green)
                  : const SizedBox(width: 24.0),
              // 编辑态显示编辑/删除按钮
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_settingState && state.findId(username) != 0) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: switch (state.findId(username)) {
                        0 => () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.snackDefaultUserNoRename),
                            ),
                          );
                        },
                        _ => () => _renameDialog(username),
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: switch (state.findId(username)) {
                        0 => () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.snackDefaultUserNoDelete),
                            ),
                          );
                        },
                        _ => () {
                          showDialog<void>(
                            context: context,
                            builder: (context) =>
                                _DeleteUserDialog(userId: username),
                          );
                        },
                      },
                    ),
                  ],
                  isDesktop
                      ? IconButton(
                          icon: const Icon(Icons.info_outline, size: 20),
                          tooltip: l10n.tooltipDetails,
                          onPressed: () => _showUnitSummary(username),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              onTap: () {
                ref.users.setCurrentUser(username);
                Navigator.pop(context);
              },
              // 长按查看该用户的单位汇总
              onLongPress: () => _showUnitSummary(username),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUserDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddUser),
      ),
    );
  }

  /// 打开指定用户的单位汇总
  void _showUnitSummary(String username) {
    final data = ref.read(usersProvider).findByUsername(username);
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).errorUserDataNotFound(username),
          ),
        ),
      );
      return;
    }
    showUnitSummarySheet(context, username: username, data: data);
  }

  void _addUserDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => const _AddUserDialog(),
    );
  }

  void _renameDialog(String username) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _EditUserDialog(username: username),
    );
  }
}

/// 删除用户确认对话框，3 秒倒计时后允许删除
class _DeleteUserDialog extends ConsumerStatefulWidget {
  const _DeleteUserDialog({required this.userId});

  final String userId;

  @override
  ConsumerState<_DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends ConsumerState<_DeleteUserDialog> {
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dialogDeleteUser),
      content: Text(l10n.dialogDeleteUserConfirm(widget.userId)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.actionCancel),
        ),
        // 倒计时中
        TextButton(
          onPressed: ready
              ? () {
                  ref.users.deleteUser(widget.userId);
                  Navigator.of(context).pop();
                }
              : null,
          child: Text(
            ready ? l10n.actionDelete : '$_remaining s',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _AddUserDialog extends ConsumerStatefulWidget {
  const _AddUserDialog();

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
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
        ref.users.createUser(
          username,
          guild: _guildController.text.trim(),
        );
        ref.users.setCurrentUser(username);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.actionAddUser),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NameTextField(
            controller: _userController,
            labelText: l10n.labelUsername,
            autofocus: true,
          ),
          const SizedBox(height: 8.0),
          NameTextField(
            controller: _guildController,
            labelText: l10n.labelGuildOptional,
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.actionAdd)),
      ],
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog({required this.username});

  final String username;

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final TextEditingController _userController;
  late final TextEditingController _guildController;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.username);
    _guildController = TextEditingController(
      text: ref.read(usersProvider).findByUsername(widget.username)?.guild ?? '',
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
        ref.read(usersProvider).findByUsername(widget.username)?.guild ?? '';
    final bool renamed =
        newUsername.isNotEmpty && newUsername != widget.username;
    try {
      if (renamed) {
        ref.users.renameUser(widget.username, newUsername);
      }
      if (newGuild != oldGuild) {
        ref.users.setUserGuild(
          renamed ? newUsername : widget.username,
          newGuild,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dialogEditUser),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NameTextField(
            controller: _userController,
            labelText: l10n.labelUsername,
            autofocus: true,
          ),
          const SizedBox(height: 8.0),
          NameTextField(
            controller: _guildController,
            labelText: l10n.tabGuild,
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }
}
