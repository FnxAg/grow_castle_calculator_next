/// 服务层错误 → 当前语言文案。
///
/// 服务层（api / backup_service / data_archive / webdav_backup_client）只产出
/// 语言中立的错误码，文案一律在这里翻译 —— 这样持久化下来的失败原因也不会
/// 被钉死在写入时的语言上。
library;

import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/service/data_archive.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';

/// WebDAV 状态码 -> 文案
String webdavErrorText(AppLocalizations l10n, int statusCode) =>
    switch (statusCode) {
      401 => l10n.webdavAuthFailed,
      403 => l10n.webdavForbidden,
      404 => l10n.webdavNoBackupFile,
      405 => l10n.webdavMethodNotAllowed,
      -1 => l10n.webdavUnreachable,
      _ => l10n.webdavServerError('$statusCode'),
    };

String webdavExceptionText(AppLocalizations l10n, WebDavException e) =>
    webdavErrorText(l10n, e.statusCode);

/// 归档不合法 -> 文案
String archiveErrorText(AppLocalizations l10n, ArchiveError error) =>
    switch (error) {
      ArchiveError.invalidJson => l10n.archiveInvalidJson,
      ArchiveError.invalid => l10n.archiveInvalid,
      ArchiveError.missingVersion => l10n.archiveMissingVersion,
      ArchiveError.newerVersion => l10n.archiveNewerVersion,
      ArchiveError.unsupportedVersion => l10n.archiveUnsupportedVersion,
      ArchiveError.missingData => l10n.archiveMissingData,
    };

String archiveExceptionText(AppLocalizations l10n, DataArchiveException e) =>
    archiveErrorText(l10n, e.error);

String _dataSectionText(AppLocalizations l10n, DataSection section) =>
    switch (section) {
      DataSection.userData => l10n.dataSectionUserData,
      DataSection.userMeta => l10n.dataSectionUserMeta,
      DataSection.appSettings => l10n.dataSectionAppSettings,
      DataSection.itemRules => l10n.highlightRules,
      DataSection.gameTrack => l10n.gameTrack,
    };

/// 备份/恢复失败 -> 文案
String backupFailureText(AppLocalizations l10n, BackupFailure failure) =>
    switch (failure) {
      BackupBusyFailure() => l10n.backupBusy,
      BackupNotConfiguredFailure() => l10n.backupNotConfigured,
      BackupGenericFailure() => l10n.backupFailed,
      BackupNoDataFailure() => l10n.backupNoRestorableData,
      BackupWebDavFailure(:final statusCode) => webdavErrorText(l10n, statusCode),
      BackupArchiveFailure(:final error) => archiveErrorText(l10n, error),
      BackupPartialRestoreFailure(:final sections) =>
        l10n.backupRestorePartialFailure(
          sections.map((s) => _dataSectionText(l10n, s)).join(l10n.listSeparator),
        ),
    };

/// 持久化下来的失败 id（[BackupFailure.id]）-> 文案
String storedBackupFailureText(AppLocalizations l10n, String id) {
  if (id.startsWith('webdav:')) {
    final status = int.tryParse(id.substring('webdav:'.length));
    if (status != null) return webdavErrorText(l10n, status);
  }
  if (id.startsWith('archive:')) {
    final name = id.substring('archive:'.length);
    for (final error in ArchiveError.values) {
      if (error.name == name) return archiveErrorText(l10n, error);
    }
  }
  if (id.startsWith('partial:')) {
    final sections = <DataSection>[];
    for (final name in id.substring('partial:'.length).split(',')) {
      for (final section in DataSection.values) {
        if (section.name == name) sections.add(section);
      }
    }
    if (sections.isNotEmpty) {
      return l10n.backupRestorePartialFailure(
        sections.map((s) => _dataSectionText(l10n, s)).join(l10n.listSeparator),
      );
    }
  }
  return switch (id) {
    'busy' => l10n.backupBusy,
    'notConfigured' => l10n.backupNotConfigured,
    'failed' => l10n.backupFailed,
    'noData' => l10n.backupNoRestorableData,
    _ => id,
  };
}
