import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_client.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/webdav_config.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/setting_edit_dialog.dart';

/// 数据备份页：WebDAV 配置与手动备份/云端恢复 + 本地导出/导入。
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupService _service = BackupService.instance;
  late final WebDavConfigStore _config;

  /// 从云端拉取预览/恢复中（手动备份的进行中状态由 service.busyNotifier 驱动）
  bool _cloudBusy = false;

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
      body: ListView(
        children: [
          SectionHeader('WebDAV 备份'),
          // 自动备份开关
          ValueListenableBuilder<bool>(
            valueListenable: _config.autoEnabledNotifier,
            builder: (context, enabled, _) => ListTile(
              leading: const Icon(Icons.autorenew),
              title: const Text('自动备份'),
              subtitle: const Text('数据变化后自动上传到云端，打开应用超过间隔补传'),
              trailing: Switch(
                value: enabled,
                onChanged: _config.setAutoEnabled,
              ),
              onTap: () => _config.setAutoEnabled(!enabled),
            ),
          ),
          // 服务器配置行（自动备份关闭时同样需要，手动备份入口共用）
          _buildConfigRows(scheme),
          ValueListenableBuilder<int>(
            valueListenable: _config.intervalHoursNotifier,
            builder: (context, hours, _) => ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('自动备份间隔'),
              subtitle: Text('距上次成功备份超过 $hours 小时时补传'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showIntervalDialog(hours),
            ),
          ),
          // 手动操作与状态
          ValueListenableBuilder<bool>(
            valueListenable: _service.busyNotifier,
            builder: (context, busy, _) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('立即备份'),
                  subtitle: Text(
                    _config.isConfigured ? '上传到 WebDAV 服务器' : '未配置服务器',
                  ),
                  trailing: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : null,
                  enabled: !busy,
                  onTap: _onManualBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('从云端恢复'),
                  subtitle: const Text('下载云端备份并覆盖本机数据'),
                  trailing: _cloudBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : null,
                  enabled: !busy && !_cloudBusy,
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
              '导入或恢复会覆盖本机全部数据，建议先导出备份。\n'
              'WebDAV 账号密码明文保存在本机，不会包含在导出文件中。',
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

  /// 服务器地址/账号/密码配置行（可折叠在自动开关下的次级展示）
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

  /// 备份状态区：上次成功/失败时间（成功/失败留痕供自动备份静默时查看）
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

  void _showIntervalDialog(int current) {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => SettingEditDialog(
        title: '自动备份间隔',
        initialValue: '$current',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: '小时（1-720）',
          helperText: '打开应用距上次成功备份超过该时长时自动补传',
        ),
        onSubmit: (text) {
          final value = int.tryParse(text);
          if (value != null) {
            _config.setIntervalHours(value);
          }
        },
      ),
    );
  }

  // ── 手动备份 / 云端恢复 / 本地导入导出 ─────────────────────────

  Future<void> _onManualBackup() async {
    if (!_config.isConfigured) {
      _snack('请先配置 WebDAV 服务器地址、账号与密码');
      return;
    }
    final error = await _service.manualBackup();
    if (!mounted) return;
    _snack(error == null ? '已备份到云端' : '备份失败：$error');
  }

  Future<void> _onRestoreFromCloud() async {
    if (!_config.isConfigured) {
      _snack('请先配置 WebDAV 服务器地址、账号与密码');
      return;
    }
    setState(() => _cloudBusy = true);
    RemoteBackupPreview? preview;
    try {
      preview = await _service.fetchRemotePreview();
    } on WebDavException catch (e) {
      if (mounted) _snack('获取云端备份失败：${e.message}');
    } on DataArchiveException catch (e) {
      if (mounted) _snack('云端文件无效：${e.message}');
    } finally {
      if (mounted) setState(() => _cloudBusy = false);
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
    );
  }

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
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          '来源：$source\n\n'
          '${_describeArchive(contents)}\n\n'
          '导入或恢复会覆盖本机全部数据，建议先导出备份。',
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

  static String _formatClock(int epochMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
