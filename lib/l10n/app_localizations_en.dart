// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabFormation => 'Build';

  @override
  String get emptyFormationHint => 'No entries yet — tap + in the top right';

  @override
  String get tooltipAddEntry => 'Add entry';

  @override
  String get tooltipInputMode => 'Input mode';

  @override
  String get tooltipViewMode => 'View mode';

  @override
  String get tooltipFetchData => 'Fetch data';

  @override
  String get snackQueryTooFrequent =>
      'Too many queries. Please try again later.';

  @override
  String snackUserBanned(String name) {
    return 'User \"$name\" is banned';
  }

  @override
  String snackQuerySuccess(String name, String wave, String seasonWave) {
    return 'Data fetched: $name, wave $wave, season wave $seasonWave';
  }

  @override
  String snackQueryFailed(String reason) {
    return 'Query failed: $reason';
  }

  @override
  String errorSeasonDataNotFound(String name) {
    return 'No season data found for \"$name\"';
  }

  @override
  String get errorQueryTimeout => 'Query timed out. Please try again.';

  @override
  String get totalWave => 'Total Wave';

  @override
  String get seasonWave => 'Season Wave';

  @override
  String get totalGold => 'Total Gold';

  @override
  String get goldPower => 'GP · (CN. Ver)';

  @override
  String get ranking => 'Ranking';

  @override
  String get tooltipEditTotalWave => 'Edit total wave';

  @override
  String get tooltipEditSeasonWave => 'Edit season wave';

  @override
  String get dialogSetTotalWave => 'Set Total Wave';

  @override
  String get dialogSetSeasonWave => 'Set Season Wave';

  @override
  String get metricShare => 'Share';

  @override
  String get metricOneOverRatio => 'Ratio';

  @override
  String get metricRatio => '1 / Ratio';

  @override
  String get unitNameCastle => 'Castle';

  @override
  String get unitNameCastleBow => 'TA';

  @override
  String unitNameGeneric(int id) {
    return 'Unit $id';
  }

  @override
  String get nameLabelCastle => 'Castle name';

  @override
  String get nameLabelCastleBow => 'TA name';

  @override
  String get nameLabelGeneric => 'Name';

  @override
  String get labelLevel => 'Level';

  @override
  String get tooltipActions => 'Actions';

  @override
  String get actionApplied => 'Applied';

  @override
  String get actionNotApplied => 'Not applied';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get itemSourceDragon1 => 'Green';

  @override
  String get itemSourceDragon2 => 'Black';

  @override
  String get itemSourceDragon3 => 'Red';

  @override
  String get itemSourceDragon4 => 'Sin';

  @override
  String get itemSourceDragon5 => 'Legendary';

  @override
  String get itemSourceDragon6 => 'Bone';

  @override
  String get itemSourceDragon7 => 'Ancient';

  @override
  String get webdavAuthFailed => 'Incorrect username or password (HTTP 401)';

  @override
  String get webdavForbidden => 'No access permission (HTTP 403)';

  @override
  String get webdavNoBackupFile => 'There is no backup file in the cloud yet';

  @override
  String get webdavMethodNotAllowed =>
      'The server does not support this operation (HTTP 405)';

  @override
  String webdavServerError(String status) {
    return 'Server error (HTTP $status)';
  }

  @override
  String get webdavUnreachable =>
      'Cannot reach the server. Check your network and the WebDAV address.';

  @override
  String get archiveInvalidJson =>
      'Not a valid backup file (JSON parse failed)';

  @override
  String get archiveInvalid => 'Not a valid backup file';

  @override
  String get archiveMissingVersion =>
      'Not a valid backup file (missing version info)';

  @override
  String get archiveNewerVersion =>
      'This backup was created by a newer version of the app. Update the app before importing.';

  @override
  String get archiveUnsupportedVersion => 'Unsupported backup file version';

  @override
  String get archiveMissingData => 'Not a valid backup file (missing data)';

  @override
  String get backupBusy =>
      'A backup task is already running. Please try again later.';

  @override
  String get backupFailed => 'Backup failed. Please try again later.';

  @override
  String get backupNotConfigured =>
      'Configure the WebDAV server address, username and password first';

  @override
  String get backupNoRestorableData =>
      'The file does not contain any restorable data';

  @override
  String get dataSectionUserData => 'User Data';

  @override
  String get dataSectionUserMeta => 'User Metadata';

  @override
  String get dataSectionAppSettings => 'App Settings';

  @override
  String get highlightRules => 'Highlight Rules';

  @override
  String backupRestorePartialFailure(String sections) {
    return 'Failed to restore: $sections';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get seasonEnded => 'Ended';

  @override
  String get tabFunction => 'Features';

  @override
  String get tabGuild => 'Guild';

  @override
  String get tabTools => 'Tools';

  @override
  String get tabSettings => 'Settings';

  @override
  String get snackUpdateCheckFailed =>
      'Update check failed. Check your connection and try again.';

  @override
  String snackAlreadyLatest(String version) {
    return 'You\'re on the latest version (v$version)';
  }

  @override
  String get dialogUpdateAvailable => 'Update available';

  @override
  String dialogUpdateAvailableBody(
    String hasCurrent,
    String latest,
    String current,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasCurrent, {
      'yes': 'Latest version: $latest (current: v$current)',
      'other': 'Latest version: $latest',
    });
    return '$_temp0';
  }

  @override
  String get labelChangelog => 'Changelog:';

  @override
  String get actionOpenReleasePage => 'Open release page';

  @override
  String snackCannotOpenLink(String url) {
    return 'Couldn\'t open link: $url';
  }

  @override
  String get settingsThirdPartyApi => 'Third-party API';

  @override
  String get labelApiUrl => 'Third-party API URL';

  @override
  String get settingsQueryConcurrency => 'Query concurrency';

  @override
  String get labelConcurrency => 'Concurrency';

  @override
  String get settingsTrackInterval => 'Record interval';

  @override
  String get labelMinutes => 'Minutes';

  @override
  String get settingsUserManagement => 'User management';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsThirdPartyApiSubtitle =>
      'Fetches wave speed data on the player detail page';

  @override
  String get settingsAutoLastOnline => 'Auto-query last online';

  @override
  String get settingsAutoLastOnlineSubtitle =>
      'Queries members\' \"last online\" on the guild detail page';

  @override
  String get settingsGameTrack => 'Game track recording';

  @override
  String get settingsGameTrackSubtitle =>
      'Records changes to your personal data';

  @override
  String get settingsGameTrackMinInterval => 'Minimum track interval';

  @override
  String settingsGameTrackIntervalValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get settingsDataBackup => 'Data backup';

  @override
  String get settingsDataBackupSubtitle =>
      'WebDAV cloud backup · local import/export';

  @override
  String get settingsCheckUpdate => 'Check for updates';

  @override
  String settingsCurrentVersion(String version) {
    return 'Current version v$version';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutAdaptedVersion => 'Supported version';

  @override
  String get aboutGuide => 'User guide';

  @override
  String get aboutThirdPartyApiInfo => 'About the third-party API';

  @override
  String get aboutThirdPartyApiInfoSubtitle =>
      'Check here when a query comes back empty';

  @override
  String get dialogThirdPartyApiBody =>
      'The default third-party API (https://fnxag.eu.org/gcapi) is maintained by the developer.\nOnly some players are within its record range — contact the developer if you need to be added.\nYou can create your own API if you want to use a different one.\n\nNote: this API has no direct connection to this app. Use it at your own discretion.';

  @override
  String get actionGotIt => 'Got it';

  @override
  String get aboutGithubRepo => 'GitHub repository';

  @override
  String get aboutOriginalGithubRepo => 'Original project on GitHub';

  @override
  String get aboutQqGroup => 'QQ group';

  @override
  String get aboutDeveloperEmail => 'Developer email';

  @override
  String get aboutOpenSourceLicenses => 'Open-source licenses';

  @override
  String get aboutLicenseNotice => 'This app is licensed under the GNU GPL-3.0';

  @override
  String get sectionInfo => 'Info';

  @override
  String get sectionLinks => 'Links';

  @override
  String get sectionLicenses => 'Licenses';

  @override
  String get aboutTagline => 'Grow Castle companion tool';

  @override
  String get sectionWebdavBackup => 'WebDAV backup';

  @override
  String get actionBackupNow => 'Back up now';

  @override
  String get backupNowSubtitleReady =>
      'Checks the cloud copy, then uploads and overwrites';

  @override
  String get backupServerNotConfigured => 'Server not configured';

  @override
  String get actionRestoreFromCloud => 'Restore from cloud';

  @override
  String get backupRestoreSubtitle =>
      'Downloads the cloud backup and overwrites local data';

  @override
  String get sectionLocalFiles => 'Local files';

  @override
  String get actionExportToFile => 'Export to file';

  @override
  String get backupExportSubtitle => 'Save all data to a local file';

  @override
  String get actionImportFile => 'Import file';

  @override
  String get backupImportSubtitle => 'Restore data from a local file';

  @override
  String get backupOverwriteHint =>
      'Importing or restoring overwrites all local data — export a backup first.';

  @override
  String get labelServerAddress => 'Server address';

  @override
  String get labelNotSet => 'Not set';

  @override
  String get labelAccount => 'Account';

  @override
  String get labelPassword => 'Password';

  @override
  String get labelWebdavAccount => 'WebDAV account';

  @override
  String get labelWebdavPassword => 'WebDAV password';

  @override
  String get labelServerUrlExample => 'https://dav.example.com/dav/folder';

  @override
  String backupLastSuccess(String time) {
    return 'Last successful backup: $time';
  }

  @override
  String get labelNever => 'Never';

  @override
  String get labelUnknown => 'Unknown';

  @override
  String get labelTimeUnknown => 'Time unknown';

  @override
  String backupLastFailed(String hasTime, String error, String time) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': 'Last backup failed: $error ($time)',
      'other': 'Last backup failed: $error',
    });
    return '$_temp0';
  }

  @override
  String get snackBackupSuccess => 'Backed up to the cloud';

  @override
  String snackBackupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String snackRemoteProbeFailed(String reason) {
    return 'Cloud backup check failed: $reason';
  }

  @override
  String get snackRemoteProbeFailedRetry =>
      'Cloud backup check failed. Please try again later.';

  @override
  String get dialogUploadBackupTitle => 'Upload backup to the cloud';

  @override
  String dialogCloudBackupLine(String hasSize, String time, String size) {
    String _temp0 = intl.Intl.selectLogic(hasSize, {
      'yes': 'Cloud backup: $time, $size KB',
      'other': 'Cloud backup: $time',
    });
    return '$_temp0';
  }

  @override
  String get dialogCloudBackupNoFile =>
      'Cloud backup: no file yet (a new one will be created)';

  @override
  String dialogLastLocalBackupLine(String time) {
    return 'Last successful local backup: $time';
  }

  @override
  String get actionRestoreRemote => 'Restore from cloud';

  @override
  String get actionUpload => 'Upload';

  @override
  String get actionOverwriteAnyway => 'Overwrite anyway';

  @override
  String get actionOverwriteUpload => 'Overwrite and upload';

  @override
  String get dialogWarningRemoteNewer =>
      'The cloud backup is newer than your last successful local backup and may have come from another device; once overwritten, the cloud copy can\'t be recovered.';

  @override
  String get dialogWarningRemoteTimeUnknown =>
      'Couldn\'t read the cloud backup\'s timestamp; once overwritten, the cloud copy can\'t be recovered.';

  @override
  String get dialogWarningLocalNoRecord =>
      'There\'s no record of a successful local backup, so the cloud copy\'s origin can\'t be confirmed; once overwritten, it can\'t be recovered.';

  @override
  String dialogRestoreCloudSource(
    String hasTime,
    String time,
    String hasSize,
    String size,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': 'Cloud backup ($time)',
      'other': 'Cloud backup',
    });
    String _temp1 = intl.Intl.selectLogic(hasSize, {
      'yes': ', $size KB',
      'other': '',
    });
    return '$_temp0$_temp1';
  }

  @override
  String snackFetchRemoteFailed(String reason) {
    return 'Failed to fetch the cloud backup: $reason';
  }

  @override
  String snackInvalidCloudFile(String reason) {
    return 'Invalid cloud file: $reason';
  }

  @override
  String dialogWarningRestoreOlder(String hasTime, String time) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes':
          'The cloud backup is older than your last successful local backup ($time); restoring will roll your data back.',
      'other': 'The cloud backup is older than your last successful local backup; restoring will roll your data back.',
    });
    return '$_temp0';
  }

  @override
  String get dialogWarningRestoreNewer =>
      'The cloud backup is newer than your last successful local backup and may have come from another device.';

  @override
  String get dialogWarningRestoreUnknown =>
      'Can\'t tell whether the cloud backup is newer or older than your local record — confirm where it came from before restoring.';

  @override
  String get snackExportFailed => 'Export failed. Please try again later.';

  @override
  String get dialogTitleExportBackup => 'Export data backup';

  @override
  String get snackExportSuccess => 'Exported to file';

  @override
  String get dialogTitlePickBackupFile => 'Choose a backup file';

  @override
  String snackInvalidFile(String reason) {
    return 'Invalid file: $reason';
  }

  @override
  String get snackReadFileFailed =>
      'Couldn\'t read the file. Make sure it\'s a backup file exported from this app.';

  @override
  String dialogPickLocalFileSource(String name) {
    return 'Local file: $name';
  }

  @override
  String dialogRestoreSource(String source) {
    return 'Source: $source';
  }

  @override
  String get actionOverwriteRestore => 'Overwrite and restore';

  @override
  String get snackRestoreSuccess => 'Local data restored';

  @override
  String snackRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String labelBackupTime(String time) {
    return 'Backup time: $time';
  }

  @override
  String labelUserCount(int count) {
    return 'Users: $count';
  }

  @override
  String labelTrackRecordCount(int count) {
    return 'Game track records: $count';
  }

  @override
  String get labelIncludesItemRules => 'Includes: line highlight rules';

  @override
  String get labelIncludesAppSettings => 'Includes: app settings';

  @override
  String get snackDefaultUserNoRename => 'The default user can\'t be renamed';

  @override
  String get snackDefaultUserNoDelete => 'The default user can\'t be deleted';

  @override
  String get tooltipDetails => 'Details';

  @override
  String get actionAddUser => 'Add user';

  @override
  String errorUserDataNotFound(String name) {
    return 'No data found for user \"$name\"';
  }

  @override
  String get dialogDeleteUser => 'Delete user';

  @override
  String dialogDeleteUserConfirm(String name) {
    return 'Delete user \"$name\"?';
  }

  @override
  String get labelUsername => 'Username';

  @override
  String get labelGuildOptional => 'Guild (optional)';

  @override
  String get actionAdd => 'Add';

  @override
  String get dialogEditUser => 'Edit user';

  @override
  String get tooltipShowPassword => 'Show';

  @override
  String get tooltipHidePassword => 'Hide';

  @override
  String get labelUsernameHint => '0-9, a-z, A-Z, -, _, space';

  @override
  String get waveStatus => 'Wave Status';

  @override
  String get wavePushIncomeCalc => 'Waving Income';

  @override
  String get tabIncome => 'Income';

  @override
  String get noRecord => 'No record';

  @override
  String timeSecondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds ago',
      one: '1 second ago',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String timeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get labelGameSpeed => 'Game speed';

  @override
  String get optionSpeed2x => '2x';

  @override
  String get optionSpeed2xAds10 => '2x + 10 ads';

  @override
  String get optionSpeed3x => '3x';

  @override
  String get optionChronoWhite => 'White (+10%)';

  @override
  String get optionChronoYellow => 'Yellow (+14%)';

  @override
  String get optionChronoBlue => 'Blue (+20%)';

  @override
  String get optionEquipped => 'Equipped';

  @override
  String get optionNotEquipped => 'Not equipped';

  @override
  String get optionNone => 'None';

  @override
  String get optionAutoBattleGoldBreak => 'GAB / FAB';

  @override
  String get optionAutoBattleTime => 'TAB';

  @override
  String get dialogWaveStatusDisclaimer => '数据仅供参考，实际游戏中可能会有较大偏差。';

  @override
  String get actionClose => 'Close';

  @override
  String get labelChronoType => 'Chrono type';

  @override
  String get labelHorn10 => '10% Horn';

  @override
  String get labelHorn30 => '30% Horn';

  @override
  String get labelDevilHornSkip => 'Devil horn wave skip';

  @override
  String get labelAutoBattleType => 'Auto battle type';

  @override
  String get infoAutoBattleTab =>
      'The TAB option assumes BAND SKILL is released and both the Orc Horn and the Band(F) are equipped.';

  @override
  String get snackTrackDeleted => 'Track record deleted';

  @override
  String get actionUndo => 'Undo';

  @override
  String get dialogWarning => 'Warning';

  @override
  String get dialogGameTrackOff =>
      'Game track recording is off. New track data cannot be recorded.';

  @override
  String get tooltipViewTrackChart => 'View track chart';

  @override
  String get tooltipSortOldestFirst => 'Sort oldest first';

  @override
  String get tooltipSortNewestFirst => 'Sort newest first';

  @override
  String get emptyTrackDefaultUser =>
      'Default user: track recording is unavailable';

  @override
  String get emptyTrackDisabled =>
      'Track recording is off. Turn on \"Game track recording\" in Settings.';

  @override
  String get emptyGameTrack => 'No track records yet';

  @override
  String get tooltipDeleteRecord => 'Delete record';

  @override
  String labelTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String get gameTrackChart => 'Track chart';

  @override
  String labelChartRange(String start, String end) {
    return 'Start $start\nEnd $end';
  }

  @override
  String get emptyChartNeedTwoRecords =>
      'At least two track records are needed';

  @override
  String labelChartDownsampled(int total, int shown) {
    return 'Downsampled: $total records, displaying $shown';
  }

  @override
  String get totalEconomy => 'Total economy';

  @override
  String get metricIndex => 'Index';

  @override
  String get dialogConfirmApplyIncome => 'Apply this income?';

  @override
  String dialogApplyGabBonusContent(String from, String to) {
    return 'GAB bonus: $from% -> $to%?';
  }

  @override
  String snackAppliedGabBonus(String value) {
    return 'GAB average bonus set to $value%';
  }

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionReset => 'Reset';

  @override
  String get dialogResetIncomeSamples =>
      'Clear all income samples for the current user?';

  @override
  String get emptyIncomeSamples => 'No income samples yet';

  @override
  String get labelGabCost => 'GAB cost';

  @override
  String get labelAverageIncome => 'Average income';

  @override
  String get labelPercent => 'Percentage';

  @override
  String get actionFillIn => 'Apply';

  @override
  String get dialogInputWaveIncome => 'Enter per-wave gold income';

  @override
  String get labelWaveGoldIncome => 'Gold income per wave';

  @override
  String get tooltipInfo => 'Info';

  @override
  String get dialogIncomeNotice =>
      'Fill in \"Wave Skip lineus\" first, otherwise the result will be inaccurate.\n\nThe result here is daily income.';

  @override
  String get tabIncomeColony => 'Colony';

  @override
  String get tabIncomeWave => 'Waving';

  @override
  String get tabIncomeOther => 'Other';

  @override
  String get labelColonyLevel => 'Colony level';

  @override
  String get labelExtraColonyC => 'Extra colony C';

  @override
  String get labelExtraColonyG => 'Extra colony G';

  @override
  String get labelWheel => 'Iron Wheel';

  @override
  String get labelWhip => 'Whip';

  @override
  String get labelGabAverageBonus => 'GAB average bonus';

  @override
  String get labelDailyGabTime => 'Daily GAB time';

  @override
  String get labelDailyTabTime => 'Daily TAB time';

  @override
  String get labelSeasonColony => 'Season colony';

  @override
  String get labelGoldenTree => 'Golden tree';

  @override
  String get toolDragonSimulator => 'Dragon Farm Simulator';

  @override
  String get toolItemComparer => 'Item Comparison';

  @override
  String get toolBestLineCalc => 'Best line Combo';

  @override
  String get rankingKindPlayer => 'Player Leaderboard';

  @override
  String get rankingKindGuild => 'Guild Leaderboard';

  @override
  String get rankingKindHell => 'Hell Mode Leaderboard';

  @override
  String get emptyRankingData => 'No leaderboard data';

  @override
  String get emptyData => 'No data';

  @override
  String labelRankingTrend(String kind) {
    return '$kind Trend';
  }

  @override
  String labelTopCount(int count) {
    return 'Top $count';
  }

  @override
  String labelRankSummary(int count, String max, String min) {
    return 'Top $count · Max $max · Min $min';
  }

  @override
  String snackRefreshFailed(String reason) {
    return 'Refresh failed: $reason';
  }

  @override
  String dialogRankMilestones(String kind) {
    return '$kind Ranks';
  }

  @override
  String get tooltipViewScoreTrend => 'View score trend';

  @override
  String get tooltipViewMilestoneRanks => 'View milestone ranks';

  @override
  String get hintSelectPlayerDetail =>
      'Select a player on the left to view details';

  @override
  String get actionRetry => 'Retry';

  @override
  String get snackNeedEnabledRule =>
      'Enable at least one rule in \"Highlight Rules\" first';

  @override
  String rollToHitHit(String count) {
    return 'Hit! Rolled $count times';
  }

  @override
  String rollToHitStopped(String count) {
    return 'Stopped manually. Rolled $count times';
  }

  @override
  String get labelItemSource => 'Item Source';

  @override
  String get labelHighestTierBonus => 'Top-tier drop rate bonus';

  @override
  String get labelRollBatchSize => 'Roll count per batch';

  @override
  String get actionRollOnce => 'Roll Once';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionRollToHit => 'Roll Until Hit';

  @override
  String rollToHitRunning(String count) {
    return 'Rolling until hit: $count rolls so far…';
  }

  @override
  String get unnamedRule => 'Unnamed rule';

  @override
  String get itemTypeBow => 'Bow';

  @override
  String get itemTypeSword => 'Sword';

  @override
  String get itemTypeStaff => 'Staff';

  @override
  String get itemTypeHammer => 'Hammer';

  @override
  String get itemTypeRing => 'Ring';

  @override
  String get itemTypeNecklace => 'Necklace';

  @override
  String get itemTypeBracelet => 'Bracelet';

  @override
  String get itemTypeEarrings => 'Earrings';

  @override
  String get actionAddRule => 'Add Rule';

  @override
  String get emptyItemRuleHint => 'No rules yet — tap + in the bottom right';

  @override
  String get tooltipPinToTop => 'Pinned to top on match';

  @override
  String get actionEdit => 'Edit';

  @override
  String labelItemTypes(String types) {
    return 'Item types: $types';
  }

  @override
  String get errorWhiteLinesWithRed =>
      'A red line is already selected — at most 2 white lines';

  @override
  String get errorWhiteLinesMax => 'At most 3 white lines';

  @override
  String get errorRedWithThreeWhite =>
      'Already 3 white lines — a red line cannot be selected';

  @override
  String get errorNoLineSelected => 'Select at least one line';

  @override
  String get errorValueNotNumber => 'Enter a number or leave it blank';

  @override
  String get errorMinGreaterThanMax =>
      'The lower bound (greater than) must be below the upper bound (less than)';

  @override
  String errorMinOutOfRange(String line, String min, String max) {
    return '\"$line\" lower bound is outside the roll range ($min ~ $max)';
  }

  @override
  String errorMaxOutOfRange(String line, String min, String max) {
    return '\"$line\" upper bound is outside the roll range ($min ~ $max)';
  }

  @override
  String get titleEditRule => 'Edit Rule';

  @override
  String get labelHintText => 'Hint text';

  @override
  String get hintRuleHintExample => 'e.g. Red + white boost (optional)';

  @override
  String get labelPinToTop => 'Pin to top when matched';

  @override
  String get labelSelectItemTypes =>
      'Restrict item types (none selected = any)';

  @override
  String get helpRuleForm =>
      'Tip: at most 1 red and 1 gold line each; a red line cannot be picked once white lines total 3.\nValue ranges are checked against the line\'s raw value (before boosting) — leave blank for no limit.\n\nThe lower bound must be below the upper bound, and entered values must stay within the line\'s allowed range.';

  @override
  String labelLineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String get lineColorWhite => 'White line';

  @override
  String get lineColorRed => 'Red line';

  @override
  String get lineColorGold => 'Gold line';

  @override
  String get lineColorPurple => 'Purple line';

  @override
  String labelItemLines(int index) {
    return 'Item $index lines';
  }

  @override
  String get dialogItemCompareHelpIntro =>
      'This tool compares the expected value of two items.\n\n';

  @override
  String get dialogItemCompareHelpStepsTitle => 'Steps:\n';

  @override
  String get dialogItemCompareHelpStep1 =>
      '1. Identify the item / orb / treasure slot to compare, unequip that item, then fill in the \"No-Item Panel\" fields from the resulting panel;\n';

  @override
  String get dialogItemCompareHelpStep2 =>
      '2. Enter the white lines of both items under \"Item 1 / Item 2\",';

  @override
  String get dialogItemCompareHelpStep2Note =>
      'Mind the line type: all elemental damage goes under \"Element Damage\" — enter the matching elemental damage line for your unit;\n';

  @override
  String get dialogItemCompareHelpStep3 =>
      '3. Result: three DPS sets update live, with a verdict.\n\n\n';

  @override
  String get dialogItemCompareHelpNormalUnit => 'Basic-attack units:';

  @override
  String get dialogItemCompareHelpNormalUnitDesc =>
      'Fill in Attacks Per Second and Increased Speed; the Attack Speed % line is counted.\n';

  @override
  String get dialogItemCompareHelpSkillUnit => 'Skill units:';

  @override
  String get dialogItemCompareHelpSkillUnitDesc =>
      'Leave both blank; the Attack Speed % line is ignored.';

  @override
  String get dialogItemCompareHelpNoteLabel => '\n\nNote: ';

  @override
  String get dialogItemCompareHelpNoteDesc =>
      'Orb and treasure lines can also be used — just mind the line type.';

  @override
  String get dialogResetConfirm => 'Clear all inputs?';

  @override
  String get labelNoItemPanel => 'No-Item Panel';

  @override
  String get actionAddLine => 'Add line';

  @override
  String get hintSelectLineType => 'Select line type';

  @override
  String get hintValue => 'Value';

  @override
  String get tooltipDeleteLine => 'Delete line';

  @override
  String get labelNoCrit => 'No crit';

  @override
  String get labelWithCrit => 'With crit';

  @override
  String get labelNoItem => 'No item';

  @override
  String labelItemNumber(int index) {
    return 'Item $index';
  }

  @override
  String labelCompareGainSummary(String gain1, String gain2) {
    return 'Item 1 vs no item $gain1 · Item 2 vs no item $gain2';
  }

  @override
  String get compareVerdictPending => 'Fill in the data to compare';

  @override
  String compareVerdictItem1(String gap) {
    return 'Item 1 is better$gap';
  }

  @override
  String compareGapItem2(String gain) {
    return ', DPS is $gain higher than Item 2';
  }

  @override
  String compareVerdictItem2(String gap) {
    return 'Item 2 is better$gap';
  }

  @override
  String compareGapItem1(String gain) {
    return ', DPS is $gain higher than Item 1';
  }

  @override
  String get compareVerdictTie => 'Both items have the same DPS';

  @override
  String get labelNoDamageLines => '(No damage lines)';

  @override
  String get dialogBestLineHelpAvgDmg =>
      'Avg. Dmg and Damage in the list below both mean the average of Damage and Elemental Damage.';

  @override
  String get labelPanelWithoutItem => 'Panel without item';

  @override
  String labelLineSlot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '$count line',
    );
    return '$_temp0';
  }

  @override
  String labelComboCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count combos',
      one: '$count combo',
    );
    return '$_temp0';
  }

  @override
  String get gameTrack => 'Game Track';

  @override
  String snackSyncFailed(String reason) {
    return 'Sync failed: $reason';
  }

  @override
  String errorGuildNotFound(String name) {
    return 'No info found for guild \"$name\"';
  }

  @override
  String get emptyGuildDefaultUserHint =>
      'You are using the default user, which is only for trying out basic features.\nGo to \"User Management\" under \"Settings\" to create your own account and fill in your guild name.';

  @override
  String get emptyGuildHint =>
      'No guild set for the current user. Fill in a guild name in \"User Management\" first.';

  @override
  String get emptyGuildMembers => 'This guild has no members yet';

  @override
  String get actionGoToUserManagement => 'Go to user management';

  @override
  String get emptySelectMemberHint =>
      'Select a member on the left to view player details';

  @override
  String guildMemberCountAndScore(int count, String score) {
    return '$count members · $score';
  }

  @override
  String get tooltipCloseDetail => 'Close details';

  @override
  String errorPlayerBanned(String name) {
    return 'Player \"$name\" is banned';
  }

  @override
  String get labelWphHistory => 'Waves per hour (third-party API)';

  @override
  String labelSeason(String season) {
    return 'Season $season';
  }

  @override
  String get endlessScore => 'Endless score';

  @override
  String get lastOnline => 'Last online';

  @override
  String unitEnabledCount(int enabled, int total) {
    return '$enabled/$total enabled';
  }

  @override
  String get metricGoldShare => 'Gold share';

  @override
  String get metricUnitPerWave => 'Unit / Wave';

  @override
  String get metricWavePerUnit => 'Wave / Unit';

  @override
  String get seasonProgress => 'Season progress';

  @override
  String get labelStart => 'Start';

  @override
  String get labelEnd => 'End';

  @override
  String get labelRemaining => 'Remaining';

  @override
  String get incomeTotal => 'Total income';
}
