import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:grow_castle_calculator_next/core/service/update_checker.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/view/page/about_page.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 设置页：独立的 Scaffold
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  /// 当前应用版本号（来自包信息，用于比较与展示）
  String? _currentVersion;

  /// 检查更新进行中（trailing 显示转圈并禁用点击）
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _currentVersion = info.version);
    });
  }

  /// 检查更新：查 GitHub 最新发布并与当前版本比较。
  /// 查询失败提示网络错误；已最新提示当前版本；有新版弹窗展示更新日志，
  /// 「打开发布页」用系统浏览器打开 GitHub 发布页。
  Future<void> _checkUpdate() async {
    // 先释放焦点：避免对话框关闭后焦点恢复，
    // 触发 PageView(allowImplicitScrolling) 自动滚回焦点所在的页面
    FocusManager.instance.primaryFocus?.unfocus();
    if (_checking) return;
    setState(() => _checking = true);
    final release = await UpdateChecker.fetchLatestRelease();
    if (!mounted) return;
    setState(() => _checking = false);

    if (release == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('检查更新失败，请检查网络后重试')),
      );
      return;
    }
    final current = _currentVersion;
    if (current != null &&
        UpdateChecker.compareVersions(release.tagName, current) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已是最新版本 v$current')),
      );
      return;
    }
    final body = release.body;
    final hasNotes = body != null && body.trim().isNotEmpty;
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('发现新版本'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '最新版本 ${release.tagName}'
                  '${current == null ? '' : '（当前 v$current）'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasNotes) ...[
                  const SizedBox(height: 12),
                  Text(
                    '更新日志：',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchUrl(release.htmlUrl);
              },
              child: const Text('打开发布页'),
            ),
          ],
        );
      },
    );
  }

  /// 用系统浏览器打开外部链接；失败时 SnackBar 提示
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开链接：$url')),
      );
    }
  }

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
          content: SelectAllTextField(
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
          // 检查更新：查询 GitHub 最新发布（镜像备用），发现新版弹窗展示
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('检查更新'),
            subtitle:
                _currentVersion == null ? null : Text('当前版本 v$_currentVersion'),
            trailing: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                : null,
            onTap: _checking ? null : _checkUpdate,
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
