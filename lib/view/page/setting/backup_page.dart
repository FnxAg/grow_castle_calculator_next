import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';
import 'package:grow_castle_calculator_next/view/responsive/content_frame.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('数据备份')),
      body: ContentFrame(child: ListView(
        children: [
          SectionHeader('WebDAV 备份'),
          // 服务器配置行（手动备份与云端恢复共用）
          _buildConfigRows(scheme),
          // 手动操作与状态
          ValueListenableBuilder<bool>(
            valueListenable: _service.busyNotifier,
            builder: (context, busy, _) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('立即备份'),
                  subtitle: Text(
                    _config.isConfigured ? '检查云端新旧后上传覆盖' : '未配置服务器',
                  ),
                  trailing: busy || _remoteBusy ? _spinner() : null,
                  enabled: !busy && !_remoteBusy,
                  onTap: _onManualBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('从云端恢复'),
                  subtitle: const Text('下载云端备份并覆盖本机数据'),
                  trailing: _remoteBusy ? _spinner() : null,
                  enabled: !busy && !_remoteBusy,
                  onTap: _onRestoreFromCloud,
                ),
              ],
            ),
          ),
          _buildStatusArea(),
          SectionHeader('本地文件'),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('导出到文件'),
            subtitle: const Text('把全部数据保存为本地文件'),
            onTap: _onExportFile,
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导入文件'),
            subtitle: const Text('从本地文件恢复数据'),
            onTap: _onImportFile,
          ),
          SectionHeader('说明'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Text(
              '导入或恢复会覆盖本机全部数据，建议先导出备份。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      )),
    );
  }

  static Widget _spinner() => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.0),
      );

  /// 服务器地址/账号/密码配置行
  Widget _buildConfigRows(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: _config.urlNotifier,
          builder: (context, url, _) => ListTile(
            leading: const Icon(Icons.link),
            title: const Text('服务器地址'),
            subtitle: Text(url.isEmpty ? '未设置' : url),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUrlDialog(),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _config.usernameNotifier,
          builder: (context, username, _) => ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('账号'),
            subtitle: Text(username.isEmpty ? '未设置' : username),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUsernameDialog(),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _config.passwordNotifier,
          builder: (context, password, _) => ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('密码'),
            subtitle: Text(password.isEmpty ? '未设置' : '••••••'),
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
                successMs == null
                    ? '上次成功备份：从未'
                    : '上次成功备份：${_formatClock(successMs)}',
                style: style?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (error != null)
                Text(
                  '上次备份失败：$error'
                  '${errorAt == null ? '' : '（${_formatClock(errorAt)}）'}',
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
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => SettingEditDialog(
        title: '服务器地址',
        initialValue: _config.urlNotifier.value,
        decoration: const InputDecoration(
          labelText: 'https://dav.example.com/dav/目录',
        ),
        onSubmit: _config.setUrl,
      ),
    );
  }

  void _showUsernameDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => SettingEditDialog(
        title: '账号',
        initialValue: _config.usernameNotifier.value,
        decoration: const InputDecoration(labelText: 'WebDAV 账号'),
        onSubmit: _config.setUsername,
      ),
    );
  }

  void _showPasswordDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => SettingEditDialog(
        title: '密码',
        initialValue: _config.passwordNotifier.value,
        decoration: const InputDecoration(labelText: 'WebDAV 密码'),
        obscureText: true,
        showVisibilityToggle: true,
        onSubmit: _config.setPassword,
      ),
    );
  }

  // ── 手动备份：探测 → 确认 → 上传 ───────────────────────────────

  Future<void> _onManualBackup() async {
    // 未配置守卫必须在探测之前：否则会发出真实网络请求
    if (!_config.isConfigured) {
      _snack('请先配置 WebDAV 服务器地址、账号与密码');
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
    _snack(error == null ? '已备份到云端' : '备份失败：$error');
  }

  /// 探测云端备份元信息；失败只提示并返回 null（不写失败留痕：
  /// 备份根本没发起，记进状态区会谎报"上次备份失败"）
  Future<WebDavFileInfo?> _probeRemoteBackup() async {
    setState(() => _remoteBusy = true);
    try {
      return await _service.fetchRemoteInfo();
    } on WebDavException catch (e) {
      if (mounted) _snack('检测云端备份失败：${e.message}');
      return null;
    } catch (_) {
      if (mounted) _snack('检测云端备份失败，请稍后重试');
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
    final lastSuccessMs = _config.lastSuccessAtNotifier.value;
    final warn = relation == RemoteBackupRelation.remoteNewer ||
        relation == RemoteBackupRelation.remoteUnknown;
    final remoteLine = info.exists
        ? '云端备份：${_clockOrUnknown(info.lastModified)}'
            '${info.contentLength == null ? '' : '，${info.contentLength! ~/ 1024} KB'}'
        : '云端备份：还没有备份文件（将新建一份）';
    final localLine = lastSuccessMs == null
        ? '本机上次成功备份：从未'
        : '本机上次成功备份：${_formatClock(lastSuccessMs)}';
    return showDialog<_OverwriteDecision>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('上传备份到云端'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(remoteLine),
            Text(localLine),
            if (warn) ...[
              const SizedBox(height: 12),
              Text(
                _overwriteWarning(info, relation, lastSuccessMs),
                style: TextStyle(color: scheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          if (relation == RemoteBackupRelation.remoteNewer)
            TextButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(_OverwriteDecision.restoreFromCloud),
              child: const Text('恢复云端'),
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
                ? '上传'
                : warn
                    ? '仍要覆盖'
                    : '覆盖上传'),
          ),
        ],
      ),
    );
  }

  /// 警告文案：remoteNewer 一种成因；remoteUnknown 分"取不到时间"与
  /// "本机无成功记录"两种，措辞分开便于用户判断该不该继续
  static String _overwriteWarning(
    WebDavFileInfo info,
    RemoteBackupRelation relation,
    int? lastSuccessMs,
  ) {
    if (relation == RemoteBackupRelation.remoteNewer) {
      return '云端备份比本机上次成功备份更新，可能来自其他设备；'
          '覆盖后云端那份将无法找回。';
    }
    if (info.lastModified == null) {
      return '无法获取云端备份时间；覆盖后云端那份将无法找回。';
    }
    if (lastSuccessMs == null) {
      return '本机没有成功备份记录，无法确认云端那份的来源；覆盖后无法找回。';
    }
    return '';
  }

  // ── 云端恢复 ───────────────────────────────────────────────────

  Future<void> _onRestoreFromCloud() async {
    if (!_config.isConfigured) {
      _snack('请先配置 WebDAV 服务器地址、账号与密码');
      return;
    }
    if (_remoteBusy || _service.busyNotifier.value) return;
    setState(() => _remoteBusy = true);
    RemoteBackupPreview? preview;
    try {
      preview = await _service.fetchRemotePreview();
    } on WebDavException catch (e) {
      if (mounted) _snack('获取云端备份失败：${e.message}');
    } on DataArchiveException catch (e) {
      if (mounted) _snack('云端文件无效：${e.message}');
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
    if (preview == null || !mounted) {
      if (preview == null && mounted) {
        _snack('云端还没有备份文件');
      }
      return;
    }
    final fileInfo = preview.fileInfo;
    final modified = fileInfo.lastModified;
    final source = [
      modified == null ? '云端备份' : '云端备份（${_formatClock(modified.millisecondsSinceEpoch)}）',
      if (fileInfo.contentLength != null) '${fileInfo.contentLength! ~/ 1024} KB',
    ].join('，');
    await _confirmAndApply(
      title: '从云端恢复',
      source: source,
      contents: preview.contents,
      warning: _restoreWarning(fileInfo),
    );
  }

  /// 恢复方向的提示：危险方与上传相反——云端较旧意味着会退回旧数据。
  /// 复用预览已带回的 fileInfo，不再多发请求
  _ConfirmWarning? _restoreWarning(WebDavFileInfo info) {
    final relation = BackupService.compareRemoteBackup(
      info: info,
      lastSuccessAtMs: _config.lastSuccessAtNotifier.value,
    );
    final localMs = _config.lastSuccessAtNotifier.value;
    switch (relation) {
      case RemoteBackupRelation.remoteOlder:
        return (
          text: '云端备份早于本机上次成功备份'
              '${localMs == null ? '' : '（${_formatClock(localMs)}）'}，'
              '恢复会退回较旧的数据。',
          isError: true,
        );
      case RemoteBackupRelation.remoteNewer:
        return (
          text: '云端备份比本机上次成功备份更新，可能来自其他设备。',
          isError: false,
        );
      case RemoteBackupRelation.remoteUnknown:
        return (
          text: '无法判断云端备份与本机记录的新旧，恢复前请确认来源。',
          isError: false,
        );
      case RemoteBackupRelation.noRemote:
        // 有预览必然存在云端文件，此分支不会走到
        return null;
    }
  }

  // ── 本地导出/导入 ──────────────────────────────────────────────

  Future<void> _onExportFile() async {
    final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(
        utf8.encode(await _service.buildArchiveText()),
      );
    } catch (e) {
      if (mounted) _snack('导出失败，请稍后重试');
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
      dialogTitle: '导出数据备份',
    );
    if (!mounted) return;
    // null = 用户取消
    if (uri != null) {
      _snack('已导出到文件');
    }
  }

  Future<void> _onImportFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: '选择备份文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null || !mounted) return; // 用户取消

    final ArchiveContents contents;
    try {
      final text = utf8.decode(await file.readAsBytes());
      contents = DataArchive.decode(text);
    } on DataArchiveException catch (e) {
      if (mounted) _snack('文件无效：${e.message}');
      return;
    } catch (e) {
      if (mounted) _snack('读取文件失败，请确认是导出的备份文件');
      return;
    }
    if (!mounted) return;
    await _confirmAndApply(
      title: '导入文件',
      source: '本机文件：${file.name}',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '来源：$source\n\n'
              '${_describeArchive(contents)}\n\n'
              '导入或恢复会覆盖本机全部数据，建议先导出备份。',
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
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('覆盖恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await _service.applyArchive(contents);
    if (!mounted) return;
    _snack(error == null ? '已恢复本地数据' : '恢复失败：$error');
  }

  /// 预览文案：归档导出时间与内容摘要
  String _describeArchive(ArchiveContents contents) {
    final lines = <String>[];
    final exported = contents.exportedAt;
    lines.add(
      exported == null
          ? '备份时间：未知'
          : '备份时间：${_formatClock(exported.millisecondsSinceEpoch)}',
    );
    lines.add('用户数：${contents.userCount}');
    lines.add('游戏轨迹记录：${contents.trackRecordCount} 条');
    if (contents.itemRules?.isNotEmpty ?? false) {
      lines.add('包含：词条高亮规则');
    }
    if (contents.appMeta?.isNotEmpty ?? false) {
      lines.add('包含：应用设置');
    }
    return lines.join('\n');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _clockOrUnknown(DateTime? time) => time == null
      ? '时间未知'
      : _formatClock(time.millisecondsSinceEpoch);

  static String _formatClock(int epochMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
