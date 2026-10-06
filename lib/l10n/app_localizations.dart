import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// 第 0 个 tab 名（底部导航 / 侧边栏），同时用作阵容页 AppBar 标题
  ///
  /// In zh, this message translates to:
  /// **'阵容'**
  String get tabFormation;

  /// No description provided for @emptyFormationHint.
  ///
  /// In zh, this message translates to:
  /// **'暂无条目，点击右上角 + 添加'**
  String get emptyFormationHint;

  /// No description provided for @tooltipAddEntry.
  ///
  /// In zh, this message translates to:
  /// **'新增条目'**
  String get tooltipAddEntry;

  /// No description provided for @tooltipInputMode.
  ///
  /// In zh, this message translates to:
  /// **'输入模式'**
  String get tooltipInputMode;

  /// No description provided for @tooltipViewMode.
  ///
  /// In zh, this message translates to:
  /// **'查看模式'**
  String get tooltipViewMode;

  /// 手动查询当前用户赛季数据的按钮，阵容页 AppBar 与汇总条各一处
  ///
  /// In zh, this message translates to:
  /// **'拉取数据'**
  String get tooltipFetchData;

  /// No description provided for @snackQueryTooFrequent.
  ///
  /// In zh, this message translates to:
  /// **'查询过于频繁，请稍后后再试'**
  String get snackQueryTooFrequent;

  /// No description provided for @snackUserBanned.
  ///
  /// In zh, this message translates to:
  /// **'用户「{name}」已被封禁'**
  String snackUserBanned(String name);

  /// 波数由调用方格式化好后传入（千分位在不同语言下一致）
  ///
  /// In zh, this message translates to:
  /// **'数据获取成功：用户「{name}」, 波数 {wave}, 赛季波数 {seasonWave}'**
  String snackQuerySuccess(String name, String wave, String seasonWave);

  /// No description provided for @snackQueryFailed.
  ///
  /// In zh, this message translates to:
  /// **'查询失败：{reason}'**
  String snackQueryFailed(String reason);

  /// No description provided for @errorSeasonDataNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到「{name}」的赛季数据'**
  String errorSeasonDataNotFound(String name);

  /// No description provided for @errorQueryTimeout.
  ///
  /// In zh, this message translates to:
  /// **'查询超时，请稍后重试'**
  String get errorQueryTimeout;

  /// No description provided for @totalWave.
  ///
  /// In zh, this message translates to:
  /// **'总波数'**
  String get totalWave;

  /// No description provided for @seasonWave.
  ///
  /// In zh, this message translates to:
  /// **'赛季波数'**
  String get seasonWave;

  /// No description provided for @totalGold.
  ///
  /// In zh, this message translates to:
  /// **'总金币'**
  String get totalGold;

  /// No description provided for @goldPower.
  ///
  /// In zh, this message translates to:
  /// **'GP · 指数'**
  String get goldPower;

  /// No description provided for @ranking.
  ///
  /// In zh, this message translates to:
  /// **'排名'**
  String get ranking;

  /// No description provided for @tooltipEditTotalWave.
  ///
  /// In zh, this message translates to:
  /// **'修改总波数'**
  String get tooltipEditTotalWave;

  /// No description provided for @tooltipEditSeasonWave.
  ///
  /// In zh, this message translates to:
  /// **'修改赛季波数'**
  String get tooltipEditSeasonWave;

  /// No description provided for @dialogSetTotalWave.
  ///
  /// In zh, this message translates to:
  /// **'设置总波数'**
  String get dialogSetTotalWave;

  /// No description provided for @dialogSetSeasonWave.
  ///
  /// In zh, this message translates to:
  /// **'设置赛季波数'**
  String get dialogSetSeasonWave;

  /// No description provided for @metricShare.
  ///
  /// In zh, this message translates to:
  /// **'占比'**
  String get metricShare;

  /// No description provided for @metricOneOverRatio.
  ///
  /// In zh, this message translates to:
  /// **'1/比例'**
  String get metricOneOverRatio;

  /// No description provided for @metricRatio.
  ///
  /// In zh, this message translates to:
  /// **'比例'**
  String get metricRatio;

  /// No description provided for @unitNameCastle.
  ///
  /// In zh, this message translates to:
  /// **'城堡'**
  String get unitNameCastle;

  /// 内置卡片 id=2 的默认名；英文取 Town Archer 的简写
  ///
  /// In zh, this message translates to:
  /// **'城弓'**
  String get unitNameCastleBow;

  /// No description provided for @unitNameGeneric.
  ///
  /// In zh, this message translates to:
  /// **'单位 {id}'**
  String unitNameGeneric(int id);

  /// No description provided for @nameLabelCastle.
  ///
  /// In zh, this message translates to:
  /// **'城堡名称'**
  String get nameLabelCastle;

  /// No description provided for @nameLabelCastleBow.
  ///
  /// In zh, this message translates to:
  /// **'城弓名称'**
  String get nameLabelCastleBow;

  /// No description provided for @nameLabelGeneric.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get nameLabelGeneric;

  /// No description provided for @labelLevel.
  ///
  /// In zh, this message translates to:
  /// **'等级'**
  String get labelLevel;

  /// No description provided for @tooltipActions.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get tooltipActions;

  /// No description provided for @actionApplied.
  ///
  /// In zh, this message translates to:
  /// **'已应用'**
  String get actionApplied;

  /// No description provided for @actionNotApplied.
  ///
  /// In zh, this message translates to:
  /// **'未应用'**
  String get actionNotApplied;

  /// No description provided for @actionClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get actionClear;

  /// No description provided for @actionDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get actionDelete;

  /// No description provided for @actionCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get actionSave;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get languageSystem;

  /// 语言选项一律用该语言自身的写法，两个 arb 里保持一致
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// 语言选项一律用该语言自身的写法；本 key 供简体/英文界面显示「繁體中文」这一项
  ///
  /// In zh, this message translates to:
  /// **'繁體中文'**
  String get languageTraditionalChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// 装备掉落来源名（ItemSource.label），显示在龙模拟器的来源下拉里。英文社区叫法我拿不准，先用 Dragon N　位置：lib/core/src/item_lines.dart:42
  ///
  /// In zh, this message translates to:
  /// **'一龙'**
  String get itemSourceDragon1;

  /// 位置：lib/core/src/item_lines.dart:43
  ///
  /// In zh, this message translates to:
  /// **'二龙'**
  String get itemSourceDragon2;

  /// 位置：lib/core/src/item_lines.dart:44
  ///
  /// In zh, this message translates to:
  /// **'三龙'**
  String get itemSourceDragon3;

  /// 位置：lib/core/src/item_lines.dart:45
  ///
  /// In zh, this message translates to:
  /// **'四龙'**
  String get itemSourceDragon4;

  /// 位置：lib/core/src/item_lines.dart:46
  ///
  /// In zh, this message translates to:
  /// **'五龙'**
  String get itemSourceDragon5;

  /// 位置：lib/core/src/item_lines.dart:47
  ///
  /// In zh, this message translates to:
  /// **'六龙'**
  String get itemSourceDragon6;

  /// No description provided for @itemSourceDragon7.
  ///
  /// In zh, this message translates to:
  /// **'七龙'**
  String get itemSourceDragon7;

  /// 位置：lib/core/service/webdav_backup_client.dart:177
  ///
  /// In zh, this message translates to:
  /// **'账号或密码错误（HTTP 401）'**
  String get webdavAuthFailed;

  /// 位置：lib/core/service/webdav_backup_client.dart:179
  ///
  /// In zh, this message translates to:
  /// **'没有访问权限（HTTP 403）'**
  String get webdavForbidden;

  /// 位置：lib/core/service/webdav_backup_client.dart:181
  ///
  /// In zh, this message translates to:
  /// **'云端还没有备份文件'**
  String get webdavNoBackupFile;

  /// 位置：lib/core/service/webdav_backup_client.dart:183
  ///
  /// In zh, this message translates to:
  /// **'服务器不支持该操作（HTTP 405）'**
  String get webdavMethodNotAllowed;

  /// 位置：lib/core/service/webdav_backup_client.dart:185
  ///
  /// In zh, this message translates to:
  /// **'服务器返回错误（HTTP {status}）'**
  String webdavServerError(String status);

  /// 位置：lib/core/service/webdav_backup_client.dart:197
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务器，请检查网络与 WebDAV 地址'**
  String get webdavUnreachable;

  /// 位置：lib/core/service/data_archive.dart:140
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件（JSON 解析失败）'**
  String get archiveInvalidJson;

  /// 位置：lib/core/service/data_archive.dart:143
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件'**
  String get archiveInvalid;

  /// 位置：lib/core/service/data_archive.dart:149
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件（缺少版本信息）'**
  String get archiveMissingVersion;

  /// 位置：lib/core/service/data_archive.dart:153
  ///
  /// In zh, this message translates to:
  /// **'该备份由更新版本的应用创建，请先升级应用后再导入'**
  String get archiveNewerVersion;

  /// 位置：lib/core/service/data_archive.dart:157
  ///
  /// In zh, this message translates to:
  /// **'不支持该备份文件版本'**
  String get archiveUnsupportedVersion;

  /// 位置：lib/core/service/data_archive.dart:162
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件（缺少数据内容）'**
  String get archiveMissingData;

  /// 位置：lib/core/service/backup_service.dart:125, lib/core/service/backup_service.dart:204
  ///
  /// In zh, this message translates to:
  /// **'已有备份任务进行中，请稍后再试'**
  String get backupBusy;

  /// 位置：lib/core/service/backup_service.dart:132, lib/core/service/backup_service.dart:157
  ///
  /// In zh, this message translates to:
  /// **'备份失败，请稍后重试'**
  String get backupFailed;

  /// 位置：lib/core/service/backup_service.dart:148
  ///
  /// In zh, this message translates to:
  /// **'请先配置 WebDAV 服务器地址、账号与密码'**
  String get backupNotConfigured;

  /// 位置：lib/core/service/backup_service.dart:212
  ///
  /// In zh, this message translates to:
  /// **'文件中不包含可恢复的数据'**
  String get backupNoRestorableData;

  /// 位置：lib/core/service/backup_service.dart:227
  ///
  /// In zh, this message translates to:
  /// **'用户数据'**
  String get dataSectionUserData;

  /// 位置：lib/core/service/backup_service.dart:236, lib/core/service/backup_service.dart:247
  ///
  /// In zh, this message translates to:
  /// **'用户元数据'**
  String get dataSectionUserMeta;

  /// 位置：lib/core/service/backup_service.dart:263
  ///
  /// In zh, this message translates to:
  /// **'应用设置'**
  String get dataSectionAppSettings;

  /// 高亮规则管理页标题 / tooltip，以及备份恢复失败列表里的分段名
  ///
  /// In zh, this message translates to:
  /// **'高亮规则'**
  String get highlightRules;

  /// sections 由调用方按语言用分隔符拼好（中文「、」，英文「, 」）　位置：lib/core/service/backup_service.dart:290
  ///
  /// In zh, this message translates to:
  /// **'以下数据恢复失败：{sections}'**
  String backupRestorePartialFailure(String sections);

  /// 中文顿号 / 英文逗号+空格，用于拼接并列的数据段名　位置：lib/core/service/backup_service.dart:290
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get listSeparator;

  /// 赛季剩余时间格式化函数在赛季结束后的返回值，显示在赛季指示器上　位置：lib/core/service/api.dart:544
  ///
  /// In zh, this message translates to:
  /// **'已结束'**
  String get seasonEnded;

  /// 底部导航第 2 项 + 功能页 AppBar 标题；main_pages.dart:37 的 TODO(l10n) 已预留此 key 名（title: (l10n) => l10n.tabFunction）。备选 Function / Data：Function 在英文里偏编程味，Data 太泛，倾向 Features。　位置：lib/view/page/function_page.dart:42
  ///
  /// In zh, this message translates to:
  /// **'功能'**
  String get tabFunction;

  /// 底部导航第 3 项，代码 TODO 已指名该 key。　位置：lib/view/shell/main_pages.dart:44
  ///
  /// In zh, this message translates to:
  /// **'公会'**
  String get tabGuild;

  /// 与 tabFormation 同策略：既是底部导航/侧边栏 tab 名，也是工具页 AppBar 标题　位置：lib/view/page/tools_page.dart:15
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get tabTools;

  /// 同时用作底部导航项与设置页 AppBar 标题（与 tabFormation 的既有用法一致）。　位置：lib/view/shell/main_pages.dart:58, lib/view/page/setting_page.dart:181
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabSettings;

  /// 位置：lib/view/page/setting_page.dart:46
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败，请检查网络后重试'**
  String get snackUpdateCheckFailed;

  /// 原文 '已是最新版本 v$current' 为拼接，版本号含 v 前缀；en 里 v 保留在括号内。　位置：lib/view/page/setting_page.dart:53
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本 v{version}'**
  String snackAlreadyLatest(String version);

  /// 位置：lib/view/page/setting_page.dart:63
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get dialogUpdateAvailable;

  /// 原文是两个字面量拼接（current 为 null 时省略整个括号），故合并为一条 select 词条，调用时 hasCurrent 传 'yes'/'no'。若不想用 select，可拆成「含当前版本」与「不含」两条 key。　位置：lib/view/page/setting_page.dart:70, lib/view/page/setting_page.dart:71
  ///
  /// In zh, this message translates to:
  /// **'{hasCurrent, select, yes{最新版本 {latest}（当前 v{current}）} other{最新版本 {latest}}}'**
  String dialogUpdateAvailableBody(
    String hasCurrent,
    String latest,
    String current,
  );

  /// 冒号在 zh 为全角、en 为半角，已一并写进词条。　位置：lib/view/page/setting_page.dart:79
  ///
  /// In zh, this message translates to:
  /// **'更新日志：'**
  String get labelChangelog;

  /// 位置：lib/view/page/setting_page.dart:100
  ///
  /// In zh, this message translates to:
  /// **'打开发布页'**
  String get actionOpenReleasePage;

  /// 设置页与关于页各一处，同一个 key。　位置：lib/view/page/setting_page.dart:113, lib/view/page/setting/about_page.dart:257
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接：{url}'**
  String snackCannotOpenLink(String url);

  /// 设置页开关标题 + 编辑弹窗标题 + 关于页说明弹窗标题，三处同一概念，务必复用同一 key。　位置：lib/view/page/setting_page.dart:122, lib/view/page/setting_page.dart:277, lib/view/page/setting/about_page.dart:46
  ///
  /// In zh, this message translates to:
  /// **'第三方 API'**
  String get settingsThirdPartyApi;

  /// 设置页条目标题与编辑弹窗 label 同一串。备选译法 API address。　位置：lib/view/page/setting_page.dart:124, lib/view/page/setting_page.dart:303
  ///
  /// In zh, this message translates to:
  /// **'API 地址'**
  String get labelApiUrl;

  /// 弹窗标题与设置条目标题同一串。备选 Concurrent queries。　位置：lib/view/page/setting_page.dart:135, lib/view/page/setting_page.dart:352
  ///
  /// In zh, this message translates to:
  /// **'查询并发数'**
  String get settingsQueryConcurrency;

  /// 输入框 label；helperText '1-10' 为纯数字符号，未收（见报告）。　位置：lib/view/page/setting_page.dart:140
  ///
  /// In zh, this message translates to:
  /// **'并发数'**
  String get labelConcurrency;

  /// helperText '1-43200' 为纯数字，未收。　位置：lib/view/page/setting_page.dart:160
  ///
  /// In zh, this message translates to:
  /// **'记录间隔'**
  String get settingsTrackInterval;

  /// 输入框 label（单位）。　位置：lib/view/page/setting_page.dart:165
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get labelMinutes;

  /// 设置条目标题 + 选用户页 AppBar 标题，同一 key。　位置：lib/view/page/setting_page.dart:186, lib/view/page/public/select_user_page.dart:29
  ///
  /// In zh, this message translates to:
  /// **'用户管理'**
  String get settingsUserManagement;

  /// 术语表给的对应词是 theme；若想保留 mode 语义可用 Theme mode。　位置：lib/view/page/setting_page.dart:201
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get settingsThemeMode;

  /// 主题分段按钮。与已有的 languageSystem（zh 为「跟随系统」）不是同一串，不能复用。　位置：lib/view/page/setting_page.dart:212
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get themeSystem;

  /// 位置：lib/view/page/setting_page.dart:217
  ///
  /// In zh, this message translates to:
  /// **'亮色'**
  String get themeLight;

  /// 位置：lib/view/page/setting_page.dart:222
  ///
  /// In zh, this message translates to:
  /// **'暗色'**
  String get themeDark;

  /// 「波速」不在术语表内，暂译 wave speed（波=wave），请拍板。　位置：lib/view/page/setting_page.dart:278
  ///
  /// In zh, this message translates to:
  /// **'玩家详情页获取波速信息'**
  String get settingsThirdPartyApiSubtitle;

  /// 术语表：上次在线 last online。　位置：lib/view/page/setting_page.dart:329
  ///
  /// In zh, this message translates to:
  /// **'自动查询上次在线'**
  String get settingsAutoLastOnline;

  /// 原文用的是半角直引号 "（不是「」），zh 原样保留；en 保持同款直引号。　位置：lib/view/page/setting_page.dart:330
  ///
  /// In zh, this message translates to:
  /// **'公会详情页查询成员\"上次在线\"'**
  String get settingsAutoLastOnlineSubtitle;

  /// 游戏轨迹页 game_track_page.dart:137 也复述了这串文案（见报告线索），建议一并复用该 key。　位置：lib/view/page/setting_page.dart:374
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹记录'**
  String get settingsGameTrack;

  /// 位置：lib/view/page/setting_page.dart:375
  ///
  /// In zh, this message translates to:
  /// **'记录个人数据变化'**
  String get settingsGameTrackSubtitle;

  /// 位置：lib/view/page/setting_page.dart:399
  ///
  /// In zh, this message translates to:
  /// **'轨迹记录最小间隔'**
  String get settingsGameTrackMinInterval;

  /// 原文 '$minutes 分钟' 为拼接。en 用 min 避免单复数问题；若想写全 minutes 需用 ICU plural（1 minute / N minutes）。　位置：lib/view/page/setting_page.dart:400
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String settingsGameTrackIntervalValue(int minutes);

  /// 设置条目标题 + 备份页 AppBar 标题。　位置：lib/view/page/setting_page.dart:416, lib/view/page/setting/backup_page.dart:50
  ///
  /// In zh, this message translates to:
  /// **'数据备份'**
  String get settingsDataBackup;

  /// 分隔符是 ' · '（空格点空格），不是中文顿号。　位置：lib/view/page/setting_page.dart:417
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 云备份 · 本地导入导出'**
  String get settingsDataBackupSubtitle;

  /// 术语表；设置条目标题。　位置：lib/view/page/setting_page.dart:429
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get settingsCheckUpdate;

  /// 原文 '当前版本 v$_currentVersion' 为拼接。　位置：lib/view/page/setting_page.dart:432
  ///
  /// In zh, this message translates to:
  /// **'当前版本 v{version}'**
  String settingsCurrentVersion(String version);

  /// 设置条目标题 + 关于页 AppBar 标题。　位置：lib/view/page/setting_page.dart:444, lib/view/page/setting/about_page.dart:124
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// 指本应用适配的游戏版本（副标题 v1.50.14 是硬编码字面量，未收）。备选 Compatible with / Game version。　位置：lib/view/page/setting/about_page.dart:30
  ///
  /// In zh, this message translates to:
  /// **'适配版本'**
  String get aboutAdaptedVersion;

  /// 链接类条目标题；备选 Documentation / How to use。　位置：lib/view/page/setting/about_page.dart:36
  ///
  /// In zh, this message translates to:
  /// **'使用说明'**
  String get aboutGuide;

  /// 位置：lib/view/page/setting/about_page.dart:41
  ///
  /// In zh, this message translates to:
  /// **'第三方 API 说明'**
  String get aboutThirdPartyApiInfo;

  /// 位置：lib/view/page/setting/about_page.dart:42
  ///
  /// In zh, this message translates to:
  /// **'当查询内容为空时，请查看这里'**
  String get aboutThirdPartyApiInfoSubtitle;

  /// 四段换行文案，URL 与空行原样保留；en 行数较多，弹窗宽度有限，必要时可略作压缩。　位置：lib/view/page/setting/about_page.dart:48
  ///
  /// In zh, this message translates to:
  /// **'默认第三方 API (https://fnxag.eu.org/gcapi) 由开发者维护。\n只有部分玩家在记录范围中，如果有需要，可联系开发者添加。\n需要使用其他 API 时，可以自行创建。\n\n注意：该 API 与本应用无任何直接联系，请自行判断是否使用。'**
  String get dialogThirdPartyApiBody;

  /// 同一中文还出现在 lib/view/widget/season_indicator.dart:133（别的分组），建议共用本 key；备选 OK。　位置：lib/view/page/function/game_track_page.dart:106
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get actionGotIt;

  /// 位置：lib/view/page/setting/about_page.dart:73
  ///
  /// In zh, this message translates to:
  /// **'GitHub 仓库'**
  String get aboutGithubRepo;

  /// en 较长，条目 subtitle 位置可能换行。　位置：lib/view/page/setting/about_page.dart:79
  ///
  /// In zh, this message translates to:
  /// **'原项目 GitHub 仓库'**
  String get aboutOriginalGithubRepo;

  /// 位置：lib/view/page/setting/about_page.dart:85
  ///
  /// In zh, this message translates to:
  /// **'QQ 群'**
  String get aboutQqGroup;

  /// 位置：lib/view/page/setting/about_page.dart:91
  ///
  /// In zh, this message translates to:
  /// **'开发者邮箱'**
  String get aboutDeveloperEmail;

  /// 位置：lib/view/page/setting/about_page.dart:101
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get aboutOpenSourceLicenses;

  /// 同一行的标题 'LICENSE' 已是英文，未收。　位置：lib/view/page/setting/about_page.dart:116
  ///
  /// In zh, this message translates to:
  /// **'本应用遵循 GNU GPL-3.0 开源协议'**
  String get aboutLicenseNotice;

  /// SectionHeader 分区标题，关于页与备份页共用；备选 Notes。　位置：lib/view/page/setting/about_page.dart:128, lib/view/page/setting/backup_page.dart:96
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get sectionInfo;

  /// 位置：lib/view/page/setting/about_page.dart:130
  ///
  /// In zh, this message translates to:
  /// **'链接'**
  String get sectionLinks;

  /// 备选 Legal。　位置：lib/view/page/setting/about_page.dart:132
  ///
  /// In zh, this message translates to:
  /// **'授权'**
  String get sectionLicenses;

  /// 游戏名 Grow Castle 不译；备选 Grow Castle helper。　位置：lib/view/page/setting/about_page.dart:171
  ///
  /// In zh, this message translates to:
  /// **'Grow Castle 辅助工具'**
  String get aboutTagline;

  /// 位置：lib/view/page/setting/backup_page.dart:53
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 备份'**
  String get sectionWebdavBackup;

  /// 术语表；条目可点，实为动作入口。　位置：lib/view/page/setting/backup_page.dart:63
  ///
  /// In zh, this message translates to:
  /// **'立即备份'**
  String get actionBackupNow;

  /// en 较长，subtitle 单行可能省略号截断。　位置：lib/view/page/setting/backup_page.dart:65
  ///
  /// In zh, this message translates to:
  /// **'检查云端新旧后上传覆盖'**
  String get backupNowSubtitleReady;

  /// 与 labelNotSet（未设置）是不同串，不要合并。　位置：lib/view/page/setting/backup_page.dart:65
  ///
  /// In zh, this message translates to:
  /// **'未配置服务器'**
  String get backupServerNotConfigured;

  /// 术语表；条目标题兼覆盖确认弹窗外层标题（同一串）。　位置：lib/view/page/setting/backup_page.dart:73, lib/view/page/setting/backup_page.dart:404
  ///
  /// In zh, this message translates to:
  /// **'从云端恢复'**
  String get actionRestoreFromCloud;

  /// 位置：lib/view/page/setting/backup_page.dart:74
  ///
  /// In zh, this message translates to:
  /// **'下载云端备份并覆盖本机数据'**
  String get backupRestoreSubtitle;

  /// 位置：lib/view/page/setting/backup_page.dart:83
  ///
  /// In zh, this message translates to:
  /// **'本地文件'**
  String get sectionLocalFiles;

  /// 术语表。　位置：lib/view/page/setting/backup_page.dart:86
  ///
  /// In zh, this message translates to:
  /// **'导出到文件'**
  String get actionExportToFile;

  /// 位置：lib/view/page/setting/backup_page.dart:87
  ///
  /// In zh, this message translates to:
  /// **'把全部数据保存为本地文件'**
  String get backupExportSubtitle;

  /// 术语表；条目标题与导入确认弹窗标题同一串。　位置：lib/view/page/setting/backup_page.dart:92, lib/view/page/setting/backup_page.dart:497
  ///
  /// In zh, this message translates to:
  /// **'导入文件'**
  String get actionImportFile;

  /// 位置：lib/view/page/setting/backup_page.dart:93
  ///
  /// In zh, this message translates to:
  /// **'从本地文件恢复数据'**
  String get backupImportSubtitle;

  /// 页面说明区与确认弹窗正文里是同一串，务必复用同一个 key。　位置：lib/view/page/setting/backup_page.dart:100, lib/view/page/setting/backup_page.dart:522
  ///
  /// In zh, this message translates to:
  /// **'导入或恢复会覆盖本机全部数据，建议先导出备份。'**
  String get backupOverwriteHint;

  /// 条目标题与编辑弹窗标题同一串。　位置：lib/view/page/setting/backup_page.dart:127, lib/view/page/setting/backup_page.dart:202
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get labelServerAddress;

  /// 服务器地址/账号/密码三行副标题的占位值；密码为空时显示的 '••••••' 为纯符号，未收。　位置：lib/view/page/setting/backup_page.dart:128, lib/view/page/setting/backup_page.dart:138, lib/view/page/setting/backup_page.dart:148
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get labelNotSet;

  /// 条目标题与编辑弹窗标题同一串；与 labelUsername（用户名）区分。　位置：lib/view/page/setting/backup_page.dart:137, lib/view/page/setting/backup_page.dart:217
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get labelAccount;

  /// 位置：lib/view/page/setting/backup_page.dart:147, lib/view/page/setting/backup_page.dart:230
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get labelPassword;

  /// 输入框 label，比条目标题多 WebDAV 前缀，不能与 labelAccount 合并。　位置：lib/view/page/setting/backup_page.dart:219
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 账号'**
  String get labelWebdavAccount;

  /// 位置：lib/view/page/setting/backup_page.dart:232
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 密码'**
  String get labelWebdavPassword;

  /// 输入框 label 兼示例，只有「目录」是中文；en 用 folder（若想保持 URL 风味可用 directory）。　位置：lib/view/page/setting/backup_page.dart:205
  ///
  /// In zh, this message translates to:
  /// **'https://dav.example.com/dav/目录'**
  String get labelServerUrlExample;

  /// 原文为 time==null ? '上次成功备份：从未' : '…：{时间}'。建议把「从未」也做成词条 labelNever，调用方在无记录时把它当 {time} 传入（译文即为 Last successful backup: Never）。　位置：lib/view/page/setting/backup_page.dart:178, lib/view/page/setting/backup_page.dart:179
  ///
  /// In zh, this message translates to:
  /// **'上次成功备份：{time}'**
  String backupLastSuccess(String time);

  /// 作为备份时间占位值使用（两处：上次成功备份、本机上次成功备份）。若不用占位值方案，则需要把这两处各写成 select 词条。　位置：lib/view/page/setting/backup_page.dart:178, lib/view/page/setting/backup_page.dart:300
  ///
  /// In zh, this message translates to:
  /// **'从未'**
  String get labelNever;

  /// 「备份时间：未知」里的取值，同样建议做占位值。　位置：lib/view/page/setting/backup_page.dart:561
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get labelUnknown;

  /// 云端备份行的 {time} 位在取不到时间时用它；与 labelUnknown（未知）是不同串。　位置：lib/view/page/setting/backup_page.dart:582
  ///
  /// In zh, this message translates to:
  /// **'时间未知'**
  String get labelTimeUnknown;

  /// 原文为拼接：'上次备份失败：$error' + 可选的 '（时间）'。用 select 合并成一条；error 来自服务层（可能含中文，见报告线索）。　位置：lib/view/page/setting/backup_page.dart:184, lib/view/page/setting/backup_page.dart:185
  ///
  /// In zh, this message translates to:
  /// **'{hasTime, select, yes{上次备份失败：{error}（{time}）} other{上次备份失败：{error}}}'**
  String backupLastFailed(String hasTime, String error, String time);

  /// 位置：lib/view/page/setting/backup_page.dart:264
  ///
  /// In zh, this message translates to:
  /// **'已备份到云端'**
  String get snackBackupSuccess;

  /// 位置：lib/view/page/setting/backup_page.dart:264
  ///
  /// In zh, this message translates to:
  /// **'备份失败：{error}'**
  String snackBackupFailed(String error);

  /// 位置：lib/view/page/setting/backup_page.dart:274
  ///
  /// In zh, this message translates to:
  /// **'检测云端备份失败：{reason}'**
  String snackRemoteProbeFailed(String reason);

  /// 位置：lib/view/page/setting/backup_page.dart:277
  ///
  /// In zh, this message translates to:
  /// **'检测云端备份失败，请稍后重试'**
  String get snackRemoteProbeFailedRetry;

  /// 位置：lib/view/page/setting/backup_page.dart:305
  ///
  /// In zh, this message translates to:
  /// **'上传备份到云端'**
  String get dialogUploadBackupTitle;

  /// 原文为拼接：'云端备份：时间' + 可选 '，N KB'（size 在 zh 里其实由整数除法算好后拼入）。用 select 合并；size 传算好的整数（原代码 ~/1024）。　位置：lib/view/page/setting/backup_page.dart:296, lib/view/page/setting/backup_page.dart:297
  ///
  /// In zh, this message translates to:
  /// **'{hasSize, select, yes{云端备份：{time}，{size} KB} other{云端备份：{time}}}'**
  String dialogCloudBackupLine(String hasSize, String time, String size);

  /// 位置：lib/view/page/setting/backup_page.dart:298
  ///
  /// In zh, this message translates to:
  /// **'云端备份：还没有备份文件（将新建一份）'**
  String get dialogCloudBackupNoFile;

  /// 与 backupLastSuccess 文案相近但不同串（多「本机」），不能合并；无记录时同样传 labelNever。　位置：lib/view/page/setting/backup_page.dart:300, lib/view/page/setting/backup_page.dart:301
  ///
  /// In zh, this message translates to:
  /// **'本机上次成功备份：{time}'**
  String dialogLastLocalBackupLine(String time);

  /// 与 actionRestoreFromCloud（从云端恢复）语义相同、zh 不同串。建议要么统一 zh 后合并成一个 key，要么保留本 key 并把 en 改成 Use cloud copy 以免与上一条完全重复。请拍板。　位置：lib/view/page/setting/backup_page.dart:330
  ///
  /// In zh, this message translates to:
  /// **'恢复云端'**
  String get actionRestoreRemote;

  /// 术语表；确认弹窗主按钮。　位置：lib/view/page/setting/backup_page.dart:342
  ///
  /// In zh, this message translates to:
  /// **'上传'**
  String get actionUpload;

  /// 按钮为错误色，en 略长，窄屏(手机)可能与「取消」挤压。　位置：lib/view/page/setting/backup_page.dart:344
  ///
  /// In zh, this message translates to:
  /// **'仍要覆盖'**
  String get actionOverwriteAnyway;

  /// 位置：lib/view/page/setting/backup_page.dart:345
  ///
  /// In zh, this message translates to:
  /// **'覆盖上传'**
  String get actionOverwriteUpload;

  /// 原文分两行拼接，注意「；」在 en 里换成 '; '；en 明显更长，弹窗会变高。　位置：lib/view/page/setting/backup_page.dart:360, lib/view/page/setting/backup_page.dart:361
  ///
  /// In zh, this message translates to:
  /// **'云端备份比本机上次成功备份更新，可能来自其他设备；覆盖后云端那份将无法找回。'**
  String get dialogWarningRemoteNewer;

  /// 位置：lib/view/page/setting/backup_page.dart:364
  ///
  /// In zh, this message translates to:
  /// **'无法获取云端备份时间；覆盖后云端那份将无法找回。'**
  String get dialogWarningRemoteTimeUnknown;

  /// 位置：lib/view/page/setting/backup_page.dart:367
  ///
  /// In zh, this message translates to:
  /// **'本机没有成功备份记录，无法确认云端那份的来源；覆盖后无法找回。'**
  String get dialogWarningLocalNoRecord;

  /// 原文是 List.join('，') 拼出来的「云端备份（时间），N KB」，且时间与大小都可缺。两个 select 拼一条；若团队不接受这种写法，可拆成 labelCloudBackup / labelSizeKb 两半由调用方拼（不推荐，分隔符是中文全角逗号）。　位置：lib/view/page/setting/backup_page.dart:400, lib/view/page/setting/backup_page.dart:401, lib/view/page/setting/backup_page.dart:402
  ///
  /// In zh, this message translates to:
  /// **'{hasTime, select, yes{云端备份（{time}）} other{云端备份}}{hasSize, select, yes{，{size} KB} other{}}'**
  String dialogRestoreCloudSource(
    String hasTime,
    String time,
    String hasSize,
    String size,
  );

  /// 位置：lib/view/page/setting/backup_page.dart:385
  ///
  /// In zh, this message translates to:
  /// **'获取云端备份失败：{reason}'**
  String snackFetchRemoteFailed(String reason);

  /// reason 来自 DataArchiveException，本身是中文（见报告线索）。　位置：lib/view/page/setting/backup_page.dart:387
  ///
  /// In zh, this message translates to:
  /// **'云端文件无效：{reason}'**
  String snackInvalidCloudFile(String reason);

  /// 原文用字符串拼接把「（时间）」夹进句中。若不想用 select，也可把 labelNever 当 {time} 传（会多出括号）。　位置：lib/view/page/setting/backup_page.dart:422, lib/view/page/setting/backup_page.dart:423, lib/view/page/setting/backup_page.dart:424
  ///
  /// In zh, this message translates to:
  /// **'{hasTime, select, yes{云端备份早于本机上次成功备份（{time}），恢复会退回较旧的数据。} other{云端备份早于本机上次成功备份，恢复会退回较旧的数据。}}'**
  String dialogWarningRestoreOlder(String hasTime, String time);

  /// 与 dialogWarningRemoteNewer 前段相同、结尾不同（无「覆盖后…」），保持两条 key。　位置：lib/view/page/setting/backup_page.dart:429
  ///
  /// In zh, this message translates to:
  /// **'云端备份比本机上次成功备份更新，可能来自其他设备。'**
  String get dialogWarningRestoreNewer;

  /// 位置：lib/view/page/setting/backup_page.dart:434
  ///
  /// In zh, this message translates to:
  /// **'无法判断云端备份与本机记录的新旧，恢复前请确认来源。'**
  String get dialogWarningRestoreUnknown;

  /// 位置：lib/view/page/setting/backup_page.dart:452
  ///
  /// In zh, this message translates to:
  /// **'导出失败，请稍后重试'**
  String get snackExportFailed;

  /// 系统文件保存对话框标题（dialogTitle），各平台是否显示取决于平台。　位置：lib/view/page/setting/backup_page.dart:467
  ///
  /// In zh, this message translates to:
  /// **'导出数据备份'**
  String get dialogTitleExportBackup;

  /// 位置：lib/view/page/setting/backup_page.dart:472
  ///
  /// In zh, this message translates to:
  /// **'已导出到文件'**
  String get snackExportSuccess;

  /// 系统文件选择对话框标题。　位置：lib/view/page/setting/backup_page.dart:478
  ///
  /// In zh, this message translates to:
  /// **'选择备份文件'**
  String get dialogTitlePickBackupFile;

  /// reason 来自 DataArchiveException（中文，见线索）。　位置：lib/view/page/setting/backup_page.dart:489
  ///
  /// In zh, this message translates to:
  /// **'文件无效：{reason}'**
  String snackInvalidFile(String reason);

  /// 位置：lib/view/page/setting/backup_page.dart:492
  ///
  /// In zh, this message translates to:
  /// **'读取文件失败，请确认是导出的备份文件'**
  String get snackReadFileFailed;

  /// 文件名可能很长，配合 dialogRestoreSource 显示，注意换行。　位置：lib/view/page/setting/backup_page.dart:498
  ///
  /// In zh, this message translates to:
  /// **'本机文件：{name}'**
  String dialogPickLocalFileSource(String name);

  /// 确认弹窗正文首行，后面用 '\n\n' 拼档案摘要与 backupOverwriteHint（调用方拼接，不改动）。　位置：lib/view/page/setting/backup_page.dart:520
  ///
  /// In zh, this message translates to:
  /// **'来源：{source}'**
  String dialogRestoreSource(String source);

  /// 位置：lib/view/page/setting/backup_page.dart:544
  ///
  /// In zh, this message translates to:
  /// **'覆盖恢复'**
  String get actionOverwriteRestore;

  /// 位置：lib/view/page/setting/backup_page.dart:552
  ///
  /// In zh, this message translates to:
  /// **'已恢复本地数据'**
  String get snackRestoreSuccess;

  /// 位置：lib/view/page/setting/backup_page.dart:552
  ///
  /// In zh, this message translates to:
  /// **'恢复失败：{error}'**
  String snackRestoreFailed(String error);

  /// 原文 time==null 时显示 '备份时间：未知'；无归档时间时把 labelUnknown 当 {time} 传入即可得到原文。　位置：lib/view/page/setting/backup_page.dart:561, lib/view/page/setting/backup_page.dart:562
  ///
  /// In zh, this message translates to:
  /// **'备份时间：{time}'**
  String labelBackupTime(String time);

  /// 归档摘要行，多行 join('\n') 展示。　位置：lib/view/page/setting/backup_page.dart:564
  ///
  /// In zh, this message translates to:
  /// **'用户数：{count}'**
  String labelUserCount(int count);

  /// 中文量词「条」在 en 无处安放，用复数即可；若要严谨可用 ICU plural：=1{1 record} other{{count} records}。　位置：lib/view/page/setting/backup_page.dart:565
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹记录：{count} 条'**
  String labelTrackRecordCount(int count);

  /// 术语表：词条=stat。　位置：lib/view/page/setting/backup_page.dart:567
  ///
  /// In zh, this message translates to:
  /// **'包含：词条高亮规则'**
  String get labelIncludesItemRules;

  /// 位置：lib/view/page/setting/backup_page.dart:570
  ///
  /// In zh, this message translates to:
  /// **'包含：应用设置'**
  String get labelIncludesAppSettings;

  /// 位置：lib/view/page/public/select_user_page.dart:121
  ///
  /// In zh, this message translates to:
  /// **'默认用户不可重命名'**
  String get snackDefaultUserNoRename;

  /// 位置：lib/view/page/public/select_user_page.dart:132
  ///
  /// In zh, this message translates to:
  /// **'默认用户不可删除'**
  String get snackDefaultUserNoDelete;

  /// 桌面端信息按钮 tooltip。单位汇总弹窗 unit_summary_sheet.dart:81 的标题也是这串（见报告线索），建议复用同一 key。　位置：lib/view/page/public/select_user_page.dart:150
  ///
  /// In zh, this message translates to:
  /// **'详细信息'**
  String get tooltipDetails;

  /// FAB 按钮文案兼新增弹窗标题，同一 key（按 FAB 属动作类取 action 前缀）。　位置：lib/view/page/public/select_user_page.dart:168, lib/view/page/public/select_user_page.dart:327
  ///
  /// In zh, this message translates to:
  /// **'添加用户'**
  String get actionAddUser;

  /// 「」按约定译成 "…"；与已有 errorSeasonDataNotFound 结构相近但不是同一串，不合并。　位置：lib/view/page/public/select_user_page.dart:178
  ///
  /// In zh, this message translates to:
  /// **'未找到用户「{name}」的数据'**
  String errorUserDataNotFound(String name);

  /// 位置：lib/view/page/public/select_user_page.dart:252
  ///
  /// In zh, this message translates to:
  /// **'删除用户'**
  String get dialogDeleteUser;

  /// 原文用的是半角直引号 "（不是「」），zh 原样保留；句尾是全角问号。　位置：lib/view/page/public/select_user_page.dart:253
  ///
  /// In zh, this message translates to:
  /// **'确定要删除用户 \"{name}\" 吗？'**
  String dialogDeleteUserConfirm(String name);

  /// 术语表；新增/编辑用户弹窗 label + NameTextField 的默认 labelText，同一 key。　位置：lib/view/page/public/select_user_page.dart:333, lib/view/page/public/select_user_page.dart:430, lib/view/widget/username_textfield.dart:13
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get labelUsername;

  /// 只有新增弹窗带「（选填）」，编辑弹窗用 labelGuild，不能合并。　位置：lib/view/page/public/select_user_page.dart:339
  ///
  /// In zh, this message translates to:
  /// **'公会（选填）'**
  String get labelGuildOptional;

  /// 术语表 添加=add。已有 tooltipAddEntry（新增条目）是另一场景。样例条数多时按钮会显示在汇总卡里，短词更稳。　位置：lib/view/page/function/bonus_gold_calc.dart:243, lib/view/page/function/bonus_gold_calc.dart:353
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get actionAdd;

  /// 位置：lib/view/page/public/select_user_page.dart:424
  ///
  /// In zh, this message translates to:
  /// **'编辑用户'**
  String get dialogEditUser;

  /// 密码框尾部显隐按钮 tooltip；为免歧义可译 Show password（与下一条成对）。　位置：lib/view/widget/setting_edit_dialog.dart:70
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get tooltipShowPassword;

  /// 同上，可译 Hide password。　位置：lib/view/widget/setting_edit_dialog.dart:70
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get tooltipHidePassword;

  /// 边界条目：串本身基本是符号，只有末尾 'space' 是英文单词。zh 与 en 可完全相同；若不想为它建词条，直接在代码里保留硬编码也说得过去。若要本地化可把 space 改成「空格」/空格。　位置：lib/view/widget/username_textfield.dart:14
  ///
  /// In zh, this message translates to:
  /// **'0-9, a-z, A-Z, -, _, space'**
  String get labelUsernameHint;

  /// 功能页入口与该页 AppBar 标题，同一词条两处。术语表 跳波=wave skip。　位置：lib/view/page/function_page.dart:51, lib/view/page/function/wave_status_page.dart:51
  ///
  /// In zh, this message translates to:
  /// **'跳波状态'**
  String get waveStatus;

  /// 功能页入口与页面标题。英文明显更长：功能页该行右侧还有百分比徽标，400px 窄屏有挤破风险（可选更短的 Push Income）；页面标题另受 AppBar 宽度限制。　位置：lib/view/page/function_page.dart:65, lib/view/page/function/bonus_gold_calc.dart:116
  ///
  /// In zh, this message translates to:
  /// **'推波收益计算'**
  String get wavePushIncomeCalc;

  /// 功能页入口 + 收入页标题。与 income_summary_bar 里的「总收入」是两条不同词条（后者建议 totalIncome）。　位置：lib/view/page/function_page.dart:91, lib/view/page/function/income_page.dart:59
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get tabIncome;

  /// 功能页「游戏轨迹」行右侧相对时间位：该用户没有任何轨迹记录时显示。与 emptyGameTrack（暂无轨迹记录，空列表页）是两个场景。　位置：lib/view/page/function_page.dart:196
  ///
  /// In zh, this message translates to:
  /// **'无记录'**
  String get noRecord;

  /// 相对时间（每秒刷新一次）。英文要复数：1 秒应写 1 second ago，建议后续统一上 ICU plural 或让调用方按 count 选词条；分钟/小时/天/月/年五条同理。　位置：lib/view/page/function_page.dart:205
  ///
  /// In zh, this message translates to:
  /// **'{count} 秒前'**
  String timeSecondsAgo(int count);

  /// 位置：lib/view/page/function_page.dart:208
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟前'**
  String timeMinutesAgo(int count);

  /// 位置：lib/view/page/function_page.dart:211
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时前'**
  String timeHoursAgo(int count);

  /// 位置：lib/view/page/function_page.dart:214
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String timeDaysAgo(int count);

  /// 按 30 天折月（代码里 months = days ~/ 30），英文 months 同义。　位置：lib/view/page/function_page.dart:218
  ///
  /// In zh, this message translates to:
  /// **'{count} 月前'**
  String timeMonthsAgo(int count);

  /// 位置：lib/view/page/function_page.dart:221
  ///
  /// In zh, this message translates to:
  /// **'{count} 年前'**
  String timeYearsAgo(int count);

  /// 位置：lib/view/page/function/wave_status_page.dart:87
  ///
  /// In zh, this message translates to:
  /// **'游戏速度'**
  String get labelGameSpeed;

  /// 下拉选项。速度是游戏倍速（core/calc/gold_income.dart:14 里 2速=2.0 倍）。用 2x/3x 最省横向空间，若嫌太简可写 2x speed。　位置：lib/view/page/function/wave_status_page.dart:11
  ///
  /// In zh, this message translates to:
  /// **'2速'**
  String get optionSpeed2x;

  /// 「10广」= 每天看 10 个广告（每个 20 分钟三倍速），见 core/calc/gold_income.dart:12 注释。故译 ads 而非直译。　位置：lib/view/page/function/wave_status_page.dart:11
  ///
  /// In zh, this message translates to:
  /// **'2速 + 10广'**
  String get optionSpeed2xAds10;

  /// 位置：lib/view/page/function/wave_status_page.dart:11
  ///
  /// In zh, this message translates to:
  /// **'3速'**
  String get optionSpeed3x;

  /// 闹钟=闹钟转职加成（chronoClass，白 +10% / 黄 +14% / 蓝 +20%）。备选 White alarm / White chrono，待拍板。　位置：lib/view/page/function/wave_status_page.dart:13
  ///
  /// In zh, this message translates to:
  /// **'白闹钟(+10%)'**
  String get optionChronoWhite;

  /// 位置：lib/view/page/function/wave_status_page.dart:14
  ///
  /// In zh, this message translates to:
  /// **'黄闹钟(+14%)'**
  String get optionChronoYellow;

  /// 位置：lib/view/page/function/wave_status_page.dart:15
  ///
  /// In zh, this message translates to:
  /// **'蓝闹钟(+20%)'**
  String get optionChronoBlue;

  /// 10%角/30%角 的下拉选项。与已有 actionApplied/actionNotApplied（已应用/未应用）结构相同但中文不同，未复用；若想统一成一对通用词条需用户拍板。　位置：lib/view/page/function/wave_status_page.dart:17
  ///
  /// In zh, this message translates to:
  /// **'已装备'**
  String get optionEquipped;

  /// 位置：lib/view/page/function/wave_status_page.dart:17
  ///
  /// In zh, this message translates to:
  /// **'未装备'**
  String get optionNotEquipped;

  /// 恶魔号角跳波数下拉的「无」（实际是跳波 +0，下标 1）。同组其余选项 '+1'…'+5' 是纯符号数字，按规则不收。　位置：lib/view/page/function/wave_status_page.dart:19
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get optionNone;

  /// 金挂=金币挂机(Gold Auto Battle)、破挂=破关挂机，缩写 GAB/FAB 是项目自己的写法（core/calc/wave_speed.dart:28）。英文社区叫法我没把握，待拍板：保留缩写 + 直译，或全用缩写。　位置：lib/view/page/function/wave_status_page.dart:27
  ///
  /// In zh, this message translates to:
  /// **'金挂(GAB) / 破挂(FAB)'**
  String get optionAutoBattleGoldBreak;

  /// 时挂=TAB（core/calc/wave_speed.dart:10）。与上一条同组，措辞要一致。　位置：lib/view/page/function/wave_status_page.dart:28
  ///
  /// In zh, this message translates to:
  /// **'时挂(TAB)'**
  String get optionAutoBattleTime;

  /// 整句弹窗内容，英文比中文长，注意窄屏换行。　位置：lib/view/page/function/wave_status_page.dart:60
  ///
  /// In zh, this message translates to:
  /// **'数据仅供参考，实际游戏中可能会有较大偏差。'**
  String get dialogWaveStatusDisclaimer;

  /// 跨组重复：income_page.dart:77、wave_status_page.dart:64 也是「关闭」，建议其他组统一用本 key　位置：lib/view/page/tool/ranking_page.dart:434, lib/view/page/tool/item_comparer.dart:394, lib/view/page/tool/best_line_calc_page.dart:233
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get actionClose;

  /// 代码注释叫 chronoClass/闹钟转职；英文措辞需与 optionClock* 三条保持一致。　位置：lib/view/page/function/wave_status_page.dart:96
  ///
  /// In zh, this message translates to:
  /// **'闹钟类型'**
  String get labelChronoType;

  /// 「角」= 号角装备（horn）。备选 Horn +10% / 10% horn，待拍板。　位置：lib/view/page/function/wave_status_page.dart:105
  ///
  /// In zh, this message translates to:
  /// **'10%角'**
  String get labelHorn10;

  /// 位置：lib/view/page/function/wave_status_page.dart:114
  ///
  /// In zh, this message translates to:
  /// **'30%角'**
  String get labelHorn30;

  /// 术语表 跳波=wave skip；这里是「跳波数」即每跳一次多推的波数，故 wave skip（也可 wave skips）。　位置：lib/view/page/function/wave_status_page.dart:123
  ///
  /// In zh, this message translates to:
  /// **'恶魔号角跳波数'**
  String get labelDevilHornSkip;

  /// 位置：lib/view/page/function/wave_status_page.dart:132
  ///
  /// In zh, this message translates to:
  /// **'挂机类型'**
  String get labelAutoBattleType;

  /// info 弹窗内容（代码里是两个相邻字面量拼成的整句）。兽人号角/经验号角英文待拍板：Orc Horn / EXP Horn。BAND SKILL 是游戏内技能名，保留大写。　位置：lib/view/page/function/wave_status_page.dart:137-138
  ///
  /// In zh, this message translates to:
  /// **'时挂 (TAB) 选项默认启用释放乐队技能 (BAND SKILL) ，且兽人号角和经验号角同时上场。'**
  String get infoAutoBattleTab;

  /// 删除轨迹记录后的 SnackBar（带撤销按钮），英文要短，否则 SnackBar 里按钮词条会被挤。　位置：lib/view/page/function/game_track_page.dart:60
  ///
  /// In zh, this message translates to:
  /// **'已删除轨迹记录'**
  String get snackTrackDeleted;

  /// 位置：lib/view/page/function/game_track_page.dart:62
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get actionUndo;

  /// 同一概念两处：AppBar 警告图标 tooltip + 弹窗标题。备选 Note / Attention（Weak warning 太重时可换）。　位置：lib/view/page/function/game_track_page.dart:93, lib/view/page/function/game_track_page.dart:98
  ///
  /// In zh, this message translates to:
  /// **'注意'**
  String get dialogWarning;

  /// 代码里由两个相邻字面量拼成，还原为一条。　位置：lib/view/page/function/game_track_page.dart:99-101
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹记录功能已关闭，无法记录新的轨迹数据。'**
  String get dialogGameTrackOff;

  /// 位置：lib/view/page/function/game_track_page.dart:115
  ///
  /// In zh, this message translates to:
  /// **'查看轨迹图表'**
  String get tooltipViewTrackChart;

  /// tooltip 写的是「点击后切到哪种顺序」（_newestFirst ? '按时间由远到近' : …），英文沿用动作语义；若想改成描述当前状态需同时改代码语义。　位置：lib/view/page/function/game_track_page.dart:126
  ///
  /// In zh, this message translates to:
  /// **'按时间由远到近'**
  String get tooltipSortOldestFirst;

  /// 位置：lib/view/page/function/game_track_page.dart:126
  ///
  /// In zh, this message translates to:
  /// **'按时间由近到远'**
  String get tooltipSortNewestFirst;

  /// 整屏居中空状态，可长一点。　位置：lib/view/page/function/game_track_page.dart:134
  ///
  /// In zh, this message translates to:
  /// **'当前为默认用户，无法记录轨迹'**
  String get emptyTrackDefaultUser;

  /// 「」按约定改英文双引号；引号里的设置项就是 setting_page.dart:374 的「游戏轨迹记录」，两处英文必须一致（那边不归本组，需对齐）。　位置：lib/view/page/function/game_track_page.dart:137
  ///
  /// In zh, this message translates to:
  /// **'轨迹记录功能已关闭，请在设置中打开「游戏轨迹记录」'**
  String get emptyTrackDisabled;

  /// 位置：lib/view/page/function/game_track_page.dart:140
  ///
  /// In zh, this message translates to:
  /// **'暂无轨迹记录'**
  String get emptyGameTrack;

  /// 也可直接复用已有 actionDelete（删除/Delete）把 tooltip 缩短，但语义会变泛，倾向保留本 key。　位置：lib/view/page/function/game_track_page.dart:206
  ///
  /// In zh, this message translates to:
  /// **'删除记录'**
  String get tooltipDeleteRecord;

  /// AppBar 副标题。英文要处理单复数（1 record / 2 records），建议 ICU plural 或另加一条单数词条。　位置：lib/view/page/function/game_track_page.dart:297
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条记录'**
  String labelTrackCount(int count);

  /// 位置：lib/view/page/function/track/game_track_chart_page.dart:91
  ///
  /// In zh, this message translates to:
  /// **'轨迹图表'**
  String get gameTrackChart;

  /// AppBar 右侧两行小字（代码里是两个字面量 + 换行拼的）。日期由调用方格式化后传入，译文可整体替换（如 From/To）。　位置：lib/view/page/function/track/game_track_chart_page.dart:99-100
  ///
  /// In zh, this message translates to:
  /// **'起始 {start}\n截止 {end}'**
  String labelChartRange(String start, String end);

  /// 术语表 至少需要=at least。整屏空状态。　位置：lib/view/page/function/track/game_track_chart_page.dart:109
  ///
  /// In zh, this message translates to:
  /// **'至少需要两条轨迹记录'**
  String get emptyChartNeedTwoRecords;

  /// 超过 300 个点时提示。英文偏长，窄屏会折行；也要处理单复数。　位置：lib/view/page/function/track/game_track_chart_page.dart:129
  ///
  /// In zh, this message translates to:
  /// **'已压缩显示：共 {total} 条，显示 {shown} 条'**
  String labelChartDownsampled(int total, int shown);

  /// 图表面板标题。面板画的就是 record.totalGold，与已有 totalGold（总金币/Total Gold）同源不同中文——强烈建议改成复用 totalGold（代码里 '总经济' 改成 '总金币'），那本 key 就不要；若坚持「总经济」措辞则用本 key。　位置：lib/view/page/function/track/game_track_chart_page.dart:157
  ///
  /// In zh, this message translates to:
  /// **'总经济'**
  String get totalEconomy;

  /// 图表面板标题（画 gpCN）。已有 gpIndex=「GP · 指数」/「GP · Index」是「GP 与指数」合写的场合，不能直接用在这里（相邻面板标题是 'GP'），故另起 metricIndex，与已有 metricShare/metricRatio 同前缀。　位置：lib/view/page/function/track/game_track_chart_page.dart:167
  ///
  /// In zh, this message translates to:
  /// **'指数'**
  String get metricIndex;

  /// 把算出的平均收益率写回「金挂平均收益」前的确认弹窗标题；备选 Confirm income fill-in。　位置：lib/view/page/function/bonus_gold_calc.dart:68
  ///
  /// In zh, this message translates to:
  /// **'确认填入收益'**
  String get dialogConfirmApplyIncome;

  /// 两个数建议都由调用方格式化后按 String 传入（现在 from 是未格式化的 double，英文界面下会显示 12.0 这类），与 snackQuerySuccess 的做法一致。箭头沿用代码里的 '->'（也可统一改 '→'）。　位置：lib/view/page/function/bonus_gold_calc.dart:70
  ///
  /// In zh, this message translates to:
  /// **'金挂收益：{from}% -> {to}%？'**
  String dialogApplyGabBonusContent(String from, String to);

  /// 位置：lib/view/page/function/bonus_gold_calc.dart:84
  ///
  /// In zh, this message translates to:
  /// **'已填入金挂平均收益 {value}%'**
  String snackAppliedGabBonus(String value);

  /// 跨组重复：bonus_gold_calc.dart:89、:138 也是「确认」，建议统一　位置：lib/view/page/tool/item_comparer.dart:418
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get actionConfirm;

  /// 同一中文既是 AppBar tooltip 又是弹窗标题，合用一条（与 actionClear/actionDelete/actionSave 同族）。　位置：lib/view/page/function/bonus_gold_calc.dart:121, lib/view/page/function/bonus_gold_calc.dart:126
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get actionReset;

  /// AppBar 已经显示当前用户名，英文也可写 ... for this user?（更短）。　位置：lib/view/page/function/bonus_gold_calc.dart:127
  ///
  /// In zh, this message translates to:
  /// **'确认清空当前用户的所有收入样本？'**
  String get dialogResetIncomeSamples;

  /// 空列表占位（灰色居中文字）。　位置：lib/view/page/function/bonus_gold_calc.dart:165
  ///
  /// In zh, this message translates to:
  /// **'暂无收入样本'**
  String get emptyIncomeSamples;

  /// 汇总卡第一行：按当前波数推得的金挂成本。　位置：lib/view/page/function/bonus_gold_calc.dart:213
  ///
  /// In zh, this message translates to:
  /// **'金挂成本'**
  String get labelGabCost;

  /// 位置：lib/view/page/function/bonus_gold_calc.dart:218
  ///
  /// In zh, this message translates to:
  /// **'平均收入'**
  String get labelAverageIncome;

  /// 位置：lib/view/page/function/bonus_gold_calc.dart:223
  ///
  /// In zh, this message translates to:
  /// **'百分比'**
  String get labelPercent;

  /// 汇总卡左侧主按钮：把算出的百分比写回金挂平均收益。中文「填入」直译是 Fill in，但英文按钮 Apply 更自然，且与已有 actionApplied（已应用/Applied）呼应，待拍板。　位置：lib/view/page/function/bonus_gold_calc.dart:237
  ///
  /// In zh, this message translates to:
  /// **'填入'**
  String get actionFillIn;

  /// 位置：lib/view/page/function/bonus_gold_calc.dart:337
  ///
  /// In zh, this message translates to:
  /// **'输入每波金币收入'**
  String get dialogInputWaveIncome;

  /// 输入框 labelText（同一弹窗的 helperText '0-9' 是纯符号，按规则不收）。英文占位较长，InputDecoration 里会浮动，注意 80px 宽度外的输入框布局。　位置：lib/view/page/function/bonus_gold_calc.dart:344
  ///
  /// In zh, this message translates to:
  /// **'每波金币收入'**
  String get labelWaveGoldIncome;

  /// 同一中文既是 AppBar info tooltip 又是该弹窗标题，合用一条（前缀取 tooltip*，若更想按 dialog* 归类请统一改名）。备选 Help / Hint。　位置：lib/view/page/function/income_page.dart:64, lib/view/page/function/income_page.dart:70
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get tooltipInfo;

  /// 两段弹窗内容，代码里是一个字面量带 \n\n。中文用的是弯引号“”，英文按约定改直引号；引号里的「跳波状态」必须与 waveStatus 的 en 值一字不差。　位置：lib/view/page/function/income_page.dart:71-72
  ///
  /// In zh, this message translates to:
  /// **'填写“跳波状态”后再填写此处，否则计算结果不准确。\n\n此处计算结果为每日收入。'**
  String get dialogIncomeNotice;

  /// 收入页 tab（窄屏 TabBar）。同一中文还出现在 lib/view/widget/income_summary_bar.dart:23 的汇总行标题，建议那边复用本 key（该 widget 归别的分组）。　位置：lib/view/page/function/income_page.dart:89
  ///
  /// In zh, this message translates to:
  /// **'殖民地'**
  String get tabIncomeColony;

  /// 术语表 推波=wave push。income_summary_bar.dart:33 同词条，建议复用。英文比中文长，三个 tab 并排时注意 400px 下不挤。　位置：lib/view/page/function/income_page.dart:90
  ///
  /// In zh, this message translates to:
  /// **'推波'**
  String get tabIncomeWave;

  /// income_summary_bar.dart:43 同词条，建议复用。　位置：lib/view/page/function/income_page.dart:91
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get tabIncomeOther;

  /// 右侧显示 (额外殖民地/波数 ×1000)，输入框带 prefixText 'Lv.'（已是英文，不收）。　位置：lib/view/page/function/income/colony_tab.dart:51
  ///
  /// In zh, this message translates to:
  /// **'殖民地等级'**
  String get labelColonyLevel;

  /// C = 冷却（store 字段 icCooldown），G = 金币（icGold）。字母后缀是游戏内的叫法，英文保留同字母；若嫌含糊可写 Extra colony (cooldown)。　位置：lib/view/page/function/income/colony_tab.dart:85
  ///
  /// In zh, this message translates to:
  /// **'额外殖民地C'**
  String get labelExtraColonyC;

  /// 位置：lib/view/page/function/income/colony_tab.dart:101
  ///
  /// In zh, this message translates to:
  /// **'额外殖民地G'**
  String get labelExtraColonyG;

  /// 装备项（equipWheel），行右侧是开关。　位置：lib/view/page/function/income/colony_tab.dart:117
  ///
  /// In zh, this message translates to:
  /// **'车轮'**
  String get labelWheel;

  /// 装备项（equipWhip，启用等价于额外殖民地G +15）。　位置：lib/view/page/function/income/colony_tab.dart:122
  ///
  /// In zh, this message translates to:
  /// **'鞭子'**
  String get labelWhip;

  /// 输入框带 suffixText '%'（符号不收）。与 bonus_gold_calc 页的 snackAppliedGabBonus 是同一概念的不同句子，措辞要一致。　位置：lib/view/page/function/income/wave_tab.dart:64
  ///
  /// In zh, this message translates to:
  /// **'金挂平均收益'**
  String get labelGabAverageBonus;

  /// 单位 suffixText 'h' 已在代码里（英文）。两行输入框合计 >24h 时下方 errorText 写的是已有英文 'Sum > 24h'（未收），若日后要本地化可另立词条。　位置：lib/view/page/function/income/wave_tab.dart:79
  ///
  /// In zh, this message translates to:
  /// **'每日金挂时间'**
  String get labelDailyGabTime;

  /// 位置：lib/view/page/function/income/wave_tab.dart:98
  ///
  /// In zh, this message translates to:
  /// **'每日时挂时间'**
  String get labelDailyTabTime;

  /// 术语表 赛季=season。另一处同名词条是 g5 的 seasonEnded，不冲突。　位置：lib/view/page/function/income/other_tab.dart:17
  ///
  /// In zh, this message translates to:
  /// **'赛季殖民地'**
  String get labelSeasonColony;

  /// 金币大树（goldenTree）。英文更短，右侧开关位置更宽松。　位置：lib/view/page/function/income/other_tab.dart:22
  ///
  /// In zh, this message translates to:
  /// **'金币大树'**
  String get labelGoldenTree;

  /// 术语表：龙 = Dragon。备选 "Dragon Reroll Simulator"；"刷"取 farm 更贴近挂机语境　位置：lib/view/page/tools_page.dart:35, lib/view/page/tool/dragon_simulator_page.dart:184
  ///
  /// In zh, this message translates to:
  /// **'刷龙模拟器'**
  String get toolDragonSimulator;

  /// 工具列表入口与页面标题同一串　位置：lib/view/page/tools_page.dart:48, lib/view/page/tool/item_comparer.dart:344
  ///
  /// In zh, this message translates to:
  /// **'装备对比'**
  String get toolItemComparer;

  /// 备选 "Optimal Stat Combination"（更长，工具列表 ListTile 与 AppBar 都可能截断）　位置：lib/view/page/tools_page.dart:61, lib/view/page/tool/best_line_calc_page.dart:219
  ///
  /// In zh, this message translates to:
  /// **'最优装备词条组合'**
  String get toolBestLineCalc;

  /// RankingKind 是 enum const 字段，无法在枚举里取 l10n，需按 kind 写解析函数（同页 4 处拼接都依赖它）　位置：lib/view/page/tool/ranking_page.dart:14
  ///
  /// In zh, this message translates to:
  /// **'个人排行榜'**
  String get rankingKindPlayer;

  /// 位置：lib/view/page/tool/ranking_page.dart:15
  ///
  /// In zh, this message translates to:
  /// **'公会排行榜'**
  String get rankingKindGuild;

  /// 术语表：无尽 = endless　位置：lib/view/page/tool/ranking_page.dart:16
  ///
  /// In zh, this message translates to:
  /// **'无尽排行榜'**
  String get rankingKindHell;

  /// NameNotFound 的错误文案。注意与已有 errorSeasonDataNotFound「未找到「{name}」的赛季数据」不是同一句，未经合并　位置：lib/view/page/tool/ranking_page.dart:85, lib/view/page/tool/ranking_page.dart:389
  ///
  /// In zh, this message translates to:
  /// **'暂无榜单数据'**
  String get emptyRankingData;

  /// 另有 guild_page / player_detail_page 等页也可能用同一串，合并脚本按值去重　位置：lib/view/page/tool/ranking_page.dart:110, lib/view/page/tool/ranking_page.dart:418, lib/view/page/tool/ranking_page.dart:485
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get emptyData;

  /// 代码是 '${widget.kind.title}趋势'，已还原为占位符形式；{kind} 传 rankingKindXxx　位置：lib/view/page/tool/ranking_page.dart:94
  ///
  /// In zh, this message translates to:
  /// **'{kind}趋势'**
  String labelRankingTrend(String kind);

  /// 代码里是三个 const 字面量 '前 50'/'前 100'/'前 300'，建议合并为一条带占位符的词条（segments 列表不能再是 const）　位置：lib/view/page/tool/ranking_page.dart:125, lib/view/page/tool/ranking_page.dart:126, lib/view/page/tool/ranking_page.dart:127
  ///
  /// In zh, this message translates to:
  /// **'前 {count}'**
  String labelTopCount(int count);

  /// max/min 已由 int.format() 预格式化（沿用 snackQuerySuccess 的 String 约定）。英文整句偏长，窄屏（<400px）可能折行，必要时缩成 "Top {count} · {max} / {min}"　位置：lib/view/page/tool/ranking_page.dart:135
  ///
  /// In zh, this message translates to:
  /// **'前 {count} 名 · 最高 {max} · 最低 {min}'**
  String labelRankSummary(int count, String max, String min);

  /// reason 为已有错误文案（暂无榜单数据 / 查询超时，请稍后重试 / 网络错误原文）　位置：lib/view/page/tool/ranking_page.dart:383
  ///
  /// In zh, this message translates to:
  /// **'刷新失败：{reason}'**
  String snackRefreshFailed(String reason);

  /// 代码是 '${widget.kind.title}名次'。备选 "{kind} Milestones"（对应按钮 tooltip 的 milestone 说法）　位置：lib/view/page/tool/ranking_page.dart:400
  ///
  /// In zh, this message translates to:
  /// **'{kind}名次'**
  String dialogRankMilestones(String kind);

  /// 位置：lib/view/page/tool/ranking_page.dart:457
  ///
  /// In zh, this message translates to:
  /// **'查看分数趋势'**
  String get tooltipViewScoreTrend;

  /// 位置：lib/view/page/tool/ranking_page.dart:468
  ///
  /// In zh, this message translates to:
  /// **'查看特殊名次'**
  String get tooltipViewMilestoneRanks;

  /// 只在宽屏主从布局（>= Breakpoints.masterDetailMinWidth）的右侧空面板出现；detailPaneWidth 固定，英文可能折两行　位置：lib/view/page/tool/ranking_page.dart:546
  ///
  /// In zh, this message translates to:
  /// **'点击左侧条目查看玩家详情'**
  String get hintSelectPlayerDetail;

  /// 跨组重复：guild_page.dart:431、player_detail_page.dart:272 也是「重试」，建议统一　位置：lib/view/page/tool/ranking_page.dart:582
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get actionRetry;

  /// 中文用全角引号“”，英文用 "..."；句中的“高亮规则”应取页标题那条的英文（见 titleHighlightRules 的撞车说明）　位置：lib/view/page/tool/dragon_simulator_page.dart:125
  ///
  /// In zh, this message translates to:
  /// **'请先在“高亮规则”中启用至少一条规则'**
  String get snackNeedEnabledRule;

  /// count 由 int.format() 预格式化后传入（千分位），沿用 snackQuerySuccess 的 String 约定　位置：lib/view/page/tool/dragon_simulator_page.dart:156
  ///
  /// In zh, this message translates to:
  /// **'命中！共 roll 了 {count} 次'**
  String rollToHitHit(String count);

  /// 位置：lib/view/page/tool/dragon_simulator_page.dart:168
  ///
  /// In zh, this message translates to:
  /// **'已手动停止，共 roll 了 {count} 次'**
  String rollToHitStopped(String count);

  /// 下方的选项文本来自数据层 ItemSource.label（一龙~六龙），需另行处理　位置：lib/view/page/tool/dragon_simulator_page.dart:209
  ///
  /// In zh, this message translates to:
  /// **'装备来源'**
  String get labelItemSource;

  /// 中文夹用英文 roll（游戏惯用语），英文保留 roll　位置：lib/view/page/tool/dragon_simulator_page.dart:228
  ///
  /// In zh, this message translates to:
  /// **'roll 单次数量'**
  String get labelRollBatchSize;

  /// 位置：lib/view/page/tool/dragon_simulator_page.dart:249
  ///
  /// In zh, this message translates to:
  /// **'roll 单次'**
  String get actionRollOnce;

  /// roll 到死进行中的复位按钮文案　位置：lib/view/page/tool/dragon_simulator_page.dart:257
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get actionStop;

  /// 口语化中文，取意译。备选 "Auto-Roll to Hit"；按钮较窄（Row 内两个 Expanded 各半），过长的英文会换行　位置：lib/view/page/tool/dragon_simulator_page.dart:257
  ///
  /// In zh, this message translates to:
  /// **'roll 到死'**
  String get actionRollToHit;

  /// count 已由 format() 预格式化；末尾省略号中文用 …，英文可保留 …　位置：lib/view/page/tool/dragon_simulator_page.dart:268
  ///
  /// In zh, this message translates to:
  /// **'roll 到死进行中：已 roll {count} 次…'**
  String rollToHitRunning(String count);

  /// 两处都是 rule.hint 为空时的回退文案；模拟器那处前面还硬编码 '✦ ' 前缀（纯符号，不入词条）　位置：lib/view/page/tool/dragon_simulator_page.dart:361, lib/view/page/tool/item_rule_edit_page.dart:106
  ///
  /// In zh, this message translates to:
  /// **'未命名规则'**
  String get unnamedRule;

  /// 本页私有的 _typeLabels（数据层 ItemType 无显示名）；英文名请与游戏内装备类型名对齐后再定　位置：lib/view/page/tool/item_rule_edit_page.dart:17
  ///
  /// In zh, this message translates to:
  /// **'弓'**
  String get itemTypeBow;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:18
  ///
  /// In zh, this message translates to:
  /// **'剑'**
  String get itemTypeSword;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:19
  ///
  /// In zh, this message translates to:
  /// **'杖'**
  String get itemTypeStaff;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:20
  ///
  /// In zh, this message translates to:
  /// **'锤'**
  String get itemTypeHammer;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:21
  ///
  /// In zh, this message translates to:
  /// **'戒指'**
  String get itemTypeRing;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:22
  ///
  /// In zh, this message translates to:
  /// **'项链'**
  String get itemTypeNecklace;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:23
  ///
  /// In zh, this message translates to:
  /// **'手镯'**
  String get itemTypeBracelet;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:24
  ///
  /// In zh, this message translates to:
  /// **'耳环'**
  String get itemTypeEarrings;

  /// FAB 文案与新建表单的 AppBar 标题同一串。注意 '新增条目' 已有 tooltipAddEntry（阵容页），此处不复用　位置：lib/view/page/tool/item_rule_edit_page.dart:58, lib/view/page/tool/item_rule_edit_page.dart:378
  ///
  /// In zh, this message translates to:
  /// **'新增规则'**
  String get actionAddRule;

  /// 句式对齐已有 emptyFormationHint（"暂无条目，点击右上角 + 添加" / "No entries yet — tap + in the top right"）　位置：lib/view/page/tool/item_rule_edit_page.dart:64
  ///
  /// In zh, this message translates to:
  /// **'暂无规则，点击右下角新增'**
  String get emptyItemRuleHint;

  /// 与 labelPinToTop「命中后置顶显示」同一概念、两种中文写法；若同意统一，两条可只留一条（本处是图标 tooltip 的短式）　位置：lib/view/page/tool/item_rule_edit_page.dart:112
  ///
  /// In zh, this message translates to:
  /// **'命中后置顶'**
  String get tooltipPinToTop;

  /// action* 家族已有 actionDelete/actionSave/actionCancel，但 arb 里缺 actionEdit，需新增　位置：lib/view/page/tool/item_rule_edit_page.dart:121
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get actionEdit;

  /// 代码用 '、' join 类型名；备份组已有 listSeparator（中文「、」/ 英文「, 」），调用点应改用它来 join，否则英文里会冒出中文顿号　位置：lib/view/page/tool/item_rule_edit_page.dart:160
  ///
  /// In zh, this message translates to:
  /// **'装备类型：{types}'**
  String labelItemTypes(String types);

  /// SnackBar 提示（_showHint），两处同串　位置：lib/view/page/tool/item_rule_edit_page.dart:262, lib/view/page/tool/item_rule_edit_page.dart:289
  ///
  /// In zh, this message translates to:
  /// **'已有红色词条，白色词条最多 2 条'**
  String get errorWhiteLinesWithRed;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:266, lib/view/page/tool/item_rule_edit_page.dart:293
  ///
  /// In zh, this message translates to:
  /// **'白色词条最多 3 条'**
  String get errorWhiteLinesMax;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:270
  ///
  /// In zh, this message translates to:
  /// **'白色词条已达 3 条，不能选择红色词条'**
  String get errorRedWithThreeWhite;

  /// 保存时的校验提示　位置：lib/view/page/tool/item_rule_edit_page.dart:307
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个词条'**
  String get errorNoLineSelected;

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:319
  ///
  /// In zh, this message translates to:
  /// **'数值需为数字或留空'**
  String get errorValueNotNumber;

  /// 中文全角括号，英文用半角；括号里的『大于/小于』对应输入框旁的 > / < 符号，勿丢　位置：lib/view/page/tool/item_rule_edit_page.dart:324
  ///
  /// In zh, this message translates to:
  /// **'下限（大于）必须小于上限（小于）'**
  String get errorMinGreaterThanMax;

  /// {line} 是词条名（数据层英文 label）；min/max 已由 format() 预格式化。代码里是两个相邻字面量拼接，已还原为一条　位置：lib/view/page/tool/item_rule_edit_page.dart:334
  ///
  /// In zh, this message translates to:
  /// **'\"{line}\" 的下限超出 roll 值范围（{min} ~ {max}）'**
  String errorMinOutOfRange(String line, String min, String max);

  /// 位置：lib/view/page/tool/item_rule_edit_page.dart:342
  ///
  /// In zh, this message translates to:
  /// **'\"{line}\" 的上限超出 roll 值范围（{min} ~ {max}）'**
  String errorMaxOutOfRange(String line, String min, String max);

  /// 与通用动作 actionEdit 区分：本串指『编辑这条规则』的表单标题　位置：lib/view/page/tool/item_rule_edit_page.dart:378
  ///
  /// In zh, this message translates to:
  /// **'编辑规则'**
  String get titleEditRule;

  /// 规则 hint 输入框的 labelText　位置：lib/view/page/tool/item_rule_edit_page.dart:392
  ///
  /// In zh, this message translates to:
  /// **'提示文本'**
  String get labelHintText;

  /// 输入框 hintText；『红白加强』是玩家自造词，英文取直译即可，或用 "e.g. red + white buff"　位置：lib/view/page/tool/item_rule_edit_page.dart:393
  ///
  /// In zh, this message translates to:
  /// **'如：红白加强（可留空）'**
  String get hintRuleHintExample;

  /// SwitchListTile 标题；与 tooltipPinToTop 同概念两写法，见该条　位置：lib/view/page/tool/item_rule_edit_page.dart:400
  ///
  /// In zh, this message translates to:
  /// **'命中后置顶显示'**
  String get labelPinToTop;

  /// FilterChip 区的小标题　位置：lib/view/page/tool/item_rule_edit_page.dart:406
  ///
  /// In zh, this message translates to:
  /// **'指定装备类型（不选则不限）'**
  String get labelSelectItemTypes;

  /// 代码是三个相邻字面量拼接成一段，已还原为一条（保留 \n 排版）；英文明显更长，页面顶部固定提示区会变高，注意矮窗 ShortWindowFallback(460) 余量　位置：lib/view/page/tool/item_rule_edit_page.dart:440
  ///
  /// In zh, this message translates to:
  /// **'提示：红/金词条各最多选 1 条；白色词条合计 3 条时不能选红色词条；\n输入数值范围时，判断的是词条原始值（加强前的值），留空表示不限。\n\n大于下限必须小于上限；输入值还需在词条的允许范围内。'**
  String get helpRuleForm;

  /// 代码是 '1条'/'2条' 两个 const 字面量（白词条出现条数），建议合并。英文有复数问题（1 line / 2 lines），建议用 ICU plural；也可统一显示为 ×1 / ×2（与 _conditionLabel 的 '×{count}' 一致，省掉复数）　位置：lib/view/page/tool/item_rule_edit_page.dart:478, lib/view/page/tool/item_rule_edit_page.dart:479
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String labelLineCount(int count);

  /// No description provided for @lineColorWhite.
  ///
  /// In zh, this message translates to:
  /// **'白词条'**
  String get lineColorWhite;

  /// No description provided for @lineColorRed.
  ///
  /// In zh, this message translates to:
  /// **'红词条'**
  String get lineColorRed;

  /// No description provided for @lineColorGold.
  ///
  /// In zh, this message translates to:
  /// **'金词条'**
  String get lineColorGold;

  /// No description provided for @lineColorPurple.
  ///
  /// In zh, this message translates to:
  /// **'紫词条'**
  String get lineColorPurple;

  /// No description provided for @labelItemLines.
  ///
  /// In zh, this message translates to:
  /// **'装备 {index} 词条'**
  String labelItemLines(int index);

  /// 帮助弹窗是 Text.rich 多 TextSpan，本组条目按 span 一一对应；末尾 \n\n 属排版，若想干净可留在代码里只译句子　位置：lib/view/page/tool/item_comparer.dart:357
  ///
  /// In zh, this message translates to:
  /// **'该工具用于对比两件装备的期望。\n\n'**
  String get dialogItemCompareHelpIntro;

  /// 该 span 在代码里是加粗样式　位置：lib/view/page/tool/item_comparer.dart:359
  ///
  /// In zh, this message translates to:
  /// **'使用步骤：\n'**
  String get dialogItemCompareHelpStepsTitle;

  /// 中文全角引号“无装备面板”引用的正是 labelNoItemPanel，英文须与其一致（或改用占位符）。宝珠/宝物暂无官方英文，暂用 orb / treasure　位置：lib/view/page/tool/item_comparer.dart:363
  ///
  /// In zh, this message translates to:
  /// **'1. 确认需要对比的装备 / 宝珠 / 宝物槽位，然后将对应的物品卸下，根据此时的面板填写“无装备面板”数据；\n'**
  String get dialogItemCompareHelpStep1;

  /// 全角引号→英文 "..."；与 labelItemNumber 的英文保持同字面　位置：lib/view/page/tool/item_comparer.dart:365
  ///
  /// In zh, this message translates to:
  /// **'2. 将两件装备的白词条填写到“装备 1 / 装备 2”中，'**
  String get dialogItemCompareHelpStep2;

  /// 代码里这段是加粗 span；"Element Damage" 是下拉框选项原文，勿改　位置：lib/view/page/tool/item_comparer.dart:367
  ///
  /// In zh, this message translates to:
  /// **'请注意词条类型，元素伤害统一并入 \"Element Damage\"，请自行根据单位属性填入对应元素伤害词条；\n'**
  String get dialogItemCompareHelpStep2Note;

  /// 末尾三个换行是排版　位置：lib/view/page/tool/item_comparer.dart:370
  ///
  /// In zh, this message translates to:
  /// **'3. 对比结果：实时显示三组 DPS 结果，并给出结论。\n\n\n'**
  String get dialogItemCompareHelpStep3;

  /// 加粗 span，与下一句连成一段　位置：lib/view/page/tool/item_comparer.dart:372
  ///
  /// In zh, this message translates to:
  /// **'普攻型单位：'**
  String get dialogItemCompareHelpNormalUnit;

  /// Attacks Per Second / Increased Speed / Attack Speed % 都是面板标签与词条原文，英文原样保留　位置：lib/view/page/tool/item_comparer.dart:376
  ///
  /// In zh, this message translates to:
  /// **'需要填写 Attacks Per Second 和 Increased Speed，Attack Speed % 词条参与计算。\n'**
  String get dialogItemCompareHelpNormalUnitDesc;

  /// 位置：lib/view/page/tool/item_comparer.dart:379
  ///
  /// In zh, this message translates to:
  /// **'技能型单位：'**
  String get dialogItemCompareHelpSkillUnit;

  /// 位置：lib/view/page/tool/item_comparer.dart:382
  ///
  /// In zh, this message translates to:
  /// **'不填写上述两项，Attack Speed % 词条不参与计算。'**
  String get dialogItemCompareHelpSkillUnitDesc;

  /// 加粗 span；前导 \n\n 属排版，建议移出词条只保留 "注："　位置：lib/view/page/tool/item_comparer.dart:384
  ///
  /// In zh, this message translates to:
  /// **'\n\n注：'**
  String get dialogItemCompareHelpNoteLabel;

  /// 宝珠/宝物译名与 Step1 保持一致　位置：lib/view/page/tool/item_comparer.dart:387
  ///
  /// In zh, this message translates to:
  /// **'宝珠、宝物等词条也可用于计算，但需要注意词条类型。'**
  String get dialogItemCompareHelpNoteDesc;

  /// 确认按钮用的是 actionConfirm（确认），取消用已有 actionCancel　位置：lib/view/page/tool/item_comparer.dart:407
  ///
  /// In zh, this message translates to:
  /// **'是否清空所有输入？'**
  String get dialogResetConfirm;

  /// 与 best_line_calc_page.dart:331「面板无装备数值」是同一概念两种中文写法（自造词），建议二选一统一；英文 All 大写连字符方案便于帮助文案里引用　位置：lib/view/page/tool/item_comparer.dart:449
  ///
  /// In zh, this message translates to:
  /// **'无装备面板'**
  String get labelNoItemPanel;

  /// 装备卡内的添加按钮（每条装备最多 3 条词条）　位置：lib/view/page/tool/item_comparer.dart:659
  ///
  /// In zh, this message translates to:
  /// **'添加词条'**
  String get actionAddLine;

  /// DropdownButtonFormField 的 hint　位置：lib/view/page/tool/item_comparer.dart:770
  ///
  /// In zh, this message translates to:
  /// **'选择词条类型'**
  String get hintSelectLineType;

  /// 数值输入框 hintText　位置：lib/view/page/tool/item_comparer.dart:799
  ///
  /// In zh, this message translates to:
  /// **'数值'**
  String get hintValue;

  /// 行尾 × 图标；与 actionDelete「删除」区分，此处带宾语　位置：lib/view/page/tool/item_comparer.dart:805
  ///
  /// In zh, this message translates to:
  /// **'删除词条'**
  String get tooltipDeleteLine;

  /// 结果表头。同行的 APS / DPS 已是英文，不入词条　位置：lib/view/page/tool/item_comparer.dart:868
  ///
  /// In zh, this message translates to:
  /// **'无暴击'**
  String get labelNoCrit;

  /// 表头列宽是 Expanded 四等分（右侧 68px 留给行标签），英文比中文长，注意挤压数值列　位置：lib/view/page/tool/item_comparer.dart:868
  ///
  /// In zh, this message translates to:
  /// **'有暴击'**
  String get labelWithCrit;

  /// 结果表第一行行标签（第二、三行用 labelItemNumber）　位置：lib/view/page/tool/item_comparer.dart:880
  ///
  /// In zh, this message translates to:
  /// **'无装备'**
  String get labelNoItem;

  /// 代码是 '装备 1'/'装备 2'，建议合并为带占位符的一条　位置：lib/view/page/tool/item_comparer.dart:881, lib/view/page/tool/item_comparer.dart:882
  ///
  /// In zh, this message translates to:
  /// **'装备 {index}'**
  String labelItemNumber(int index);

  /// gain 为 '—'（未就绪）或 '+12.3%'。英文整句明显更长且居中显示，窄屏可能折成两行　位置：lib/view/page/tool/item_comparer.dart:885
  ///
  /// In zh, this message translates to:
  /// **'装备 1 较无装备 {gain1} · 装备 2 较无装备 {gain2}'**
  String labelCompareGainSummary(String gain1, String gain2);

  /// Base Attack 未填（ready=false）时的结论占位　位置：lib/view/page/tool/item_comparer.dart:896
  ///
  /// In zh, this message translates to:
  /// **'填写数据后自动对比'**
  String get compareVerdictPending;

  /// 代码是 '装备 1 更优' 拼接可选从句，已还原为带占位符的一条；{gap} 传 compareGapItem2 或空串。英文若不想留前导逗号，可改写成 "Item 1 wins — DPS ..." 并同步改 compareGapItem2 的英文　位置：lib/view/page/tool/item_comparer.dart:901
  ///
  /// In zh, this message translates to:
  /// **'装备 1 更优{gap}'**
  String compareVerdictItem1(String gap);

  /// 拼接用从句，以中文逗号开头；英文前导 ", " 要保留　位置：lib/view/page/tool/item_comparer.dart:899
  ///
  /// In zh, this message translates to:
  /// **'，DPS 比装备 2 高 {gain}'**
  String compareGapItem2(String gain);

  /// 同 compareVerdictItem1　位置：lib/view/page/tool/item_comparer.dart:907
  ///
  /// In zh, this message translates to:
  /// **'装备 2 更优{gap}'**
  String compareVerdictItem2(String gap);

  /// 同 compareGapItem2　位置：lib/view/page/tool/item_comparer.dart:905
  ///
  /// In zh, this message translates to:
  /// **'，DPS 比装备 1 高 {gain}'**
  String compareGapItem1(String gain);

  /// 位置：lib/view/page/tool/item_comparer.dart:909
  ///
  /// In zh, this message translates to:
  /// **'两件装备 DPS 相同'**
  String get compareVerdictTie;

  /// 全角括号→英文半角；出现在组合列表每行标题里　位置：lib/view/page/tool/best_line_calc_page.dart:203
  ///
  /// In zh, this message translates to:
  /// **'（无输出词条）'**
  String get labelNoDamageLines;

  /// 中文句里夹英文游戏术语，英文侧保持原词形；本页帮助弹窗只有这一句（标题用 dialogUsageHelp）　位置：lib/view/page/tool/best_line_calc_page.dart:229
  ///
  /// In zh, this message translates to:
  /// **'Avg. Dmg 和下方列表中的 Damage 都是 Damage 与 Elemental Damage 的均值。'**
  String get dialogBestLineHelpAvgDmg;

  /// 与 labelNoItemPanel「无装备面板」同概念两种写法，建议统一（本页面板字段是 Increased Dmg / Critical Chance / Critical Dmg / Increased Speed）　位置：lib/view/page/tool/best_line_calc_page.dart:331
  ///
  /// In zh, this message translates to:
  /// **'面板无装备数值'**
  String get labelPanelWithoutItem;

  /// 代码是 '6 词条'/'5 词条'/'4 词条' 三个 const 字面量（词条位数量），建议合并；英文有复数问题，建议 ICU plural 或统一 "{count} slots"　位置：lib/view/page/tool/best_line_calc_page.dart:410, lib/view/page/tool/best_line_calc_page.dart:411, lib/view/page/tool/best_line_calc_page.dart:412
  ///
  /// In zh, this message translates to:
  /// **'{count} 词条'**
  String labelLineSlot(int count);

  /// 列举出的搭配总数（190 / 122 / 70），英文可加 "combos" 复数；此列是 labelSmall，英文长度无压力　位置：lib/view/page/tool/best_line_calc_page.dart:421
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 种'**
  String labelComboCount(int count);

  /// 同一中文已被 g5 的 dataSectionGameTrack（数据备份分段名，en 小写 game track）占用：merge_arb 按中文查重，g2 排在 g5 前，会把 g5 那条判为重复并跳过。建议二者合一（分段名也用本 key）或让 g5 改成句子化的 key，见报告。　位置：lib/view/page/function_page.dart:121, lib/view/page/function/game_track_page.dart:85
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹'**
  String get gameTrack;

  /// 下拉全量同步失败的提示。{reason} 内嵌的仍是 _errorMessage 的整句（含「查询超时，请稍后重试」等），英文下会形成 "Sync failed: Query timed out. Please try again."，可接受。　位置：lib/view/page/guild_page.dart:296
  ///
  /// In zh, this message translates to:
  /// **'同步失败：{reason}'**
  String snackSyncFailed(String reason);

  /// 与已有 errorSeasonDataNotFound 句式同源但主语不同（公会 info vs 赛季数据），不复用。「」按约定译成双引号。备选：No guild found named "{name}"。　位置：lib/view/page/guild_page.dart:305
  ///
  /// In zh, this message translates to:
  /// **'未找到公会「{name}」的信息'**
  String errorGuildNotFound(String name);

  /// 源码 314-315 两行字符串拼接，中间是一个 \n 强制换行（错误页居中文本，宽度受限）。英文比中文长约 1.8 倍，窄屏会折成 3~4 行；若排版吃紧，英文可改成单段不分行。　位置：lib/view/page/guild_page.dart:314
  ///
  /// In zh, this message translates to:
  /// **'当前为默认用户，仅用于体验基础功能。\n请到「设置」页的「用户管理」创建自己的账号，并填写公会名。'**
  String get emptyGuildDefaultUserHint;

  /// 位置：lib/view/page/guild_page.dart:317
  ///
  /// In zh, this message translates to:
  /// **'当前用户未设置公会，请先到「用户管理」中填写公会名'**
  String get emptyGuildHint;

  /// 位置：lib/view/page/guild_page.dart:328
  ///
  /// In zh, this message translates to:
  /// **'该公会暂无成员'**
  String get emptyGuildMembers;

  /// FilledButton 文案。另需一个「用户管理」的 key（select_user_page.dart:29 / setting_page.dart:186 的标题，属设置组），与本条不是同一个串，勿互相顶替。　位置：lib/view/page/guild_page.dart:425
  ///
  /// In zh, this message translates to:
  /// **'前往用户管理'**
  String get actionGoToUserManagement;

  /// 宽屏主从两栏右侧的占位提示。ranking_page.dart:546「点击左侧条目查看玩家详情」仅差一词，建议两组统一成一条 key（改动来源文案）或保持两条并在英文里都译作同一句。　位置：lib/view/page/guild_page.dart:477
  ///
  /// In zh, this message translates to:
  /// **'点击左侧成员查看玩家详情'**
  String get emptySelectMemberHint;

  /// {count}=成员数，{score}=已千分位格式化的赛季波数总和（沿用 snackQuerySuccess 的做法，格式化交给调用方，故为 String）。英文复数：1 时应为 "1 member · …"，ARB 里可用 ICU plural（无 plural 支持时建议写成 "{count} members · {score}" 并在 note 里记一笔）。右对齐列，英文更长，窄屏有挤占公会名胶囊的空间风险。　位置：lib/view/page/guild_page.dart:550
  ///
  /// In zh, this message translates to:
  /// **'{count} 人 · {score}'**
  String guildMemberCountAndScore(int count, String score);

  /// 嵌入两栏面板时头部的关闭按钮 tooltip；独立 AppBar 场景不显示。　位置：lib/view/page/public/player_detail_page.dart:228
  ///
  /// In zh, this message translates to:
  /// **'关闭详情'**
  String get tooltipCloseDetail;

  /// 整页空状态。与已有 snackUserBanned（用户「{name}」已被封禁）只差「玩家/用户」——若要统一产品用词，可只留 snackUserBanned 一条，但中文界面会从「玩家」变成「用户」（需拍板）。　位置：lib/view/page/public/player_detail_page.dart:290
  ///
  /// In zh, this message translates to:
  /// **'玩家「{name}」已被封禁'**
  String errorPlayerBanned(String name);

  /// 区块小标题（titleSmall）。中文用全角括号，英文用半角；备选缩写 "Waves/h (third-party API)"。　位置：lib/view/page/public/player_detail_page.dart:335
  ///
  /// In zh, this message translates to:
  /// **'每小时波速（第三方 API）'**
  String get labelWphHistory;

  /// {season} 是接口返回的赛季标识原样（如 2025-09）；只译「赛季」二字。　位置：lib/view/page/public/player_detail_page.dart:344
  ///
  /// In zh, this message translates to:
  /// **'赛季 {season}'**
  String labelSeason(String season);

  /// 汇总卡的 SummaryRow 标题。术语表：无尽 endless / 分数 score。仅当无尽榜有数据时显示。　位置：lib/view/page/public/player_detail_page.dart:429
  ///
  /// In zh, this message translates to:
  /// **'无尽分数'**
  String get endlessScore;

  /// 汇总卡行标题（术语表：上次在线 last online）。右侧值当前是英文硬编码拼接 "… ago"，详见报告「英文硬编码」一节——本期不改的话，英文界面会出现 "Last online  12min ago" 而中文界面是「上次在线  12min ago」。　位置：lib/view/page/public/player_detail_page.dart:451
  ///
  /// In zh, this message translates to:
  /// **'上次在线'**
  String get lastOnline;

  /// 标题右侧的胶囊（_StatusPill，fontSize 12、内边距 10/6）。英文 "3/8 enabled" 比中文「3/8 启用」宽约一倍，与标题同排、标题有 Expanded+ellipsis 兜底，但仍偏紧；如需更短可用 "3/8 on"。　位置：lib/view/widget/unit_summary_sheet.dart:94
  ///
  /// In zh, this message translates to:
  /// **'{enabled}/{total} 启用'**
  String unitEnabledCount(int enabled, int total);

  /// 【需拍板】与阵容页已有 metricShare（"占比" / "Share"）是同一指标、仅中文措辞不同。二选一：①保留本 key；②复用 metricShare 并把此处中文改成「占比」（此时本条删除）。同理见下面两条。三列等宽、字号 11，英文 "Gold share" 比「金币占比」宽，注意换行。　位置：lib/view/widget/unit_summary_sheet.dart:353
  ///
  /// In zh, this message translates to:
  /// **'金币占比'**
  String get metricGoldShare;

  /// 【需拍板】对应已有 metricOneOverRatio（"1/比例" / "1 / Ratio"）的同一数值（单位等级/总波数）。这里的中文更直白，建议保留本 key；若要与阵容页统一措辞则复用 metricOneOverRatio。三列等宽，最长的一条，英文按 11px 约 70px，窄屏有换行风险。　位置：lib/view/widget/unit_summary_sheet.dart:355
  ///
  /// In zh, this message translates to:
  /// **'单位 / 波数'**
  String get metricUnitPerWave;

  /// 【需拍板】对应已有 metricRatio（"比例" / "Ratio"）的同一数值（其上一条的倒数）；同上二选一。斜杠两侧的空格与代码一致，保留。　位置：lib/view/widget/unit_summary_sheet.dart:357
  ///
  /// In zh, this message translates to:
  /// **'波数 / 单位'**
  String get metricWavePerUnit;

  /// 同一串既是 AppBar 计时按钮的 tooltip（49），又是详情弹窗的标题（107），按「同一中文不复造 key」合并为一条，故 key 名不带 tooltip 前缀。若偏好 tooltip 前缀，可拆成 tooltipSeasonProgress + dialogSeasonProgress，但会重复同一中文。　位置：lib/view/widget/season_indicator.dart:49, lib/view/widget/season_indicator.dart:107
  ///
  /// In zh, this message translates to:
  /// **'赛季进度'**
  String get seasonProgress;

  /// 赛季详情弹窗的行标签（开始时间）。仅当接口给了 start 时显示该行。　位置：lib/view/widget/season_indicator.dart:120
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get labelStart;

  /// 同一弹窗的行标签（结束时间）。与 seasonEnded（已结束）区分：这里是时刻标签 End，不是状态 Ended。　位置：lib/view/widget/season_indicator.dart:122
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get labelEnd;

  /// 行标签，右侧值是 formatSeasonRemaining 的 "2d 3h 45m"（英文单位，本期不改）。　位置：lib/view/widget/season_indicator.dart:124
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get labelRemaining;

  /// 术语表：总收入 total income。同理已有的 totalGold（总金币）是另一指标，勿混用。　位置：lib/view/widget/income_summary_bar.dart:53
  ///
  /// In zh, this message translates to:
  /// **'总收入'**
  String get incomeTotal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
