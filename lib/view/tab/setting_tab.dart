import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';

/// 设置 tab：独立的 Scaffold（无抽屉）
class SettingTab extends StatelessWidget {
  const SettingTab({super.key});

  Future<PackageInfo> _getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final appSettingsStore = Stores.appSettingsStore;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('主题模式'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: appSettingsStore.themeModeNotifier,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('系统默认'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('亮色'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('暗色'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) {
                    appSettingsStore.setThemeMode(selection.first);
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () async {
              // 先释放焦点：避免对话框关闭后焦点恢复，
              // 触发 PageView(allowImplicitScrolling) 自动滚回焦点所在的页面
              FocusManager.instance.primaryFocus?.unfocus();
              final PackageInfo packageInfo = await _getPackageInfo();
              final appName = packageInfo.appName;
              final version = packageInfo.version;
              final buildNumber = packageInfo.buildNumber;
              if (!context.mounted) return;
              showAboutDialog(
                context: context,
                applicationName: appName,
                applicationVersion: '$version ($buildNumber)',
                applicationIcon: const Icon(Icons.castle),
                applicationLegalese: 'FnxAg',
                children: [
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
