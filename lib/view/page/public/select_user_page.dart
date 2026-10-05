import 'dart:async';

import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/unit_summary_sheet.dart';
import 'package:grow_castle_calculator_next/view/widget/username_textfield.dart';
import 'package:material_ui/material_ui.dart';

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
          final String guild = infoStore.getUserGuild(username);
          // 桌面端右键也可打开单位汇总（触屏长按入口保留）
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
                                infoStore.getUserWave(username).format(),
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
                                infoStore
                                    .getUserTotalGold(username)
                                    .formatCompact(
                                      fractionDigits: 2,
                                      english: !context.isChineseLocale,
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
              leading: infoStore.getCurrentUsername() == username
                  ? const Icon(Icons.check, color: Colors.green)
                  : const SizedBox(width: 24.0),
              // 编辑态显示编辑/删除按钮；单位汇总按钮常显（长按与右键同入口）
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_settingState && infoStore.getUserId(username) != 0) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: switch (infoStore.getUserId(username)) {
                        0 => () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.snackDefaultUserNoRename),
                            ),
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
                            SnackBar(
                              content: Text(l10n.snackDefaultUserNoDelete),
                            ),
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
                infoStore.setCurrentUser(username);
                Navigator.pop(context);
              },
              // 长按查看该用户的单位汇总（任意用户均可用，含默认用户）
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

  /// 打开指定用户的单位汇总（信息按钮 / 长按 / 右键共用入口）
  void _showUnitSummary(String username) {
    final data = Stores.infoStore.getUserData(username);
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
            ready ? l10n.actionDelete : '$_remaining s',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({required this.infoStore, required this.onAdded});

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
