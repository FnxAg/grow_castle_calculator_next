import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/user_info.dart';

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
            icon: Icon(Icons.edit, color: _settingState ? Colors.red : null),
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
                        infoStore.getTotalGold(userId).toStringAsFixed(0),
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
                : const Spacer(),
            trailing: !_settingState
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: switch (infoStore.getUserId(userId)) {
                      0 => null,
                      _ => () {
                        infoStore.deleteUser(userId);
                        setState(() {});
                      },
                    },
                  ),
            onTap: () {
              infoStore.setCurrentUser(userId);
              Navigator.pop(context);
            },
            onLongPress: switch (infoStore.getUserId(userId)) {
              0 => null,
              _ => () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final TextEditingController controller =
                        TextEditingController(text: userId);
                    return AlertDialog(
                      title: const Text('编辑用户名'),
                      content: TextField(
                        controller: controller,
                        maxLines: 1,
                        maxLength: 14,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-_ ]')),
                        ],
                        decoration: const InputDecoration(
                          hintText: '输入新用户名',
                          helperText: '0-9, a-z, A-Z, -, _, space',
                        ),
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
                            final String newUsername = controller.text.trim();
                            if (newUsername.isNotEmpty &&
                                newUsername != userId) {
                              infoStore.renameUser(userId, newUsername);
                              setState(() {});
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('保存'),
                        ),
                      ],
                    );
                  },
                );
              },
            },
          );
        },
      ),
    );
  }
}
