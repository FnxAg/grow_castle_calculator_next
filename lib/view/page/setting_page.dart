import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:grow_castle_calculator_next/core/service/update_checker.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting/about_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting/backup_page.dart';
import 'package:grow_castle_calculator_next/view/widget/setting_edit_dialog.dart';

/// 设置页
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? _currentVersion;

  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _currentVersion = info.version);
    });
  }

  Future<void> _checkUpdate() async {
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    if (_checking) return;
    setState(() => _checking = true);
    final release = await UpdateChecker.fetchLatestRelease();
    if (!mounted) return;
    setState(() => _checking = false);

    if (release == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.snackUpdateCheckFailed)));
      return;
    }
    final current = _currentVersion;
    if (current != null &&
        UpdateChecker.compareVersions(release.tagName, current) <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snackAlreadyLatest(current))));
      return;
    }
    final body = release.body;
    final hasNotes = body != null && body.trim().isNotEmpty;
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(l10n.dialogUpdateAvailable),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.dialogUpdateAvailableBody(
                    current == null ? 'no' : 'yes',
                    release.tagName,
                    current ?? '',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasNotes) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.labelChangelog,
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
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchUrl(release.htmlUrl);
              },
              child: Text(l10n.actionOpenReleasePage),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).snackCannotOpenLink(url)),
        ),
      );
    }
  }

  void _showApiUrlDialog(BuildContext context, AppSettingsStore store) {
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => SettingEditDialog(
        title: l10n.settingsThirdPartyApi,
        initialValue: store.apiUrlNotifier.value,
        decoration: InputDecoration(labelText: l10n.labelApiUrl),
        onSubmit: store.setApiUrl,
      ),
    );
  }

  void _showConcurrencyDialog(BuildContext context, AppSettingsStore store) {
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => SettingEditDialog(
        title: l10n.settingsQueryConcurrency,
        initialValue: '${store.lastOnlineConcurrencyNotifier.value}',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.labelConcurrency,
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
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => SettingEditDialog(
        title: l10n.settingsTrackInterval,
        initialValue: '${store.gameTrackIntervalMinutesNotifier.value}',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.labelMinutes,
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
    final l10n = AppLocalizations.of(context);
    final currentVersion = _currentVersion;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.group),
            title: Text(l10n.settingsUserManagement),
            subtitle: ValueListenableBuilder(
              valueListenable: Stores.infoStore.currentUserNotifier,
              builder: (context, value, child) {
                return Text(Stores.infoStore.getCurrentUsername());
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SelectUserPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(l10n.settingsThemeMode),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: appSettingsStore.themeModeNotifier,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(l10n.themeDark),
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
            leading: const Icon(Icons.translate),
            title: Text(AppLocalizations.of(context).settingsLanguage),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ValueListenableBuilder<AppLanguage>(
              valueListenable: appSettingsStore.languageNotifier,
              builder: (context, language, _) {
                return SegmentedButton<AppLanguage>(
                  segments: [
                    ButtonSegment(
                      value: AppLanguage.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(l10n.languageSystem),
                    ),
                    ButtonSegment(
                      value: AppLanguage.zh,
                      label: Text(l10n.languageChinese),
                    ),
                    ButtonSegment(
                      value: AppLanguage.en,
                      label: Text(l10n.languageEnglish),
                    ),
                  ],
                  selected: {language},
                  onSelectionChanged: (selection) {
                    appSettingsStore.setLanguage(selection.first);
                  },
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: appSettingsStore.thirdPartyApiEnabledNotifier,
                builder: (context, enabled, _) {
                  return ListTile(
                    leading: const Icon(Icons.api),
                    title: Text(l10n.settingsThirdPartyApi),
                    subtitle: Text(l10n.settingsThirdPartyApiSubtitle),
                    onTap: () =>
                        appSettingsStore.setThirdPartyApiEnabled(!enabled),
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
                    valueListenable:
                        appSettingsStore.thirdPartyApiEnabledNotifier,
                    builder: (context, enabled, child) {
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.linearToEaseOut,
                        child: SizedBox(
                          child: !enabled
                              ? const SizedBox(height: 0)
                              : ListTile(
                                  leading: const Icon(Icons.link),
                                  title: Text(l10n.labelApiUrl),
                                  subtitle: Text(url),
                                  onTap: () => _showApiUrlDialog(
                                    context,
                                    appSettingsStore,
                                  ),
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: appSettingsStore.autoLastOnlineEnabledNotifier,
                builder: (context, enabled, _) {
                  return ListTile(
                    onTap: () {
                      appSettingsStore.setAutoLastOnlineEnabled(!enabled);
                    },
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.settingsAutoLastOnline),
                    subtitle: Text(l10n.settingsAutoLastOnlineSubtitle),
                    trailing: Switch(
                      value: enabled,
                      onChanged: appSettingsStore.setAutoLastOnlineEnabled,
                    ),
                  );
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: appSettingsStore.lastOnlineConcurrencyNotifier,
                builder: (context, concurrency, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        appSettingsStore.autoLastOnlineEnabledNotifier,
                    builder: (context, enabled, child) {
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.linearToEaseOut,
                        child: !enabled
                            ? const SizedBox(height: 0)
                            : ListTile(
                                leading: const Icon(Icons.network_check),
                                title: Text(l10n.settingsQueryConcurrency),
                                subtitle: Text('$concurrency'),
                                onTap: () => _showConcurrencyDialog(
                                  context,
                                  appSettingsStore,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: appSettingsStore.gameTrackEnabledNotifier,
                builder: (context, enabled, _) {
                  return ListTile(
                    leading: const Icon(Icons.timeline),
                    title: Text(l10n.settingsGameTrack),
                    subtitle: Text(l10n.settingsGameTrackSubtitle),
                    onTap: () => appSettingsStore.setGameTrackEnabled(!enabled),
                    trailing: Switch(
                      value: enabled,
                      onChanged: appSettingsStore.setGameTrackEnabled,
                    ),
                  );
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable:
                    appSettingsStore.gameTrackIntervalMinutesNotifier,
                builder: (context, minutes, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: appSettingsStore.gameTrackEnabledNotifier,
                    builder: (context, enabled, _) {
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.linearToEaseOut,
                        child: !enabled
                            ? const SizedBox(height: 0)
                            : ListTile(
                                enabled: enabled,
                                leading: const Icon(Icons.timer_outlined),
                                title: Text(l10n.settingsGameTrackMinInterval),
                                subtitle: Text(
                                  l10n.settingsGameTrackIntervalValue(minutes),
                                ),
                                onTap: () => _showGameTrackIntervalDialog(
                                  context,
                                  appSettingsStore,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          // 数据备份：WebDAV 云备份/恢复 + 本地导入导出
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(l10n.settingsDataBackup),
            subtitle: Text(l10n.settingsDataBackupSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BackupPage()),
              );
            },
          ),
          // 检查更新：查询 GitHub 最新发布（镜像备用），发现新版弹窗展示
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: Text(l10n.settingsCheckUpdate),
            subtitle: currentVersion == null
                ? null
                : Text(l10n.settingsCurrentVersion(currentVersion)),
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
            title: Text(l10n.settingsAbout),
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
