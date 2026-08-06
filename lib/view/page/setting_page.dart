import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/view/page/about_page.dart';

/// 设置页：独立的 Scaffold
class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  /// 弹出第三方 API 地址编辑对话框
  void _showApiUrlDialog(BuildContext context, AppSettingsStore store) {
    // 先释放焦点：避免对话框关闭后焦点恢复，
    // 触发 PageView(allowImplicitScrolling) 自动滚回焦点所在的页面
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (context) {
        // 控制器在 builder 内创建、随对话框路由销毁后由 GC 回收，
        // 不手动 dispose：若 pop 后立即释放，路由退场动画期间
        // TextField 仍挂载，访问已释放的控制器会抛异常导致路由卡死
        final controller = TextEditingController(
          text: store.apiUrlNotifier.value,
        );
        return AlertDialog(
          title: const Text('第三方API'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'API 地址',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                store.setApiUrl(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
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
                      label: Text('系统'),
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
          ValueListenableBuilder<bool>(
            valueListenable: appSettingsStore.thirdPartyApiEnabledNotifier,
            builder: (context, enabled, _) {
              return ListTile(
                enabled: enabled,
                leading: const Icon(Icons.api),
                title: const Text('第三方API'),
                subtitle: ValueListenableBuilder<String>(
                  valueListenable: appSettingsStore.apiUrlNotifier,
                  builder: (context, url, _) {
                    return Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                // 开关关闭时禁止编辑（onTap 置空，整行置灰）
                onTap: enabled
                    ? () => _showApiUrlDialog(context, appSettingsStore)
                    : null,
                trailing: Switch(
                  value: enabled,
                  onChanged: appSettingsStore.setThirdPartyApiEnabled,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 先释放焦点：避免对话框关闭后焦点恢复，
              // 触发 PageView(allowImplicitScrolling) 自动滚回焦点所在的页面
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
