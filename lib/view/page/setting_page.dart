import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:grow_castle_calculator_next/core/service/update_checker.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting/about_page.dart';
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
      builder: (context) => _SettingEditDialog(
        title: '第三方 API',
        initialValue: store.apiUrlNotifier.value,
        decoration: const InputDecoration(labelText: 'API 地址'),
        onSubmit: store.setApiUrl,
      ),
    );
  }

  /// 弹出"查询并发数"编辑对话框（公会成员"上次在线"同时查询的请求数）
  void _showConcurrencyDialog(BuildContext context, AppSettingsStore store) {
    // 先释放焦点：避免对话框关闭后焦点恢复，
    // 触发 PageView(allowImplicitScrolling) 自动滚回焦点所在的页面
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => _SettingEditDialog(
        title: '查询并发数',
        initialValue: '${store.lastOnlineConcurrencyNotifier.value}',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: '并发数',
          helperText: '1-10',
          isDense: true,
        ),
        onSubmit: (text) {
          final value = int.tryParse(text);
          if (value != null) store.setLastOnlineConcurrency(value);
        },
      ),
    );
  }

  void _showGameTrackIntervalDialog(
    BuildContext context,
    AppSettingsStore store,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => _SettingEditDialog(
        title: '记录间隔',
        initialValue: '${store.gameTrackIntervalMinutesNotifier.value}',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: '分钟',
          helperText: '1-43200',
          isDense: true,
        ),
        onSubmit: (text) {
          final value = int.tryParse(text);
          if (value != null) store.setGameTrackIntervalMinutes(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettingsStore = Stores.appSettingsStore;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('用户管理'),
            subtitle: ValueListenableBuilder(
              valueListenable: Stores.infoStore.currentUserNotifier,
              builder: (context, value, child) {
                return Text(Stores.infoStore.getCurrentUsername());
              }
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SelectUserPage()),
              );
            },
          ),
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
                leading: const Icon(Icons.api),
                title: const Text('第三方 API'),
                subtitle: const Text('玩家详情页获取波速信息'),
                onTap: () => appSettingsStore.setThirdPartyApiEnabled(!enabled),
                trailing: Switch(
                  value: enabled,
                  onChanged: appSettingsStore.setThirdPartyApiEnabled,
                ),
              );
            },
          ),
          ValueListenableBuilder<String>(
            valueListenable: appSettingsStore.apiUrlNotifier,
            builder: (context, url, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: appSettingsStore.thirdPartyApiEnabledNotifier,
                builder: (context, enabled, child) {
                  return ListTile(
                    enabled: enabled,
                    leading: const Icon(Icons.link),
                    title: const Text('API 地址'),
                    subtitle: Text(url),
                    onTap: () => _showApiUrlDialog(context, appSettingsStore),
                  );
                }
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: appSettingsStore.autoLastOnlineEnabledNotifier,
            builder: (context, enabled, _) {
              return ListTile(
                onTap: () {
                  appSettingsStore.setAutoLastOnlineEnabled(!enabled);
                },
                leading: const Icon(Icons.schedule),
                title: const Text('自动查询上次在线'),
                subtitle: const Text('公会详情页查询成员"上次在线"'),
                trailing: Switch(
                  value: enabled,
                  onChanged: appSettingsStore.setAutoLastOnlineEnabled,
                ),
              );
            },
          ),
          // 查询并发数：公会成员"上次在线"同时进行的请求数
          ValueListenableBuilder<int>(
            valueListenable: appSettingsStore.lastOnlineConcurrencyNotifier,
            builder: (context, concurrency, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: appSettingsStore.autoLastOnlineEnabledNotifier,
                builder: (context, enabled, child) {
                  return ListTile(
                    enabled: enabled,
                    leading: const Icon(Icons.network_check),
                    title: const Text('查询并发数'),
                    subtitle: Text('$concurrency'),
                    onTap: () => _showConcurrencyDialog(context, appSettingsStore),
                  );
                }
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: appSettingsStore.gameTrackEnabledNotifier,
            builder: (context, enabled, _) {
              return ListTile(
                leading: const Icon(Icons.timeline),
                title: const Text('游戏轨迹记录'),
                subtitle: const Text('记录个人数据变化'),
                onTap: () => appSettingsStore.setGameTrackEnabled(!enabled),
                trailing: Switch(
                  value: enabled,
                  onChanged: appSettingsStore.setGameTrackEnabled,
                ),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: appSettingsStore.gameTrackIntervalMinutesNotifier,
            builder: (context, minutes, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: appSettingsStore.gameTrackEnabledNotifier,
                builder: (context, enabled, _) {
                  return ListTile(
                    enabled: enabled,
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('轨迹记录最小间隔'),
                    subtitle: Text('$minutes 分钟'),
                    onTap: () => _showGameTrackIntervalDialog(
                      context,
                      appSettingsStore,
                    ),
                  );
                },
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

class _SettingEditDialog extends StatefulWidget {
  const _SettingEditDialog({
    required this.title,
    required this.initialValue,
    required this.decoration,
    required this.onSubmit,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
  });

  final String title;

  final String initialValue;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final InputDecoration decoration;

  final ValueChanged<String> onSubmit;

  @override
  State<_SettingEditDialog> createState() => _SettingEditDialogState();
}

class _SettingEditDialogState extends State<_SettingEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SelectAllTextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        decoration: widget.decoration,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onSubmit(_controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
