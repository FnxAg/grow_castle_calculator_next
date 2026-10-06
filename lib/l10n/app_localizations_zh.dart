// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get tabFormation => '阵容';

  @override
  String get emptyFormationHint => '暂无条目，点击右上角 + 添加';

  @override
  String get tooltipAddEntry => '新增条目';

  @override
  String get tooltipInputMode => '输入模式';

  @override
  String get tooltipViewMode => '查看模式';

  @override
  String get tooltipFetchData => '拉取数据';

  @override
  String get snackQueryTooFrequent => '查询过于频繁，请稍后后再试';

  @override
  String snackUserBanned(String name) {
    return '用户「$name」已被封禁';
  }

  @override
  String snackQuerySuccess(String name, String wave, String seasonWave) {
    return '数据获取成功：用户「$name」, 波数 $wave, 赛季波数 $seasonWave';
  }

  @override
  String snackQueryFailed(String reason) {
    return '查询失败：$reason';
  }

  @override
  String errorSeasonDataNotFound(String name) {
    return '未找到「$name」的赛季数据';
  }

  @override
  String get errorQueryTimeout => '查询超时，请稍后重试';

  @override
  String get totalWave => '总波数';

  @override
  String get seasonWave => '赛季波数';

  @override
  String get totalGold => '总金币';

  @override
  String get goldPower => 'GP · 指数';

  @override
  String get ranking => '排名';

  @override
  String get tooltipEditTotalWave => '修改总波数';

  @override
  String get tooltipEditSeasonWave => '修改赛季波数';

  @override
  String get dialogSetTotalWave => '设置总波数';

  @override
  String get dialogSetSeasonWave => '设置赛季波数';

  @override
  String get metricShare => '占比';

  @override
  String get metricOneOverRatio => '1/比例';

  @override
  String get metricRatio => '比例';

  @override
  String get unitNameCastle => '城堡';

  @override
  String get unitNameCastleBow => '城弓';

  @override
  String unitNameGeneric(int id) {
    return '单位 $id';
  }

  @override
  String get nameLabelCastle => '城堡名称';

  @override
  String get nameLabelCastleBow => '城弓名称';

  @override
  String get nameLabelGeneric => '名称';

  @override
  String get labelLevel => '等级';

  @override
  String get tooltipActions => '操作';

  @override
  String get actionApplied => '已应用';

  @override
  String get actionNotApplied => '未应用';

  @override
  String get actionClear => '清空';

  @override
  String get actionDelete => '删除';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '保存';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get itemSourceDragon1 => '一龙';

  @override
  String get itemSourceDragon2 => '二龙';

  @override
  String get itemSourceDragon3 => '三龙';

  @override
  String get itemSourceDragon4 => '四龙';

  @override
  String get itemSourceDragon5 => '五龙';

  @override
  String get itemSourceDragon6 => '六龙';

  @override
  String get itemSourceDragon7 => '七龙';

  @override
  String get webdavAuthFailed => '账号或密码错误（HTTP 401）';

  @override
  String get webdavForbidden => '没有访问权限（HTTP 403）';

  @override
  String get webdavNoBackupFile => '云端还没有备份文件';

  @override
  String get webdavMethodNotAllowed => '服务器不支持该操作（HTTP 405）';

  @override
  String webdavServerError(String status) {
    return '服务器返回错误（HTTP $status）';
  }

  @override
  String get webdavUnreachable => '无法连接服务器，请检查网络与 WebDAV 地址';

  @override
  String get archiveInvalidJson => '不是有效的备份文件（JSON 解析失败）';

  @override
  String get archiveInvalid => '不是有效的备份文件';

  @override
  String get archiveMissingVersion => '不是有效的备份文件（缺少版本信息）';

  @override
  String get archiveNewerVersion => '该备份由更新版本的应用创建，请先升级应用后再导入';

  @override
  String get archiveUnsupportedVersion => '不支持该备份文件版本';

  @override
  String get archiveMissingData => '不是有效的备份文件（缺少数据内容）';

  @override
  String get backupBusy => '已有备份任务进行中，请稍后再试';

  @override
  String get backupFailed => '备份失败，请稍后重试';

  @override
  String get backupNotConfigured => '请先配置 WebDAV 服务器地址、账号与密码';

  @override
  String get backupNoRestorableData => '文件中不包含可恢复的数据';

  @override
  String get dataSectionUserData => '用户数据';

  @override
  String get dataSectionUserMeta => '用户元数据';

  @override
  String get dataSectionAppSettings => '应用设置';

  @override
  String get highlightRules => '高亮规则';

  @override
  String backupRestorePartialFailure(String sections) {
    return '以下数据恢复失败：$sections';
  }

  @override
  String get listSeparator => '、';

  @override
  String get seasonEnded => '已结束';

  @override
  String get tabFunction => '功能';

  @override
  String get tabGuild => '公会';

  @override
  String get tabTools => '工具';

  @override
  String get tabSettings => '设置';

  @override
  String get snackUpdateCheckFailed => '检查更新失败，请检查网络后重试';

  @override
  String snackAlreadyLatest(String version) {
    return '已是最新版本 v$version';
  }

  @override
  String get dialogUpdateAvailable => '发现新版本';

  @override
  String dialogUpdateAvailableBody(
    String hasCurrent,
    String latest,
    String current,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasCurrent, {
      'yes': '最新版本 $latest（当前 v$current）',
      'other': '最新版本 $latest',
    });
    return '$_temp0';
  }

  @override
  String get labelChangelog => '更新日志：';

  @override
  String get actionOpenReleasePage => '打开发布页';

  @override
  String snackCannotOpenLink(String url) {
    return '无法打开链接：$url';
  }

  @override
  String get settingsThirdPartyApi => '第三方 API';

  @override
  String get labelApiUrl => 'API 地址';

  @override
  String get settingsQueryConcurrency => '查询并发数';

  @override
  String get labelConcurrency => '并发数';

  @override
  String get settingsTrackInterval => '记录间隔';

  @override
  String get labelMinutes => '分钟';

  @override
  String get settingsUserManagement => '用户管理';

  @override
  String get settingsThemeMode => '主题模式';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '亮色';

  @override
  String get themeDark => '暗色';

  @override
  String get settingsThirdPartyApiSubtitle => '玩家详情页获取波速信息';

  @override
  String get settingsAutoLastOnline => '自动查询上次在线';

  @override
  String get settingsAutoLastOnlineSubtitle => '公会详情页查询成员\"上次在线\"';

  @override
  String get settingsGameTrack => '游戏轨迹记录';

  @override
  String get settingsGameTrackSubtitle => '记录个人数据变化';

  @override
  String get settingsGameTrackMinInterval => '轨迹记录最小间隔';

  @override
  String settingsGameTrackIntervalValue(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get settingsDataBackup => '数据备份';

  @override
  String get settingsDataBackupSubtitle => 'WebDAV 云备份 · 本地导入导出';

  @override
  String get settingsCheckUpdate => '检查更新';

  @override
  String settingsCurrentVersion(String version) {
    return '当前版本 v$version';
  }

  @override
  String get settingsAbout => '关于';

  @override
  String get aboutAdaptedVersion => '适配版本';

  @override
  String get aboutGuide => '使用说明';

  @override
  String get aboutThirdPartyApiInfo => '第三方 API 说明';

  @override
  String get aboutThirdPartyApiInfoSubtitle => '当查询内容为空时，请查看这里';

  @override
  String get dialogThirdPartyApiBody =>
      '默认第三方 API (https://fnxag.eu.org/gcapi) 由开发者维护。\n只有部分玩家在记录范围中，如果有需要，可联系开发者添加。\n需要使用其他 API 时，可以自行创建。\n\n注意：该 API 与本应用无任何直接联系，请自行判断是否使用。';

  @override
  String get actionGotIt => '知道了';

  @override
  String get aboutGithubRepo => 'GitHub 仓库';

  @override
  String get aboutOriginalGithubRepo => '原项目 GitHub 仓库';

  @override
  String get aboutQqGroup => 'QQ 群';

  @override
  String get aboutDeveloperEmail => '开发者邮箱';

  @override
  String get aboutOpenSourceLicenses => '开源许可';

  @override
  String get aboutLicenseNotice => '本应用遵循 GNU GPL-3.0 开源协议';

  @override
  String get sectionInfo => '说明';

  @override
  String get sectionLinks => '链接';

  @override
  String get sectionLicenses => '授权';

  @override
  String get aboutTagline => 'Grow Castle 辅助工具';

  @override
  String get sectionWebdavBackup => 'WebDAV 备份';

  @override
  String get actionBackupNow => '立即备份';

  @override
  String get backupNowSubtitleReady => '检查云端新旧后上传覆盖';

  @override
  String get backupServerNotConfigured => '未配置服务器';

  @override
  String get actionRestoreFromCloud => '从云端恢复';

  @override
  String get backupRestoreSubtitle => '下载云端备份并覆盖本机数据';

  @override
  String get sectionLocalFiles => '本地文件';

  @override
  String get actionExportToFile => '导出到文件';

  @override
  String get backupExportSubtitle => '把全部数据保存为本地文件';

  @override
  String get actionImportFile => '导入文件';

  @override
  String get backupImportSubtitle => '从本地文件恢复数据';

  @override
  String get backupOverwriteHint => '导入或恢复会覆盖本机全部数据，建议先导出备份。';

  @override
  String get labelServerAddress => '服务器地址';

  @override
  String get labelNotSet => '未设置';

  @override
  String get labelAccount => '账号';

  @override
  String get labelPassword => '密码';

  @override
  String get labelWebdavAccount => 'WebDAV 账号';

  @override
  String get labelWebdavPassword => 'WebDAV 密码';

  @override
  String get labelServerUrlExample => 'https://dav.example.com/dav/目录';

  @override
  String backupLastSuccess(String time) {
    return '上次成功备份：$time';
  }

  @override
  String get labelNever => '从未';

  @override
  String get labelUnknown => '未知';

  @override
  String get labelTimeUnknown => '时间未知';

  @override
  String backupLastFailed(String hasTime, String error, String time) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': '上次备份失败：$error（$time）',
      'other': '上次备份失败：$error',
    });
    return '$_temp0';
  }

  @override
  String get snackBackupSuccess => '已备份到云端';

  @override
  String snackBackupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String snackRemoteProbeFailed(String reason) {
    return '检测云端备份失败：$reason';
  }

  @override
  String get snackRemoteProbeFailedRetry => '检测云端备份失败，请稍后重试';

  @override
  String get dialogUploadBackupTitle => '上传备份到云端';

  @override
  String dialogCloudBackupLine(String hasSize, String time, String size) {
    String _temp0 = intl.Intl.selectLogic(hasSize, {
      'yes': '云端备份：$time，$size KB',
      'other': '云端备份：$time',
    });
    return '$_temp0';
  }

  @override
  String get dialogCloudBackupNoFile => '云端备份：还没有备份文件（将新建一份）';

  @override
  String dialogLastLocalBackupLine(String time) {
    return '本机上次成功备份：$time';
  }

  @override
  String get actionRestoreRemote => '恢复云端';

  @override
  String get actionUpload => '上传';

  @override
  String get actionOverwriteAnyway => '仍要覆盖';

  @override
  String get actionOverwriteUpload => '覆盖上传';

  @override
  String get dialogWarningRemoteNewer =>
      '云端备份比本机上次成功备份更新，可能来自其他设备；覆盖后云端那份将无法找回。';

  @override
  String get dialogWarningRemoteTimeUnknown => '无法获取云端备份时间；覆盖后云端那份将无法找回。';

  @override
  String get dialogWarningLocalNoRecord => '本机没有成功备份记录，无法确认云端那份的来源；覆盖后无法找回。';

  @override
  String dialogRestoreCloudSource(
    String hasTime,
    String time,
    String hasSize,
    String size,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': '云端备份（$time）',
      'other': '云端备份',
    });
    String _temp1 = intl.Intl.selectLogic(hasSize, {
      'yes': '，$size KB',
      'other': '',
    });
    return '$_temp0$_temp1';
  }

  @override
  String snackFetchRemoteFailed(String reason) {
    return '获取云端备份失败：$reason';
  }

  @override
  String snackInvalidCloudFile(String reason) {
    return '云端文件无效：$reason';
  }

  @override
  String dialogWarningRestoreOlder(String hasTime, String time) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': '云端备份早于本机上次成功备份（$time），恢复会退回较旧的数据。',
      'other': '云端备份早于本机上次成功备份，恢复会退回较旧的数据。',
    });
    return '$_temp0';
  }

  @override
  String get dialogWarningRestoreNewer => '云端备份比本机上次成功备份更新，可能来自其他设备。';

  @override
  String get dialogWarningRestoreUnknown => '无法判断云端备份与本机记录的新旧，恢复前请确认来源。';

  @override
  String get snackExportFailed => '导出失败，请稍后重试';

  @override
  String get dialogTitleExportBackup => '导出数据备份';

  @override
  String get snackExportSuccess => '已导出到文件';

  @override
  String get dialogTitlePickBackupFile => '选择备份文件';

  @override
  String snackInvalidFile(String reason) {
    return '文件无效：$reason';
  }

  @override
  String get snackReadFileFailed => '读取文件失败，请确认是导出的备份文件';

  @override
  String dialogPickLocalFileSource(String name) {
    return '本机文件：$name';
  }

  @override
  String dialogRestoreSource(String source) {
    return '来源：$source';
  }

  @override
  String get actionOverwriteRestore => '覆盖恢复';

  @override
  String get snackRestoreSuccess => '已恢复本地数据';

  @override
  String snackRestoreFailed(String error) {
    return '恢复失败：$error';
  }

  @override
  String labelBackupTime(String time) {
    return '备份时间：$time';
  }

  @override
  String labelUserCount(int count) {
    return '用户数：$count';
  }

  @override
  String labelTrackRecordCount(int count) {
    return '游戏轨迹记录：$count 条';
  }

  @override
  String get labelIncludesItemRules => '包含：词条高亮规则';

  @override
  String get labelIncludesAppSettings => '包含：应用设置';

  @override
  String get snackDefaultUserNoRename => '默认用户不可重命名';

  @override
  String get snackDefaultUserNoDelete => '默认用户不可删除';

  @override
  String get tooltipDetails => '详细信息';

  @override
  String get actionAddUser => '添加用户';

  @override
  String errorUserDataNotFound(String name) {
    return '未找到用户「$name」的数据';
  }

  @override
  String get dialogDeleteUser => '删除用户';

  @override
  String dialogDeleteUserConfirm(String name) {
    return '确定要删除用户 \"$name\" 吗？';
  }

  @override
  String get labelUsername => '用户名';

  @override
  String get labelGuildOptional => '公会（选填）';

  @override
  String get actionAdd => '添加';

  @override
  String get dialogEditUser => '编辑用户';

  @override
  String get tooltipShowPassword => '显示';

  @override
  String get tooltipHidePassword => '隐藏';

  @override
  String get labelUsernameHint => '0-9, a-z, A-Z, -, _, space';

  @override
  String get waveStatus => '跳波状态';

  @override
  String get wavePushIncomeCalc => '推波收益计算';

  @override
  String get tabIncome => '收入';

  @override
  String get noRecord => '无记录';

  @override
  String timeSecondsAgo(int count) {
    return '$count 秒前';
  }

  @override
  String timeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String timeMonthsAgo(int count) {
    return '$count 月前';
  }

  @override
  String timeYearsAgo(int count) {
    return '$count 年前';
  }

  @override
  String get labelGameSpeed => '游戏速度';

  @override
  String get optionSpeed2x => '2速';

  @override
  String get optionSpeed2xAds10 => '2速 + 10广';

  @override
  String get optionSpeed3x => '3速';

  @override
  String get optionChronoWhite => '白闹钟(+10%)';

  @override
  String get optionChronoYellow => '黄闹钟(+14%)';

  @override
  String get optionChronoBlue => '蓝闹钟(+20%)';

  @override
  String get optionEquipped => '已装备';

  @override
  String get optionNotEquipped => '未装备';

  @override
  String get optionNone => '无';

  @override
  String get optionAutoBattleGoldBreak => '金挂(GAB) / 破挂(FAB)';

  @override
  String get optionAutoBattleTime => '时挂(TAB)';

  @override
  String get dialogWaveStatusDisclaimer => '数据仅供参考，实际游戏中可能会有较大偏差。';

  @override
  String get actionClose => '关闭';

  @override
  String get labelChronoType => '闹钟类型';

  @override
  String get labelHorn10 => '10%角';

  @override
  String get labelHorn30 => '30%角';

  @override
  String get labelDevilHornSkip => '恶魔号角跳波数';

  @override
  String get labelAutoBattleType => '挂机类型';

  @override
  String get infoAutoBattleTab =>
      '时挂 (TAB) 选项默认启用释放乐队技能 (BAND SKILL) ，且兽人号角和经验号角同时上场。';

  @override
  String get snackTrackDeleted => '已删除轨迹记录';

  @override
  String get actionUndo => '撤销';

  @override
  String get dialogWarning => '注意';

  @override
  String get dialogGameTrackOff => '游戏轨迹记录功能已关闭，无法记录新的轨迹数据。';

  @override
  String get tooltipViewTrackChart => '查看轨迹图表';

  @override
  String get tooltipSortOldestFirst => '按时间由远到近';

  @override
  String get tooltipSortNewestFirst => '按时间由近到远';

  @override
  String get emptyTrackDefaultUser => '当前为默认用户，无法记录轨迹';

  @override
  String get emptyTrackDisabled => '轨迹记录功能已关闭，请在设置中打开「游戏轨迹记录」';

  @override
  String get emptyGameTrack => '暂无轨迹记录';

  @override
  String get tooltipDeleteRecord => '删除记录';

  @override
  String labelTrackCount(int count) {
    return '共 $count 条记录';
  }

  @override
  String get gameTrackChart => '轨迹图表';

  @override
  String labelChartRange(String start, String end) {
    return '起始 $start\n截止 $end';
  }

  @override
  String get emptyChartNeedTwoRecords => '至少需要两条轨迹记录';

  @override
  String labelChartDownsampled(int total, int shown) {
    return '已压缩显示：共 $total 条，显示 $shown 条';
  }

  @override
  String get totalEconomy => '总经济';

  @override
  String get metricIndex => '指数';

  @override
  String get dialogConfirmApplyIncome => '确认填入收益';

  @override
  String dialogApplyGabBonusContent(String from, String to) {
    return '金挂收益：$from% -> $to%？';
  }

  @override
  String snackAppliedGabBonus(String value) {
    return '已填入金挂平均收益 $value%';
  }

  @override
  String get actionConfirm => '确认';

  @override
  String get actionReset => '重置';

  @override
  String get dialogResetIncomeSamples => '确认清空当前用户的所有收入样本？';

  @override
  String get emptyIncomeSamples => '暂无收入样本';

  @override
  String get labelGabCost => '金挂成本';

  @override
  String get labelAverageIncome => '平均收入';

  @override
  String get labelPercent => '百分比';

  @override
  String get actionFillIn => '填入';

  @override
  String get dialogInputWaveIncome => '输入每波金币收入';

  @override
  String get labelWaveGoldIncome => '每波金币收入';

  @override
  String get tooltipInfo => '提示';

  @override
  String get dialogIncomeNotice => '填写“跳波状态”后再填写此处，否则计算结果不准确。\n\n此处计算结果为每日收入。';

  @override
  String get tabIncomeColony => '殖民地';

  @override
  String get tabIncomeWave => '推波';

  @override
  String get tabIncomeOther => '其他';

  @override
  String get labelColonyLevel => '殖民地等级';

  @override
  String get labelExtraColonyC => '额外殖民地C';

  @override
  String get labelExtraColonyG => '额外殖民地G';

  @override
  String get labelWheel => '车轮';

  @override
  String get labelWhip => '鞭子';

  @override
  String get labelGabAverageBonus => '金挂平均收益';

  @override
  String get labelDailyGabTime => '每日金挂时间';

  @override
  String get labelDailyTabTime => '每日时挂时间';

  @override
  String get labelSeasonColony => '赛季殖民地';

  @override
  String get labelGoldenTree => '金币大树';

  @override
  String get toolDragonSimulator => '刷龙模拟器';

  @override
  String get toolItemComparer => '装备对比';

  @override
  String get toolBestLineCalc => '最优装备词条组合';

  @override
  String get rankingKindPlayer => '个人排行榜';

  @override
  String get rankingKindGuild => '公会排行榜';

  @override
  String get rankingKindHell => '无尽排行榜';

  @override
  String get emptyRankingData => '暂无榜单数据';

  @override
  String get emptyData => '暂无数据';

  @override
  String labelRankingTrend(String kind) {
    return '$kind趋势';
  }

  @override
  String labelTopCount(int count) {
    return '前 $count';
  }

  @override
  String labelRankSummary(int count, String max, String min) {
    return '前 $count 名 · 最高 $max · 最低 $min';
  }

  @override
  String snackRefreshFailed(String reason) {
    return '刷新失败：$reason';
  }

  @override
  String dialogRankMilestones(String kind) {
    return '$kind名次';
  }

  @override
  String get tooltipViewScoreTrend => '查看分数趋势';

  @override
  String get tooltipViewMilestoneRanks => '查看特殊名次';

  @override
  String get hintSelectPlayerDetail => '点击左侧条目查看玩家详情';

  @override
  String get actionRetry => '重试';

  @override
  String get snackNeedEnabledRule => '请先在“高亮规则”中启用至少一条规则';

  @override
  String rollToHitHit(String count) {
    return '命中！共 roll 了 $count 次';
  }

  @override
  String rollToHitStopped(String count) {
    return '已手动停止，共 roll 了 $count 次';
  }

  @override
  String get labelItemSource => '装备来源';

  @override
  String get labelHighestTierBonus => '最高品阶掉落率加成';

  @override
  String get labelRollBatchSize => 'roll 单次数量';

  @override
  String get actionRollOnce => 'roll 单次';

  @override
  String get actionStop => '停止';

  @override
  String get actionRollToHit => 'roll 到死';

  @override
  String rollToHitRunning(String count) {
    return 'roll 到死进行中：已 roll $count 次…';
  }

  @override
  String get unnamedRule => '未命名规则';

  @override
  String get itemTypeBow => '弓';

  @override
  String get itemTypeSword => '剑';

  @override
  String get itemTypeStaff => '杖';

  @override
  String get itemTypeHammer => '锤';

  @override
  String get itemTypeRing => '戒指';

  @override
  String get itemTypeNecklace => '项链';

  @override
  String get itemTypeBracelet => '手镯';

  @override
  String get itemTypeEarrings => '耳环';

  @override
  String get actionAddRule => '新增规则';

  @override
  String get emptyItemRuleHint => '暂无规则，点击右下角新增';

  @override
  String get tooltipPinToTop => '命中后置顶';

  @override
  String get actionEdit => '编辑';

  @override
  String labelItemTypes(String types) {
    return '装备类型：$types';
  }

  @override
  String get errorWhiteLinesWithRed => '已有红色词条，白色词条最多 2 条';

  @override
  String get errorWhiteLinesMax => '白色词条最多 3 条';

  @override
  String get errorRedWithThreeWhite => '白色词条已达 3 条，不能选择红色词条';

  @override
  String get errorNoLineSelected => '请至少选择一个词条';

  @override
  String get errorValueNotNumber => '数值需为数字或留空';

  @override
  String get errorMinGreaterThanMax => '下限（大于）必须小于上限（小于）';

  @override
  String errorMinOutOfRange(String line, String min, String max) {
    return '\"$line\" 的下限超出 roll 值范围（$min ~ $max）';
  }

  @override
  String errorMaxOutOfRange(String line, String min, String max) {
    return '\"$line\" 的上限超出 roll 值范围（$min ~ $max）';
  }

  @override
  String get titleEditRule => '编辑规则';

  @override
  String get labelHintText => '提示文本';

  @override
  String get hintRuleHintExample => '如：红白加强（可留空）';

  @override
  String get labelPinToTop => '命中后置顶显示';

  @override
  String get labelSelectItemTypes => '指定装备类型（不选则不限）';

  @override
  String get helpRuleForm =>
      '提示：红/金词条各最多选 1 条；白色词条合计 3 条时不能选红色词条；\n输入数值范围时，判断的是词条原始值（加强前的值），留空表示不限。\n\n大于下限必须小于上限；输入值还需在词条的允许范围内。';

  @override
  String labelLineCount(int count) {
    return '$count 条';
  }

  @override
  String get lineColorWhite => '白词条';

  @override
  String get lineColorRed => '红词条';

  @override
  String get lineColorGold => '金词条';

  @override
  String get lineColorPurple => '紫词条';

  @override
  String labelItemLines(int index) {
    return '装备 $index 词条';
  }

  @override
  String get dialogItemCompareHelpIntro => '该工具用于对比两件装备的期望。\n\n';

  @override
  String get dialogItemCompareHelpStepsTitle => '使用步骤：\n';

  @override
  String get dialogItemCompareHelpStep1 =>
      '1. 确认需要对比的装备 / 宝珠 / 宝物槽位，然后将对应的物品卸下，根据此时的面板填写“无装备面板”数据；\n';

  @override
  String get dialogItemCompareHelpStep2 => '2. 将两件装备的白词条填写到“装备 1 / 装备 2”中，';

  @override
  String get dialogItemCompareHelpStep2Note =>
      '请注意词条类型，元素伤害统一并入 \"Element Damage\"，请自行根据单位属性填入对应元素伤害词条；\n';

  @override
  String get dialogItemCompareHelpStep3 => '3. 对比结果：实时显示三组 DPS 结果，并给出结论。\n\n\n';

  @override
  String get dialogItemCompareHelpNormalUnit => '普攻型单位：';

  @override
  String get dialogItemCompareHelpNormalUnitDesc =>
      '需要填写 Attacks Per Second 和 Increased Speed，Attack Speed % 词条参与计算。\n';

  @override
  String get dialogItemCompareHelpSkillUnit => '技能型单位：';

  @override
  String get dialogItemCompareHelpSkillUnitDesc =>
      '不填写上述两项，Attack Speed % 词条不参与计算。';

  @override
  String get dialogItemCompareHelpNoteLabel => '\n\n注：';

  @override
  String get dialogItemCompareHelpNoteDesc => '宝珠、宝物等词条也可用于计算，但需要注意词条类型。';

  @override
  String get dialogResetConfirm => '是否清空所有输入？';

  @override
  String get labelNoItemPanel => '无装备面板';

  @override
  String get actionAddLine => '添加词条';

  @override
  String get hintSelectLineType => '选择词条类型';

  @override
  String get hintValue => '数值';

  @override
  String get tooltipDeleteLine => '删除词条';

  @override
  String get labelNoCrit => '无暴击';

  @override
  String get labelWithCrit => '有暴击';

  @override
  String get labelNoItem => '无装备';

  @override
  String labelItemNumber(int index) {
    return '装备 $index';
  }

  @override
  String labelCompareGainSummary(String gain1, String gain2) {
    return '装备 1 较无装备 $gain1 · 装备 2 较无装备 $gain2';
  }

  @override
  String get compareVerdictPending => '填写数据后自动对比';

  @override
  String compareVerdictItem1(String gap) {
    return '装备 1 更优$gap';
  }

  @override
  String compareGapItem2(String gain) {
    return '，DPS 比装备 2 高 $gain';
  }

  @override
  String compareVerdictItem2(String gap) {
    return '装备 2 更优$gap';
  }

  @override
  String compareGapItem1(String gain) {
    return '，DPS 比装备 1 高 $gain';
  }

  @override
  String get compareVerdictTie => '两件装备 DPS 相同';

  @override
  String get labelNoDamageLines => '（无输出词条）';

  @override
  String get dialogBestLineHelpAvgDmg =>
      'Avg. Dmg 和下方列表中的 Damage 都是 Damage 与 Elemental Damage 的均值。';

  @override
  String get labelPanelWithoutItem => '面板无装备数值';

  @override
  String labelLineSlot(int count) {
    return '$count 词条';
  }

  @override
  String labelComboCount(int count) {
    return '共 $count 种';
  }

  @override
  String get gameTrack => '游戏轨迹';

  @override
  String snackSyncFailed(String reason) {
    return '同步失败：$reason';
  }

  @override
  String errorGuildNotFound(String name) {
    return '未找到公会「$name」的信息';
  }

  @override
  String get emptyGuildDefaultUserHint =>
      '当前为默认用户，仅用于体验基础功能。\n请到「设置」页的「用户管理」创建自己的账号，并填写公会名。';

  @override
  String get emptyGuildHint => '当前用户未设置公会，请先到「用户管理」中填写公会名';

  @override
  String get emptyGuildMembers => '该公会暂无成员';

  @override
  String get actionGoToUserManagement => '前往用户管理';

  @override
  String get emptySelectMemberHint => '点击左侧成员查看玩家详情';

  @override
  String guildMemberCountAndScore(int count, String score) {
    return '$count 人 · $score';
  }

  @override
  String get tooltipCloseDetail => '关闭详情';

  @override
  String errorPlayerBanned(String name) {
    return '玩家「$name」已被封禁';
  }

  @override
  String get labelWphHistory => '每小时波速（第三方 API）';

  @override
  String labelSeason(String season) {
    return '赛季 $season';
  }

  @override
  String get endlessScore => '无尽分数';

  @override
  String get lastOnline => '上次在线';

  @override
  String unitEnabledCount(int enabled, int total) {
    return '$enabled/$total 启用';
  }

  @override
  String get metricGoldShare => '金币占比';

  @override
  String get metricUnitPerWave => '单位 / 波数';

  @override
  String get metricWavePerUnit => '波数 / 单位';

  @override
  String get seasonProgress => '赛季进度';

  @override
  String get labelStart => '开始';

  @override
  String get labelEnd => '结束';

  @override
  String get labelRemaining => '剩余';

  @override
  String get incomeTotal => '总收入';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get tabFormation => '陣容';

  @override
  String get emptyFormationHint => '尚無項目，點擊右上角 + 新增';

  @override
  String get tooltipAddEntry => '新增項目';

  @override
  String get tooltipInputMode => '輸入模式';

  @override
  String get tooltipViewMode => '檢視模式';

  @override
  String get tooltipFetchData => '取得資料';

  @override
  String get snackQueryTooFrequent => '查詢過於頻繁，請稍後再試';

  @override
  String snackUserBanned(String name) {
    return '使用者「$name」已被封鎖';
  }

  @override
  String snackQuerySuccess(String name, String wave, String seasonWave) {
    return '資料取得成功：使用者「$name」，波數 $wave，賽季波數 $seasonWave';
  }

  @override
  String snackQueryFailed(String reason) {
    return '查詢失敗：$reason';
  }

  @override
  String errorSeasonDataNotFound(String name) {
    return '找不到「$name」的賽季資料';
  }

  @override
  String get errorQueryTimeout => '查詢逾時，請稍後重試';

  @override
  String get totalWave => '總波數';

  @override
  String get seasonWave => '賽季波數';

  @override
  String get totalGold => '總金幣';

  @override
  String get goldPower => 'GP · 指數';

  @override
  String get ranking => '排名';

  @override
  String get tooltipEditTotalWave => '修改總波數';

  @override
  String get tooltipEditSeasonWave => '修改賽季波數';

  @override
  String get dialogSetTotalWave => '設定總波數';

  @override
  String get dialogSetSeasonWave => '設定賽季波數';

  @override
  String get metricShare => '佔比';

  @override
  String get metricOneOverRatio => '1/比例';

  @override
  String get metricRatio => '比例';

  @override
  String get unitNameCastle => '城堡';

  @override
  String get unitNameCastleBow => '城弓';

  @override
  String unitNameGeneric(int id) {
    return '單位 $id';
  }

  @override
  String get nameLabelCastle => '城堡名稱';

  @override
  String get nameLabelCastleBow => '城弓名稱';

  @override
  String get nameLabelGeneric => '名稱';

  @override
  String get labelLevel => '等級';

  @override
  String get tooltipActions => '操作';

  @override
  String get actionApplied => '已套用';

  @override
  String get actionNotApplied => '未套用';

  @override
  String get actionClear => '清除';

  @override
  String get actionDelete => '刪除';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '儲存';

  @override
  String get settingsLanguage => '語言';

  @override
  String get languageSystem => '系統';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get itemSourceDragon1 => '一龍';

  @override
  String get itemSourceDragon2 => '二龍';

  @override
  String get itemSourceDragon3 => '三龍';

  @override
  String get itemSourceDragon4 => '四龍';

  @override
  String get itemSourceDragon5 => '五龍';

  @override
  String get itemSourceDragon6 => '六龍';

  @override
  String get itemSourceDragon7 => '七龍';

  @override
  String get webdavAuthFailed => '帳號或密碼錯誤（HTTP 401）';

  @override
  String get webdavForbidden => '沒有存取權限（HTTP 403）';

  @override
  String get webdavNoBackupFile => '雲端還沒有備份檔案';

  @override
  String get webdavMethodNotAllowed => '伺服器不支援此操作（HTTP 405）';

  @override
  String webdavServerError(String status) {
    return '伺服器回傳錯誤（HTTP $status）';
  }

  @override
  String get webdavUnreachable => '無法連線伺服器，請檢查網路與 WebDAV 位址';

  @override
  String get archiveInvalidJson => '不是有效的備份檔案（JSON 解析失敗）';

  @override
  String get archiveInvalid => '不是有效的備份檔案';

  @override
  String get archiveMissingVersion => '不是有效的備份檔案（缺少版本資訊）';

  @override
  String get archiveNewerVersion => '此備份由較新版本的應用程式建立，請先更新應用程式後再匯入';

  @override
  String get archiveUnsupportedVersion => '不支援此備份檔案版本';

  @override
  String get archiveMissingData => '不是有效的備份檔案（缺少資料內容）';

  @override
  String get backupBusy => '已有備份工作進行中，請稍後再試';

  @override
  String get backupFailed => '備份失敗，請稍後重試';

  @override
  String get backupNotConfigured => '請先設定 WebDAV 伺服器位址、帳號與密碼';

  @override
  String get backupNoRestorableData => '檔案中不包含可還原的資料';

  @override
  String get dataSectionUserData => '使用者資料';

  @override
  String get dataSectionUserMeta => '使用者中繼資料';

  @override
  String get dataSectionAppSettings => '應用程式設定';

  @override
  String get highlightRules => '高亮規則';

  @override
  String backupRestorePartialFailure(String sections) {
    return '以下資料還原失敗：$sections';
  }

  @override
  String get listSeparator => '、';

  @override
  String get seasonEnded => '已結束';

  @override
  String get tabFunction => '功能';

  @override
  String get tabGuild => '公會';

  @override
  String get tabTools => '工具';

  @override
  String get tabSettings => '設定';

  @override
  String get snackUpdateCheckFailed => '檢查更新失敗，請檢查網路後重試';

  @override
  String snackAlreadyLatest(String version) {
    return '已是最新版本 v$version';
  }

  @override
  String get dialogUpdateAvailable => '發現新版本';

  @override
  String dialogUpdateAvailableBody(
    String hasCurrent,
    String latest,
    String current,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasCurrent, {
      'yes': '最新版本 $latest（目前 v$current）',
      'other': '最新版本 $latest',
    });
    return '$_temp0';
  }

  @override
  String get labelChangelog => '更新日誌：';

  @override
  String get actionOpenReleasePage => '開啟發布頁';

  @override
  String snackCannotOpenLink(String url) {
    return '無法開啟連結：$url';
  }

  @override
  String get settingsThirdPartyApi => '第三方 API';

  @override
  String get labelApiUrl => 'API 位址';

  @override
  String get settingsQueryConcurrency => '查詢並行數';

  @override
  String get labelConcurrency => '並行數';

  @override
  String get settingsTrackInterval => '紀錄間隔';

  @override
  String get labelMinutes => '分鐘';

  @override
  String get settingsUserManagement => '使用者管理';

  @override
  String get settingsThemeMode => '主題模式';

  @override
  String get themeSystem => '系統';

  @override
  String get themeLight => '亮色';

  @override
  String get themeDark => '暗色';

  @override
  String get settingsThirdPartyApiSubtitle => '玩家詳情頁取得波速資訊';

  @override
  String get settingsAutoLastOnline => '自動查詢上次線上';

  @override
  String get settingsAutoLastOnlineSubtitle => '公會詳情頁查詢成員「上次線上」';

  @override
  String get settingsGameTrack => '遊戲軌跡紀錄';

  @override
  String get settingsGameTrackSubtitle => '紀錄個人資料變化';

  @override
  String get settingsGameTrackMinInterval => '軌跡紀錄最小間隔';

  @override
  String settingsGameTrackIntervalValue(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String get settingsDataBackup => '資料備份';

  @override
  String get settingsDataBackupSubtitle => 'WebDAV 雲端備份 · 本機匯入匯出';

  @override
  String get settingsCheckUpdate => '檢查更新';

  @override
  String settingsCurrentVersion(String version) {
    return '目前版本 v$version';
  }

  @override
  String get settingsAbout => '關於';

  @override
  String get aboutAdaptedVersion => '對應版本';

  @override
  String get aboutGuide => '使用說明';

  @override
  String get aboutThirdPartyApiInfo => '第三方 API 說明';

  @override
  String get aboutThirdPartyApiInfoSubtitle => '當查詢內容為空時，請查看這裡';

  @override
  String get dialogThirdPartyApiBody =>
      '預設第三方 API (https://fnxag.eu.org/gcapi) 由開發者維護。\n只有部分玩家在紀錄範圍中，如果有需要，可聯絡開發者新增。\n需要使用其他 API 時，可以自行建立。\n\n注意：該 API 與本應用程式無任何直接聯繫，請自行判斷是否使用。';

  @override
  String get actionGotIt => '知道了';

  @override
  String get aboutGithubRepo => 'GitHub 儲存庫';

  @override
  String get aboutOriginalGithubRepo => '原專案 GitHub 儲存庫';

  @override
  String get aboutQqGroup => 'QQ 群';

  @override
  String get aboutDeveloperEmail => '開發者電子郵件';

  @override
  String get aboutOpenSourceLicenses => '開源授權';

  @override
  String get aboutLicenseNotice => '本應用程式遵循 GNU GPL-3.0 開源協議';

  @override
  String get sectionInfo => '說明';

  @override
  String get sectionLinks => '連結';

  @override
  String get sectionLicenses => '授權';

  @override
  String get aboutTagline => 'Grow Castle 輔助工具';

  @override
  String get sectionWebdavBackup => 'WebDAV 備份';

  @override
  String get actionBackupNow => '立即備份';

  @override
  String get backupNowSubtitleReady => '檢查雲端新舊後上傳覆蓋';

  @override
  String get backupServerNotConfigured => '未設定伺服器';

  @override
  String get actionRestoreFromCloud => '從雲端還原';

  @override
  String get backupRestoreSubtitle => '下載雲端備份並覆蓋本機資料';

  @override
  String get sectionLocalFiles => '本機檔案';

  @override
  String get actionExportToFile => '匯出至檔案';

  @override
  String get backupExportSubtitle => '將全部資料儲存為本機檔案';

  @override
  String get actionImportFile => '匯入檔案';

  @override
  String get backupImportSubtitle => '從本機檔案還原資料';

  @override
  String get backupOverwriteHint => '匯入或還原會覆蓋本機全部資料，建議先匯出備份。';

  @override
  String get labelServerAddress => '伺服器位址';

  @override
  String get labelNotSet => '未設定';

  @override
  String get labelAccount => '帳號';

  @override
  String get labelPassword => '密碼';

  @override
  String get labelWebdavAccount => 'WebDAV 帳號';

  @override
  String get labelWebdavPassword => 'WebDAV 密碼';

  @override
  String get labelServerUrlExample => 'https://dav.example.com/dav/目錄';

  @override
  String backupLastSuccess(String time) {
    return '上次成功備份：$time';
  }

  @override
  String get labelNever => '從未';

  @override
  String get labelUnknown => '未知';

  @override
  String get labelTimeUnknown => '時間未知';

  @override
  String backupLastFailed(String hasTime, String error, String time) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': '上次備份失敗：$error（$time）',
      'other': '上次備份失敗：$error',
    });
    return '$_temp0';
  }

  @override
  String get snackBackupSuccess => '已備份到雲端';

  @override
  String snackBackupFailed(String error) {
    return '備份失敗：$error';
  }

  @override
  String snackRemoteProbeFailed(String reason) {
    return '偵測雲端備份失敗：$reason';
  }

  @override
  String get snackRemoteProbeFailedRetry => '偵測雲端備份失敗，請稍後重試';

  @override
  String get dialogUploadBackupTitle => '上傳備份到雲端';

  @override
  String dialogCloudBackupLine(String hasSize, String time, String size) {
    String _temp0 = intl.Intl.selectLogic(hasSize, {
      'yes': '雲端備份：$time，$size KB',
      'other': '雲端備份：$time',
    });
    return '$_temp0';
  }

  @override
  String get dialogCloudBackupNoFile => '雲端備份：還沒有備份檔案（將新建一份）';

  @override
  String dialogLastLocalBackupLine(String time) {
    return '本機上次成功備份：$time';
  }

  @override
  String get actionRestoreRemote => '還原雲端';

  @override
  String get actionUpload => '上傳';

  @override
  String get actionOverwriteAnyway => '仍要覆蓋';

  @override
  String get actionOverwriteUpload => '覆蓋上傳';

  @override
  String get dialogWarningRemoteNewer =>
      '雲端備份比本機上次成功備份新，可能來自其他裝置；覆蓋後雲端那份將無法救回。';

  @override
  String get dialogWarningRemoteTimeUnknown => '無法取得雲端備份時間；覆蓋後雲端那份將無法救回。';

  @override
  String get dialogWarningLocalNoRecord => '本機沒有成功備份紀錄，無法確認雲端那份的來源；覆蓋後無法救回。';

  @override
  String dialogRestoreCloudSource(
    String hasTime,
    String time,
    String hasSize,
    String size,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': '雲端備份（$time）',
      'other': '雲端備份',
    });
    String _temp1 = intl.Intl.selectLogic(hasSize, {
      'yes': '，$size KB',
      'other': '',
    });
    return '$_temp0$_temp1';
  }

  @override
  String snackFetchRemoteFailed(String reason) {
    return '取得雲端備份失敗：$reason';
  }

  @override
  String snackInvalidCloudFile(String reason) {
    return '雲端檔案無效：$reason';
  }

  @override
  String dialogWarningRestoreOlder(String hasTime, String time) {
    String _temp0 = intl.Intl.selectLogic(hasTime, {
      'yes': '雲端備份早於本機上次成功備份（$time），還原會退回較舊的資料。',
      'other': '雲端備份早於本機上次成功備份，還原會退回較舊的資料。',
    });
    return '$_temp0';
  }

  @override
  String get dialogWarningRestoreNewer => '雲端備份比本機上次成功備份新，可能來自其他裝置。';

  @override
  String get dialogWarningRestoreUnknown => '無法判斷雲端備份與本機紀錄的新舊，還原前請確認來源。';

  @override
  String get snackExportFailed => '匯出失敗，請稍後重試';

  @override
  String get dialogTitleExportBackup => '匯出資料備份';

  @override
  String get snackExportSuccess => '已匯出至檔案';

  @override
  String get dialogTitlePickBackupFile => '選擇備份檔案';

  @override
  String snackInvalidFile(String reason) {
    return '檔案無效：$reason';
  }

  @override
  String get snackReadFileFailed => '讀取檔案失敗，請確認是匯出的備份檔案';

  @override
  String dialogPickLocalFileSource(String name) {
    return '本機檔案：$name';
  }

  @override
  String dialogRestoreSource(String source) {
    return '來源：$source';
  }

  @override
  String get actionOverwriteRestore => '覆蓋還原';

  @override
  String get snackRestoreSuccess => '已還原本機資料';

  @override
  String snackRestoreFailed(String error) {
    return '還原失敗：$error';
  }

  @override
  String labelBackupTime(String time) {
    return '備份時間：$time';
  }

  @override
  String labelUserCount(int count) {
    return '使用者數：$count';
  }

  @override
  String labelTrackRecordCount(int count) {
    return '遊戲軌跡紀錄：$count 筆';
  }

  @override
  String get labelIncludesItemRules => '包含：詞條高亮規則';

  @override
  String get labelIncludesAppSettings => '包含：應用程式設定';

  @override
  String get snackDefaultUserNoRename => '預設使用者不可重新命名';

  @override
  String get snackDefaultUserNoDelete => '預設使用者不可刪除';

  @override
  String get tooltipDetails => '詳細資訊';

  @override
  String get actionAddUser => '新增使用者';

  @override
  String errorUserDataNotFound(String name) {
    return '找不到使用者「$name」的資料';
  }

  @override
  String get dialogDeleteUser => '刪除使用者';

  @override
  String dialogDeleteUserConfirm(String name) {
    return '確定要刪除使用者「$name」嗎？';
  }

  @override
  String get labelUsername => '使用者名稱';

  @override
  String get labelGuildOptional => '公會（選填）';

  @override
  String get actionAdd => '新增';

  @override
  String get dialogEditUser => '編輯使用者';

  @override
  String get tooltipShowPassword => '顯示';

  @override
  String get tooltipHidePassword => '隱藏';

  @override
  String get labelUsernameHint => '0-9, a-z, A-Z, -, _, space';

  @override
  String get waveStatus => '跳波狀態';

  @override
  String get wavePushIncomeCalc => '推波收益計算';

  @override
  String get tabIncome => '收入';

  @override
  String get noRecord => '無紀錄';

  @override
  String timeSecondsAgo(int count) {
    return '$count 秒前';
  }

  @override
  String timeMinutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小時前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String timeMonthsAgo(int count) {
    return '$count 個月前';
  }

  @override
  String timeYearsAgo(int count) {
    return '$count 年前';
  }

  @override
  String get labelGameSpeed => '遊戲速度';

  @override
  String get optionSpeed2x => '2速';

  @override
  String get optionSpeed2xAds10 => '2速 + 10廣';

  @override
  String get optionSpeed3x => '3速';

  @override
  String get optionChronoWhite => '白鬧鐘(+10%)';

  @override
  String get optionChronoYellow => '黃鬧鐘(+14%)';

  @override
  String get optionChronoBlue => '藍鬧鐘(+20%)';

  @override
  String get optionEquipped => '已裝備';

  @override
  String get optionNotEquipped => '未裝備';

  @override
  String get optionNone => '無';

  @override
  String get optionAutoBattleGoldBreak => '金掛(GAB) / 破掛(FAB)';

  @override
  String get optionAutoBattleTime => '時掛(TAB)';

  @override
  String get dialogWaveStatusDisclaimer => '資料僅供參考，實際遊戲中可能會有較大偏差。';

  @override
  String get actionClose => '關閉';

  @override
  String get labelChronoType => '鬧鐘類型';

  @override
  String get labelHorn10 => '10%角';

  @override
  String get labelHorn30 => '30%角';

  @override
  String get labelDevilHornSkip => '惡魔號角跳波數';

  @override
  String get labelAutoBattleType => '掛機類型';

  @override
  String get infoAutoBattleTab =>
      '時掛 (TAB) 選項預設啟用釋放樂團技能 (BAND SKILL)，且獸人號角與經驗號角同時上場。';

  @override
  String get snackTrackDeleted => '已刪除軌跡紀錄';

  @override
  String get actionUndo => '復原';

  @override
  String get dialogWarning => '注意';

  @override
  String get dialogGameTrackOff => '遊戲軌跡紀錄功能已關閉，無法紀錄新的軌跡資料。';

  @override
  String get tooltipViewTrackChart => '檢視軌跡圖表';

  @override
  String get tooltipSortOldestFirst => '依時間由遠到近';

  @override
  String get tooltipSortNewestFirst => '依時間由近到遠';

  @override
  String get emptyTrackDefaultUser => '目前為預設使用者，無法紀錄軌跡';

  @override
  String get emptyTrackDisabled => '軌跡紀錄功能已關閉，請在設定中開啟「遊戲軌跡紀錄」';

  @override
  String get emptyGameTrack => '尚無軌跡紀錄';

  @override
  String get tooltipDeleteRecord => '刪除紀錄';

  @override
  String labelTrackCount(int count) {
    return '共 $count 筆紀錄';
  }

  @override
  String get gameTrackChart => '軌跡圖表';

  @override
  String labelChartRange(String start, String end) {
    return '起始 $start\n截止 $end';
  }

  @override
  String get emptyChartNeedTwoRecords => '至少需要兩筆軌跡紀錄';

  @override
  String labelChartDownsampled(int total, int shown) {
    return '已壓縮顯示：共 $total 筆，顯示 $shown 筆';
  }

  @override
  String get totalEconomy => '總經濟';

  @override
  String get metricIndex => '指數';

  @override
  String get dialogConfirmApplyIncome => '確認填入收益';

  @override
  String dialogApplyGabBonusContent(String from, String to) {
    return '金掛收益：$from% -> $to%？';
  }

  @override
  String snackAppliedGabBonus(String value) {
    return '已填入金掛平均收益 $value%';
  }

  @override
  String get actionConfirm => '確認';

  @override
  String get actionReset => '重設';

  @override
  String get dialogResetIncomeSamples => '確認清除目前使用者的所有收入樣本？';

  @override
  String get emptyIncomeSamples => '尚無收入樣本';

  @override
  String get labelGabCost => '金掛成本';

  @override
  String get labelAverageIncome => '平均收入';

  @override
  String get labelPercent => '百分比';

  @override
  String get actionFillIn => '填入';

  @override
  String get dialogInputWaveIncome => '輸入每波金幣收入';

  @override
  String get labelWaveGoldIncome => '每波金幣收入';

  @override
  String get tooltipInfo => '提示';

  @override
  String get dialogIncomeNotice => '填寫「跳波狀態」後再填寫此處，否則計算結果不準確。\n\n此處計算結果為每日收入。';

  @override
  String get tabIncomeColony => '殖民地';

  @override
  String get tabIncomeWave => '推波';

  @override
  String get tabIncomeOther => '其他';

  @override
  String get labelColonyLevel => '殖民地等級';

  @override
  String get labelExtraColonyC => '額外殖民地C';

  @override
  String get labelExtraColonyG => '額外殖民地G';

  @override
  String get labelWheel => '車輪';

  @override
  String get labelWhip => '鞭子';

  @override
  String get labelGabAverageBonus => '金掛平均收益';

  @override
  String get labelDailyGabTime => '每日金掛時間';

  @override
  String get labelDailyTabTime => '每日時掛時間';

  @override
  String get labelSeasonColony => '賽季殖民地';

  @override
  String get labelGoldenTree => '金幣大樹';

  @override
  String get toolDragonSimulator => '刷龍模擬器';

  @override
  String get toolItemComparer => '裝備比較';

  @override
  String get toolBestLineCalc => '最佳裝備詞條組合';

  @override
  String get rankingKindPlayer => '個人排行榜';

  @override
  String get rankingKindGuild => '公會排行榜';

  @override
  String get rankingKindHell => '無盡排行榜';

  @override
  String get emptyRankingData => '尚無排行榜資料';

  @override
  String get emptyData => '尚無資料';

  @override
  String labelRankingTrend(String kind) {
    return '$kind趨勢';
  }

  @override
  String labelTopCount(int count) {
    return '前 $count';
  }

  @override
  String labelRankSummary(int count, String max, String min) {
    return '前 $count 名 · 最高 $max · 最低 $min';
  }

  @override
  String snackRefreshFailed(String reason) {
    return '重新整理失敗：$reason';
  }

  @override
  String dialogRankMilestones(String kind) {
    return '$kind名次';
  }

  @override
  String get tooltipViewScoreTrend => '檢視分數趨勢';

  @override
  String get tooltipViewMilestoneRanks => '檢視特殊名次';

  @override
  String get hintSelectPlayerDetail => '點擊左側項目檢視玩家詳情';

  @override
  String get actionRetry => '重試';

  @override
  String get snackNeedEnabledRule => '請先在「高亮規則」中啟用至少一條規則';

  @override
  String rollToHitHit(String count) {
    return '命中！共 roll 了 $count 次';
  }

  @override
  String rollToHitStopped(String count) {
    return '已手動停止，共 roll 了 $count 次';
  }

  @override
  String get labelItemSource => '裝備來源';

  @override
  String get labelHighestTierBonus => '最高品階掉落率加成';

  @override
  String get labelRollBatchSize => 'roll 單次數量';

  @override
  String get actionRollOnce => 'roll 單次';

  @override
  String get actionStop => '停止';

  @override
  String get actionRollToHit => 'roll 到死';

  @override
  String rollToHitRunning(String count) {
    return 'roll 到死進行中：已 roll $count 次…';
  }

  @override
  String get unnamedRule => '未命名規則';

  @override
  String get itemTypeBow => '弓';

  @override
  String get itemTypeSword => '劍';

  @override
  String get itemTypeStaff => '杖';

  @override
  String get itemTypeHammer => '錘';

  @override
  String get itemTypeRing => '戒指';

  @override
  String get itemTypeNecklace => '項鍊';

  @override
  String get itemTypeBracelet => '手鐲';

  @override
  String get itemTypeEarrings => '耳環';

  @override
  String get actionAddRule => '新增規則';

  @override
  String get emptyItemRuleHint => '尚無規則，點擊右下角新增';

  @override
  String get tooltipPinToTop => '命中後置頂';

  @override
  String get actionEdit => '編輯';

  @override
  String labelItemTypes(String types) {
    return '裝備類型：$types';
  }

  @override
  String get errorWhiteLinesWithRed => '已有紅色詞條，白色詞條最多 2 條';

  @override
  String get errorWhiteLinesMax => '白色詞條最多 3 條';

  @override
  String get errorRedWithThreeWhite => '白色詞條已達 3 條，不能選擇紅色詞條';

  @override
  String get errorNoLineSelected => '請至少選擇一個詞條';

  @override
  String get errorValueNotNumber => '數值需為數字或留空';

  @override
  String get errorMinGreaterThanMax => '下限（大於）必須小於上限（小於）';

  @override
  String errorMinOutOfRange(String line, String min, String max) {
    return '「$line」的下限超出 roll 值範圍（$min ~ $max）';
  }

  @override
  String errorMaxOutOfRange(String line, String min, String max) {
    return '「$line」的上限超出 roll 值範圍（$min ~ $max）';
  }

  @override
  String get titleEditRule => '編輯規則';

  @override
  String get labelHintText => '提示文字';

  @override
  String get hintRuleHintExample => '例如：紅白加強（可留空）';

  @override
  String get labelPinToTop => '命中後置頂顯示';

  @override
  String get labelSelectItemTypes => '指定裝備類型（不選則不限）';

  @override
  String get helpRuleForm =>
      '提示：紅/金詞條各最多選 1 條；白色詞條合計 3 條時不能選紅色詞條；\n輸入數值範圍時，判斷的是詞條原始值（加強前的值），留空表示不限。\n\n大於下限必須小於上限；輸入值還需在詞條的允許範圍內。';

  @override
  String labelLineCount(int count) {
    return '$count 條';
  }

  @override
  String get lineColorWhite => '白詞條';

  @override
  String get lineColorRed => '紅詞條';

  @override
  String get lineColorGold => '金詞條';

  @override
  String get lineColorPurple => '紫詞條';

  @override
  String labelItemLines(int index) {
    return '裝備 $index 詞條';
  }

  @override
  String get dialogItemCompareHelpIntro => '此工具用於比較兩件裝備的期望值。\n\n';

  @override
  String get dialogItemCompareHelpStepsTitle => '使用步驟：\n';

  @override
  String get dialogItemCompareHelpStep1 =>
      '1. 確認需要比較的裝備 / 寶珠 / 寶物欄位，然後將對應的物品卸下，依此時的面板填寫「無裝備面板」資料；\n';

  @override
  String get dialogItemCompareHelpStep2 => '2. 將兩件裝備的白詞條填寫到「裝備 1 / 裝備 2」中，';

  @override
  String get dialogItemCompareHelpStep2Note =>
      '請注意詞條類型，元素傷害統一併入 \"Element Damage\"，請自行依單位屬性填入對應元素傷害詞條；\n';

  @override
  String get dialogItemCompareHelpStep3 => '3. 比較結果：即時顯示三組 DPS 結果，並給出結論。\n\n\n';

  @override
  String get dialogItemCompareHelpNormalUnit => '普攻型單位：';

  @override
  String get dialogItemCompareHelpNormalUnitDesc =>
      '需要填寫 Attacks Per Second 和 Increased Speed，Attack Speed % 詞條參與計算。\n';

  @override
  String get dialogItemCompareHelpSkillUnit => '技能型單位：';

  @override
  String get dialogItemCompareHelpSkillUnitDesc =>
      '不填寫上述兩項，Attack Speed % 詞條不參與計算。';

  @override
  String get dialogItemCompareHelpNoteLabel => '\n\n註：';

  @override
  String get dialogItemCompareHelpNoteDesc => '寶珠、寶物等詞條也可用於計算，但需要注意詞條類型。';

  @override
  String get dialogResetConfirm => '是否清除所有輸入？';

  @override
  String get labelNoItemPanel => '無裝備面板';

  @override
  String get actionAddLine => '新增詞條';

  @override
  String get hintSelectLineType => '選擇詞條類型';

  @override
  String get hintValue => '數值';

  @override
  String get tooltipDeleteLine => '刪除詞條';

  @override
  String get labelNoCrit => '無爆擊';

  @override
  String get labelWithCrit => '有爆擊';

  @override
  String get labelNoItem => '無裝備';

  @override
  String labelItemNumber(int index) {
    return '裝備 $index';
  }

  @override
  String labelCompareGainSummary(String gain1, String gain2) {
    return '裝備 1 較無裝備 $gain1 · 裝備 2 較無裝備 $gain2';
  }

  @override
  String get compareVerdictPending => '填寫資料後自動比較';

  @override
  String compareVerdictItem1(String gap) {
    return '裝備 1 較佳$gap';
  }

  @override
  String compareGapItem2(String gain) {
    return '，DPS 比裝備 2 高 $gain';
  }

  @override
  String compareVerdictItem2(String gap) {
    return '裝備 2 較佳$gap';
  }

  @override
  String compareGapItem1(String gain) {
    return '，DPS 比裝備 1 高 $gain';
  }

  @override
  String get compareVerdictTie => '兩件裝備 DPS 相同';

  @override
  String get labelNoDamageLines => '（無輸出詞條）';

  @override
  String get dialogBestLineHelpAvgDmg =>
      'Avg. Dmg 和下方列表中的 Damage 都是 Damage 與 Elemental Damage 的平均值。';

  @override
  String get labelPanelWithoutItem => '面板無裝備數值';

  @override
  String labelLineSlot(int count) {
    return '$count 詞條';
  }

  @override
  String labelComboCount(int count) {
    return '共 $count 種';
  }

  @override
  String get gameTrack => '遊戲軌跡';

  @override
  String snackSyncFailed(String reason) {
    return '同步失敗：$reason';
  }

  @override
  String errorGuildNotFound(String name) {
    return '找不到公會「$name」的資訊';
  }

  @override
  String get emptyGuildDefaultUserHint =>
      '目前為預設使用者，僅供體驗基本功能。\n請至「設定」頁的「使用者管理」建立自己的帳號，並填寫公會名稱。';

  @override
  String get emptyGuildHint => '目前使用者未設定公會，請先至「使用者管理」填寫公會名稱';

  @override
  String get emptyGuildMembers => '該公會尚無成員';

  @override
  String get actionGoToUserManagement => '前往使用者管理';

  @override
  String get emptySelectMemberHint => '點擊左側成員檢視玩家詳情';

  @override
  String guildMemberCountAndScore(int count, String score) {
    return '$count 人 · $score';
  }

  @override
  String get tooltipCloseDetail => '關閉詳情';

  @override
  String errorPlayerBanned(String name) {
    return '玩家「$name」已被封鎖';
  }

  @override
  String get labelWphHistory => '每小時波速（第三方 API）';

  @override
  String labelSeason(String season) {
    return '賽季 $season';
  }

  @override
  String get endlessScore => '無盡分數';

  @override
  String get lastOnline => '上次線上';

  @override
  String unitEnabledCount(int enabled, int total) {
    return '$enabled/$total 啟用';
  }

  @override
  String get metricGoldShare => '金幣佔比';

  @override
  String get metricUnitPerWave => '單位 / 波數';

  @override
  String get metricWavePerUnit => '波數 / 單位';

  @override
  String get seasonProgress => '賽季進度';

  @override
  String get labelStart => '開始';

  @override
  String get labelEnd => '結束';

  @override
  String get labelRemaining => '剩餘';

  @override
  String get incomeTotal => '總收入';
}
