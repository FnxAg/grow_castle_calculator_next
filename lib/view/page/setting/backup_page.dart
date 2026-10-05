import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/extension/service_error_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/setting_edit_dialog.dart';

/// 覆盖确认弹窗的选择结果
enum _OverwriteDecision { overwrite, restoreFromCloud }

/// 确认弹窗里的附加提示（error 为 true 时用错误色）
typedef _ConfirmWarning = ({String text, bool isError});

/// 数据备份页：WebDAV 配置与手动备份/云端恢复 + 本地导出/导入。
///
/// 上传前先探测云端元信息、与本机上次成功备份比对，弹窗确认后才覆盖——
/// 云端只有一份文件，覆盖不可找回，因此本页不存在静默上传路径。
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupService _service = BackupService.instance;
  late final WebDavConfigStore _config;

  /// 本页正在与云端交互（探测元信息 / 下载预览）；
  /// 上传与恢复的执行期由 service.busyNotifier 驱动
  bool _remoteBusy = false;

  @override
  void initState() {
    super.initState();
    _config = Stores.webDavConfigStore;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsDataBackup)),
      body: ListView(
        children: [
          SectionHeader(l10n.sectionWebdavBackup),
          // 服务器配置行（手动备份与云端恢复共用）
          _buildConfigRows(scheme),
          // 手动操作与状态
          ValueListenableBuilder<bool>(
            valueListenable: _service.busyNotifier,
            builder: (context, busy, _) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: Text(l10n.actionBackupNow),
                  subtitle: Text(
                    _config.isConfigured
                        ? l10n.backupNowSubtitleReady
                        : l10n.backupServerNotConfigured,
                  ),
                  trailing: busy || _remoteBusy ? _spinner() : null,
                  enabled: !busy && !_remoteBusy,
                  onTap: _onManualBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: Text(l10n.actionRestoreFromCloud),
                  subtitle: Text(l10n.backupRestoreSubtitle),
                  trailing: _remoteBusy ? _spinner() : null,
                  enabled: !busy && !_remoteBusy,
                  onTap: _onRestoreFromCloud,
                ),
              ],
            ),
          ),
          _buildStatusArea(),
          SectionHeader(l10n.sectionLocalFiles),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(l10n.actionExportToFile),
            subtitle: Text(l10n.backupExportSubtitle),
            onTap: _onExportFile,
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l10n.actionImportFile),
            subtitle: Text(l10n.backupImportSubtitle),
            onTap: _onImportFile,
          ),
          SectionHeader(l10n.sectionInfo),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Text(
              l10n.backupOverwriteHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _spinner() => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.0),
      );

  /// 服务器地址/账号/密码配置行
  Widget _buildConfigRows(ColorScheme scheme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: _config.urlNotifier,
          builder: (context, url, _) => ListTile(
            leading: const Icon(Icons.link),
            title: Text(l10n.labelServerAddress),
            subtitle: Text(url.isEmpty ? l10n.labelNotSet : url),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUrlDialog(),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _config.usernameNotifier,
          builder: (context, username, _) => ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.labelAccount),
            subtitle: Text(username.isEmpty ? l10n.labelNotSet : username),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUsernameDialog(),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _config.passwordNotifier,
          builder: (context, password, _) => ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.labelPassword),
            subtitle: Text(password.isEmpty ? l10n.labelNotSet : '••••••'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPasswordDialog(),
          ),
        ),
      ],
    );
  }

  /// 备份状态区：上次成功/失败时间（手动备份的留痕；探测失败不写入）
  Widget _buildStatusArea() {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        _config.lastSuccessAtNotifier,
        _config.lastErrorAtNotifier,
        _config.lastErrorNotifier,
      ]),
      builder: (context, _) {
        final successMs = _config.lastSuccessAtNotifier.value;
        final errorAt = _config.lastErrorAtNotifier.value;
        final error = _config.lastErrorNotifier.value;
        final style = Theme.of(context).textTheme.bodySmall;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.backupLastSuccess(
                  successMs == null ? l10n.labelNever : _formatClock(successMs),
                ),
                style: style?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (error != null)
                Text(
                  l10n.backupLastFailed(
                    errorAt == null ? 'no' : 'yes',
                    storedBackupFailureText(l10n, error),
                    errorAt == null ? '' : _formatClock(errorAt),
                  ),
                  style: style?.copyWith(color: scheme.error),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── 配置输入弹窗 ──────────────────────────────────────────────

  void _showUrlDialog() {
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => SettingEditDialog(
        title: l10n.labelServerAddress,
        initialValue: _config.urlNotifier.value,
        decoration: InputDecoration(labelText: l10n.labelServerUrlExample),
        onSubmit: _config.setUrl,
      ),
    );
  }

  void _showUsernameDialog() {
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => SettingEditDialog(
        title: l10n.labelAccount,
        initialValue: _config.usernameNotifier.value,
        decoration: InputDecoration(labelText: l10n.labelWebdavAccount),
        onSubmit: _config.setUsername,
      ),
    );
  }

  void _showPasswordDialog() {
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => SettingEditDialog(
        title: l10n.labelPassword,
        initialValue: _config.passwordNotifier.value,
        decoration: InputDecoration(labelText: l10n.labelWebdavPassword),
        obscureText: true,
        showVisibilityToggle: true,
        onSubmit: _config.setPassword,
      ),
    );
  }

  // ── 手动备份：探测 → 确认 → 上传 ───────────────────────────────

  Future<void> _onManualBackup() async {
    final l10n = AppLocalizations.of(context);
    // 未配置守卫必须在探测之前：否则会发出真实网络请求
    if (!_config.isConfigured) {
      _snack(l10n.backupNotConfigured);
      return;
    }
    if (_remoteBusy || _service.busyNotifier.value) return; // 防同帧双击

    final info = await _probeRemoteBackup();
    if (info == null || !mounted) return; // 探测失败即拦截，不提供"忽略检测"
    final relation = BackupService.compareRemoteBackup(
      info: info,
      lastSuccessAtMs: _config.lastSuccessAtNotifier.value,
    );
    final decision = await _confirmOverwrite(info, relation);
    if (decision == null || !mounted) return;
    if (decision == _OverwriteDecision.restoreFromCloud) {
      await _onRestoreFromCloud();
      return;
    }
    final error = await _service.manualBackup();
    if (!mounted) return;
    _snack(
      error == null
          ? l10n.snackBackupSuccess
          : l10n.snackBackupFailed(backupFailureText(l10n, error)),
    );
  }

  /// 探测云端备份元信息；失败只提示并返回 null（不写失败留痕：
  /// 备份根本没发起，记进状态区会谎报"上次备份失败"）
  Future<WebDavFileInfo?> _probeRemoteBackup() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _remoteBusy = true);
    try {
      return await _service.fetchRemoteInfo();
    } on WebDavException catch (e) {
      if (mounted) {
        _snack(l10n.snackRemoteProbeFailed(webdavExceptionText(l10n, e)));
      }
      return null;
    } catch (_) {
      if (mounted) _snack(l10n.snackRemoteProbeFailedRetry);
      return null;
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
  }

  /// 覆盖确认弹窗：并列展示云端与本机记录，云端显新时高亮警告。
  /// 只有 remoteNewer 额外给"恢复云端"捷径——警告语已在说云端更新，
  /// 用户的自然反应就是改用云端那份；其余结论下不该暗示某一侧更优。
  Future<_OverwriteDecision?> _confirmOverwrite(
    WebDavFileInfo info,
    RemoteBackupRelation relation,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final lastSuccessMs = _config.lastSuccessAtNotifier.value;
    final warn = relation == RemoteBackupRelation.remoteNewer ||
        relation == RemoteBackupRelation.remoteUnknown;
    final int? contentLength = info.contentLength;
    final String remoteLine;
    if (!info.exists) {
      remoteLine = l10n.dialogCloudBackupNoFile;
    } else {
      remoteLine = l10n.dialogCloudBackupLine(
        contentLength == null ? 'no' : 'yes',
        _clockOrUnknown(l10n, info.lastModified),
        contentLength == null ? '' : '${contentLength ~/ 1024}',
      );
    }
    final localLine = l10n.dialogLastLocalBackupLine(
      lastSuccessMs == null ? l10n.labelNever : _formatClock(lastSuccessMs),
    );
    return showDialog<_OverwriteDecision>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dialogUploadBackupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(remoteLine),
            Text(localLine),
            if (warn) ...[
              const SizedBox(height: 12),
              Text(
                _overwriteWarning(l10n, info, relation, lastSuccessMs),
                style: TextStyle(color: scheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          if (relation == RemoteBackupRelation.remoteNewer)
            TextButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(_OverwriteDecision.restoreFromCloud),
              child: Text(l10n.actionRestoreRemote),
            ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_OverwriteDecision.overwrite),
            style: warn
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            child: Text(!info.exists
                ? l10n.actionUpload
                : warn
                    ? l10n.actionOverwriteAnyway
                    : l10n.actionOverwriteUpload),
          ),
        ],
      ),
    );
  }

  /// 警告文案：remoteNewer 一种成因；remoteUnknown 分"取不到时间"与
  /// "本机无成功记录"两种，措辞分开便于用户判断该不该继续
  static String _overwriteWarning(
    AppLocalizations l10n,
    WebDavFileInfo info,
    RemoteBackupRelation relation,
    int? lastSuccessMs,
  ) {
    if (relation == RemoteBackupRelation.remoteNewer) {
      return l10n.dialogWarningRemoteNewer;
    }
    if (info.lastModified == null) {
      return l10n.dialogWarningRemoteTimeUnknown;
    }
    if (lastSuccessMs == null) {
      return l10n.dialogWarningLocalNoRecord;
    }
    return '';
  }

  // ── 云端恢复 ───────────────────────────────────────────────────

  Future<void> _onRestoreFromCloud() async {
    final l10n = AppLocalizations.of(context);
    if (!_config.isConfigured) {
      _snack(l10n.backupNotConfigured);
      return;
    }
    if (_remoteBusy || _service.busyNotifier.value) return;
    setState(() => _remoteBusy = true);
    RemoteBackupPreview? preview;
    try {
      preview = await _service.fetchRemotePreview();
    } on WebDavException catch (e) {
      if (mounted) _snack(l10n.snackFetchRemoteFailed(webdavExceptionText(l10n, e)));
    } on DataArchiveException catch (e) {
      if (mounted) {
        _snack(l10n.snackInvalidCloudFile(archiveExceptionText(l10n, e)));
      }
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
    if (preview == null || !mounted) {
      if (preview == null && mounted) {
        _snack(l10n.webdavNoBackupFile);
      }
      return;
    }
    final fileInfo = preview.fileInfo;
    final modified = fileInfo.lastModified;
    final int? contentLength = fileInfo.contentLength;
    final source = l10n.dialogRestoreCloudSource(
      modified == null ? 'no' : 'yes',
      modified == null ? '' : _formatClock(modified.millisecondsSinceEpoch),
      contentLength == null ? 'no' : 'yes',
      contentLength == null ? '' : '${contentLength ~/ 1024}',
    );
    await _confirmAndApply(
      title: l10n.actionRestoreFromCloud,
      source: source,
      contents: preview.contents,
      warning: _restoreWarning(fileInfo),
    );
  }

  /// 恢复方向的提示：危险方与上传相反——云端较旧意味着会退回旧数据。
  /// 复用预览已带回的 fileInfo，不再多发请求
  _ConfirmWarning? _restoreWarning(WebDavFileInfo info) {
    final l10n = AppLocalizations.of(context);
    final relation = BackupService.compareRemoteBackup(
      info: info,
      lastSuccessAtMs: _config.lastSuccessAtNotifier.value,
    );
    final localMs = _config.lastSuccessAtNotifier.value;
    switch (relation) {
      case RemoteBackupRelation.remoteOlder:
        return (
          text: l10n.dialogWarningRestoreOlder(
            localMs == null ? 'no' : 'yes',
            localMs == null ? '' : _formatClock(localMs),
          ),
          isError: true,
        );
      case RemoteBackupRelation.remoteNewer:
        return (
          text: l10n.dialogWarningRestoreNewer,
          isError: false,
        );
      case RemoteBackupRelation.remoteUnknown:
        return (
          text: l10n.dialogWarningRestoreUnknown,
          isError: false,
        );
      case RemoteBackupRelation.noRemote:
        // 有预览必然存在云端文件，此分支不会走到
        return null;
    }
  }

  // ── 本地导出/导入 ──────────────────────────────────────────────

  Future<void> _onExportFile() async {
    final l10n = AppLocalizations.of(context);
    final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(
        utf8.encode(await _service.buildArchiveText()),
      );
    } catch (e) {
      if (mounted) _snack(l10n.snackExportFailed);
      return;
    }
    final now = DateTime.now();
    final stamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    final uri = await FilePicker.saveFile(
      fileName: 'gcc_backup_$stamp.json',
      bytes: bytes,
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: l10n.dialogTitleExportBackup,
    );
    if (!mounted) return;
    // null = 用户取消
    if (uri != null) {
      _snack(l10n.snackExportSuccess);
    }
  }

  Future<void> _onImportFile() async {
    final l10n = AppLocalizations.of(context);
    final file = await FilePicker.pickFile(
      dialogTitle: l10n.dialogTitlePickBackupFile,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null || !mounted) return; // 用户取消

    final ArchiveContents contents;
    try {
      final text = utf8.decode(await file.readAsBytes());
      contents = DataArchive.decode(text);
    } on DataArchiveException catch (e) {
      if (mounted) _snack(l10n.snackInvalidFile(archiveExceptionText(l10n, e)));
      return;
    } catch (e) {
      if (mounted) _snack(l10n.snackReadFileFailed);
      return;
    }
    if (!mounted) return;
    await _confirmAndApply(
      title: l10n.actionImportFile,
      source: l10n.dialogPickLocalFileSource(file.name),
      contents: contents,
    );
  }

  /// 恢复前确认弹窗 → 覆盖式恢复
  Future<void> _confirmAndApply({
    required String title,
    required String source,
    required ArchiveContents contents,
    _ConfirmWarning? warning,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.dialogRestoreSource(source)}\n\n'
              '${_describeArchive(l10n, contents)}\n\n'
              '${l10n.backupOverwriteHint}',
            ),
            if (warning != null) ...[
              const SizedBox(height: 12),
              Text(
                warning.text,
                style: TextStyle(
                  color: warning.isError
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionOverwriteRestore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await _service.applyArchive(contents);
    if (!mounted) return;
    _snack(
      error == null
          ? l10n.snackRestoreSuccess
          : l10n.snackRestoreFailed(backupFailureText(l10n, error)),
    );
  }

  /// 预览文案：归档导出时间与内容摘要
  String _describeArchive(AppLocalizations l10n, ArchiveContents contents) {
    final lines = <String>[];
    final exported = contents.exportedAt;
    lines.add(
      l10n.labelBackupTime(
        exported == null
            ? l10n.labelUnknown
            : _formatClock(exported.millisecondsSinceEpoch),
      ),
    );
    lines.add(l10n.labelUserCount(contents.userCount));
    lines.add(l10n.labelTrackRecordCount(contents.trackRecordCount));
    if (contents.itemRules?.isNotEmpty ?? false) {
      lines.add(l10n.labelIncludesItemRules);
    }
    if (contents.appMeta?.isNotEmpty ?? false) {
      lines.add(l10n.labelIncludesAppSettings);
    }
    return lines.join('\n');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _clockOrUnknown(AppLocalizations l10n, DateTime? time) =>
      time == null
      ? l10n.labelTimeUnknown
      : _formatClock(time.millisecondsSinceEpoch);

  static String _formatClock(int epochMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
