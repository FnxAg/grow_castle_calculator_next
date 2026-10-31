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

  /// No description provided for @tabFormation.
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

  /// No description provided for @tooltipShowActions.
  ///
  /// In zh, this message translates to:
  /// **'展开操作'**
  String get tooltipShowActions;

  /// No description provided for @tooltipHideActions.
  ///
  /// In zh, this message translates to:
  /// **'隐藏操作'**
  String get tooltipHideActions;

  /// No description provided for @tooltipFetchData.
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

  /// No description provided for @snackQuerySuccess.
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

  /// No description provided for @gp.
  ///
  /// In zh, this message translates to:
  /// **'GP'**
  String get gp;

  /// No description provided for @gpCN.
  ///
  /// In zh, this message translates to:
  /// **'指数'**
  String get gpCN;

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

  /// No description provided for @unitNameTownArcher.
  ///
  /// In zh, this message translates to:
  /// **'城弓'**
  String get unitNameTownArcher;

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

  /// No description provided for @nameLabelTownArcher.
  ///
  /// In zh, this message translates to:
  /// **'城弓名称'**
  String get nameLabelTownArcher;

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

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageTraditionalChinese.
  ///
  /// In zh, this message translates to:
  /// **'繁體中文'**
  String get languageTraditionalChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @itemSourceDragon1.
  ///
  /// In zh, this message translates to:
  /// **'一龙（绿龙）'**
  String get itemSourceDragon1;

  /// No description provided for @itemSourceDragon2.
  ///
  /// In zh, this message translates to:
  /// **'二龙（黑龙）'**
  String get itemSourceDragon2;

  /// No description provided for @itemSourceDragon3.
  ///
  /// In zh, this message translates to:
  /// **'三龙（红龙）'**
  String get itemSourceDragon3;

  /// No description provided for @itemSourceDragon4.
  ///
  /// In zh, this message translates to:
  /// **'四龙（罪恶龙）'**
  String get itemSourceDragon4;

  /// No description provided for @itemSourceDragon5.
  ///
  /// In zh, this message translates to:
  /// **'五龙（传说龙）'**
  String get itemSourceDragon5;

  /// No description provided for @itemSourceDragon6.
  ///
  /// In zh, this message translates to:
  /// **'六龙（骨龙）'**
  String get itemSourceDragon6;

  /// No description provided for @itemSourceDragon7.
  ///
  /// In zh, this message translates to:
  /// **'七龙（远古龙）'**
  String get itemSourceDragon7;

  /// No description provided for @itemSourceDragon1Easteregg.
  ///
  /// In zh, this message translates to:
  /// **'苍虬'**
  String get itemSourceDragon1Easteregg;

  /// No description provided for @itemSourceDragon2Easteregg.
  ///
  /// In zh, this message translates to:
  /// **'玄螭'**
  String get itemSourceDragon2Easteregg;

  /// No description provided for @itemSourceDragon3Easteregg.
  ///
  /// In zh, this message translates to:
  /// **'赤螭'**
  String get itemSourceDragon3Easteregg;

  /// No description provided for @itemSourceDragon4Easteregg.
  ///
  /// In zh, this message translates to:
  /// **'正弦函数'**
  String get itemSourceDragon4Easteregg;

  /// No description provided for @itemSourceDragon5Easteregg.
  ///
  /// In zh, this message translates to:
  /// **'绛霄赤蜃'**
  String get itemSourceDragon5Easteregg;

  /// No description provided for @itemSourceDragon6Easteregg.
  ///
  /// In zh, this message translates to:
  /// **'漆骨巨蛟'**
  String get itemSourceDragon6Easteregg;

  /// No description provided for @itemSourceDragon7Easteregg.
  ///
  /// In zh, this message translates to:
  /// **'黯霜灰烬'**
  String get itemSourceDragon7Easteregg;

  /// No description provided for @eastereggDragonName.
  ///
  /// In zh, this message translates to:
  /// **'v1.51.8：“正弦函数”'**
  String get eastereggDragonName;

  /// No description provided for @webdavAuthFailed.
  ///
  /// In zh, this message translates to:
  /// **'账号或密码错误（HTTP 401）'**
  String get webdavAuthFailed;

  /// No description provided for @webdavForbidden.
  ///
  /// In zh, this message translates to:
  /// **'没有访问权限（HTTP 403）'**
  String get webdavForbidden;

  /// No description provided for @webdavNoBackupFile.
  ///
  /// In zh, this message translates to:
  /// **'云端还没有备份文件'**
  String get webdavNoBackupFile;

  /// No description provided for @webdavMethodNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'服务器不支持该操作（HTTP 405）'**
  String get webdavMethodNotAllowed;

  /// No description provided for @webdavServerError.
  ///
  /// In zh, this message translates to:
  /// **'服务器返回错误（HTTP {status}）'**
  String webdavServerError(String status);

  /// No description provided for @webdavUnreachable.
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务器，请检查网络与 WebDAV 地址'**
  String get webdavUnreachable;

  /// No description provided for @archiveInvalidJson.
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件（JSON 解析失败）'**
  String get archiveInvalidJson;

  /// No description provided for @archiveInvalid.
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件'**
  String get archiveInvalid;

  /// No description provided for @archiveMissingVersion.
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件（缺少版本信息）'**
  String get archiveMissingVersion;

  /// No description provided for @archiveNewerVersion.
  ///
  /// In zh, this message translates to:
  /// **'该备份由更新版本的应用创建，请先升级应用后再导入'**
  String get archiveNewerVersion;

  /// No description provided for @archiveUnsupportedVersion.
  ///
  /// In zh, this message translates to:
  /// **'不支持该备份文件版本'**
  String get archiveUnsupportedVersion;

  /// No description provided for @archiveMissingData.
  ///
  /// In zh, this message translates to:
  /// **'不是有效的备份文件（缺少数据内容）'**
  String get archiveMissingData;

  /// No description provided for @backupBusy.
  ///
  /// In zh, this message translates to:
  /// **'已有备份任务进行中，请稍后再试'**
  String get backupBusy;

  /// No description provided for @backupFailed.
  ///
  /// In zh, this message translates to:
  /// **'备份失败，请稍后重试'**
  String get backupFailed;

  /// No description provided for @backupNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'请先配置 WebDAV 服务器地址、账号与密码'**
  String get backupNotConfigured;

  /// No description provided for @backupNoRestorableData.
  ///
  /// In zh, this message translates to:
  /// **'文件中不包含可恢复的数据'**
  String get backupNoRestorableData;

  /// No description provided for @dataSectionUserData.
  ///
  /// In zh, this message translates to:
  /// **'用户数据'**
  String get dataSectionUserData;

  /// No description provided for @dataSectionUserMeta.
  ///
  /// In zh, this message translates to:
  /// **'用户元数据'**
  String get dataSectionUserMeta;

  /// No description provided for @dataSectionAppSettings.
  ///
  /// In zh, this message translates to:
  /// **'应用设置'**
  String get dataSectionAppSettings;

  /// No description provided for @highlightRules.
  ///
  /// In zh, this message translates to:
  /// **'高亮规则'**
  String get highlightRules;

  /// No description provided for @backupRestorePartialFailure.
  ///
  /// In zh, this message translates to:
  /// **'以下数据恢复失败：{sections}'**
  String backupRestorePartialFailure(String sections);

  /// No description provided for @listSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get listSeparator;

  /// No description provided for @seasonEnded.
  ///
  /// In zh, this message translates to:
  /// **'已结束'**
  String get seasonEnded;

  /// No description provided for @tabFunction.
  ///
  /// In zh, this message translates to:
  /// **'功能'**
  String get tabFunction;

  /// No description provided for @tabGuild.
  ///
  /// In zh, this message translates to:
  /// **'公会'**
  String get tabGuild;

  /// No description provided for @tabTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get tabTools;

  /// No description provided for @tabSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabSettings;

  /// No description provided for @snackUpdateCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败，请检查网络后重试'**
  String get snackUpdateCheckFailed;

  /// No description provided for @snackAlreadyLatest.
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本 v{version}'**
  String snackAlreadyLatest(String version);

  /// No description provided for @dialogUpdateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get dialogUpdateAvailable;

  /// No description provided for @dialogUpdateAvailableBody.
  ///
  /// In zh, this message translates to:
  /// **'{hasCurrent, select, yes{最新版本 {latest}（当前 v{current}）} other{最新版本 {latest}}}'**
  String dialogUpdateAvailableBody(
    String hasCurrent,
    String latest,
    String current,
  );

  /// No description provided for @labelChangelog.
  ///
  /// In zh, this message translates to:
  /// **'更新日志：'**
  String get labelChangelog;

  /// No description provided for @actionOpenReleasePage.
  ///
  /// In zh, this message translates to:
  /// **'打开发布页'**
  String get actionOpenReleasePage;

  /// No description provided for @snackCannotOpenLink.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接：{url}'**
  String snackCannotOpenLink(String url);

  /// No description provided for @settingsEnabled.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get settingsEnabled;

  /// No description provided for @settingsThirdPartyApi.
  ///
  /// In zh, this message translates to:
  /// **'第三方 API'**
  String get settingsThirdPartyApi;

  /// No description provided for @labelApiUrl.
  ///
  /// In zh, this message translates to:
  /// **'API 地址'**
  String get labelApiUrl;

  /// No description provided for @settingsQueryConcurrency.
  ///
  /// In zh, this message translates to:
  /// **'查询并发数'**
  String get settingsQueryConcurrency;

  /// No description provided for @labelConcurrency.
  ///
  /// In zh, this message translates to:
  /// **'并发数'**
  String get labelConcurrency;

  /// No description provided for @settingsTrackInterval.
  ///
  /// In zh, this message translates to:
  /// **'记录间隔'**
  String get settingsTrackInterval;

  /// No description provided for @labelMinutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get labelMinutes;

  /// No description provided for @settingsUserManagement.
  ///
  /// In zh, this message translates to:
  /// **'用户管理'**
  String get settingsUserManagement;

  /// No description provided for @settingsThemeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get settingsThemeMode;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'亮色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'暗色'**
  String get themeDark;

  /// No description provided for @settingsThirdPartyApiSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'玩家详情页获取波速信息'**
  String get settingsThirdPartyApiSubtitle;

  /// No description provided for @settingsAutoLastOnline.
  ///
  /// In zh, this message translates to:
  /// **'自动查询上次在线'**
  String get settingsAutoLastOnline;

  /// No description provided for @settingsAutoLastOnlineSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'公会详情页查询成员\"上次在线\"'**
  String get settingsAutoLastOnlineSubtitle;

  /// No description provided for @settingsGameTrack.
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹记录'**
  String get settingsGameTrack;

  /// No description provided for @settingsGameTrackSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'记录个人数据变化'**
  String get settingsGameTrackSubtitle;

  /// No description provided for @settingsGameTrackMinInterval.
  ///
  /// In zh, this message translates to:
  /// **'轨迹记录最小间隔'**
  String get settingsGameTrackMinInterval;

  /// No description provided for @settingsGameTrackIntervalValue.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String settingsGameTrackIntervalValue(int minutes);

  /// No description provided for @settingsDataBackup.
  ///
  /// In zh, this message translates to:
  /// **'数据备份'**
  String get settingsDataBackup;

  /// No description provided for @settingsDataBackupSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 云备份 · 本地导入导出'**
  String get settingsDataBackupSubtitle;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsCurrentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本 v{version}'**
  String settingsCurrentVersion(String version);

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// No description provided for @aboutAdaptedVersion.
  ///
  /// In zh, this message translates to:
  /// **'适配版本'**
  String get aboutAdaptedVersion;

  /// No description provided for @aboutGuide.
  ///
  /// In zh, this message translates to:
  /// **'使用说明'**
  String get aboutGuide;

  /// No description provided for @aboutThirdPartyApiInfo.
  ///
  /// In zh, this message translates to:
  /// **'第三方 API 说明'**
  String get aboutThirdPartyApiInfo;

  /// No description provided for @aboutThirdPartyApiInfoSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'当查询内容为空时，请查看这里'**
  String get aboutThirdPartyApiInfoSubtitle;

  /// No description provided for @dialogThirdPartyApiBody.
  ///
  /// In zh, this message translates to:
  /// **'默认第三方 API (https://fnxag.eu.org/gcapi) 由开发者维护。\n只有部分玩家在记录范围中，如果有需要，可联系开发者添加。\n需要使用其他 API 时，可以自行创建。\n\n注意：该 API 与本应用无任何直接联系，请自行判断是否使用。'**
  String get dialogThirdPartyApiBody;

  /// No description provided for @actionGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get actionGotIt;

  /// No description provided for @aboutGithubRepo.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 仓库'**
  String get aboutGithubRepo;

  /// No description provided for @aboutOriginalGithubRepo.
  ///
  /// In zh, this message translates to:
  /// **'原项目 GitHub 仓库'**
  String get aboutOriginalGithubRepo;

  /// No description provided for @aboutQqGroup.
  ///
  /// In zh, this message translates to:
  /// **'QQ 群'**
  String get aboutQqGroup;

  /// No description provided for @aboutDeveloperEmail.
  ///
  /// In zh, this message translates to:
  /// **'开发者邮箱'**
  String get aboutDeveloperEmail;

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutLicenseNotice.
  ///
  /// In zh, this message translates to:
  /// **'本应用遵循 GNU GPL-3.0 开源协议'**
  String get aboutLicenseNotice;

  /// No description provided for @sectionInfo.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get sectionInfo;

  /// No description provided for @sectionLinks.
  ///
  /// In zh, this message translates to:
  /// **'链接'**
  String get sectionLinks;

  /// No description provided for @sectionLicenses.
  ///
  /// In zh, this message translates to:
  /// **'授权'**
  String get sectionLicenses;

  /// No description provided for @aboutTagline.
  ///
  /// In zh, this message translates to:
  /// **'Grow Castle 辅助工具'**
  String get aboutTagline;

  /// No description provided for @sectionWebdavBackup.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 备份'**
  String get sectionWebdavBackup;

  /// No description provided for @actionBackupNow.
  ///
  /// In zh, this message translates to:
  /// **'立即备份'**
  String get actionBackupNow;

  /// No description provided for @backupNowSubtitleReady.
  ///
  /// In zh, this message translates to:
  /// **'检查云端新旧后上传覆盖'**
  String get backupNowSubtitleReady;

  /// No description provided for @backupServerNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置服务器'**
  String get backupServerNotConfigured;

  /// No description provided for @actionRestoreFromCloud.
  ///
  /// In zh, this message translates to:
  /// **'从云端恢复'**
  String get actionRestoreFromCloud;

  /// No description provided for @backupRestoreSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'下载云端备份并覆盖本机数据'**
  String get backupRestoreSubtitle;

  /// No description provided for @sectionLocalFiles.
  ///
  /// In zh, this message translates to:
  /// **'本地文件'**
  String get sectionLocalFiles;

  /// No description provided for @actionExportToFile.
  ///
  /// In zh, this message translates to:
  /// **'导出到文件'**
  String get actionExportToFile;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'把全部数据保存为本地文件'**
  String get backupExportSubtitle;

  /// No description provided for @actionImportFile.
  ///
  /// In zh, this message translates to:
  /// **'导入文件'**
  String get actionImportFile;

  /// No description provided for @backupImportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从本地文件恢复数据'**
  String get backupImportSubtitle;

  /// No description provided for @backupOverwriteHint.
  ///
  /// In zh, this message translates to:
  /// **'导入或恢复会覆盖本机全部数据，建议先导出备份。'**
  String get backupOverwriteHint;

  /// No description provided for @labelServerAddress.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get labelServerAddress;

  /// No description provided for @labelNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get labelNotSet;

  /// No description provided for @labelAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get labelAccount;

  /// No description provided for @labelPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get labelPassword;

  /// No description provided for @labelWebdavAccount.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 账号'**
  String get labelWebdavAccount;

  /// No description provided for @labelWebdavPassword.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 密码'**
  String get labelWebdavPassword;

  /// No description provided for @labelServerUrlExample.
  ///
  /// In zh, this message translates to:
  /// **'https://dav.example.com/dav/目录'**
  String get labelServerUrlExample;

  /// No description provided for @backupLastSuccess.
  ///
  /// In zh, this message translates to:
  /// **'上次成功备份：{time}'**
  String backupLastSuccess(String time);

  /// No description provided for @labelNever.
  ///
  /// In zh, this message translates to:
  /// **'从未'**
  String get labelNever;

  /// No description provided for @labelUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get labelUnknown;

  /// No description provided for @labelTimeUnknown.
  ///
  /// In zh, this message translates to:
  /// **'时间未知'**
  String get labelTimeUnknown;

  /// No description provided for @backupLastFailed.
  ///
  /// In zh, this message translates to:
  /// **'{hasTime, select, yes{上次备份失败：{error}（{time}）} other{上次备份失败：{error}}}'**
  String backupLastFailed(String hasTime, String error, String time);

  /// No description provided for @snackBackupSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已备份到云端'**
  String get snackBackupSuccess;

  /// No description provided for @snackBackupFailed.
  ///
  /// In zh, this message translates to:
  /// **'备份失败：{error}'**
  String snackBackupFailed(String error);

  /// No description provided for @snackRemoteProbeFailed.
  ///
  /// In zh, this message translates to:
  /// **'检测云端备份失败：{reason}'**
  String snackRemoteProbeFailed(String reason);

  /// No description provided for @snackRemoteProbeFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'检测云端备份失败，请稍后重试'**
  String get snackRemoteProbeFailedRetry;

  /// No description provided for @dialogUploadBackupTitle.
  ///
  /// In zh, this message translates to:
  /// **'上传备份到云端'**
  String get dialogUploadBackupTitle;

  /// No description provided for @dialogCloudBackupLine.
  ///
  /// In zh, this message translates to:
  /// **'{hasSize, select, yes{云端备份：{time}，{size} KB} other{云端备份：{time}}}'**
  String dialogCloudBackupLine(String hasSize, String time, String size);

  /// No description provided for @dialogCloudBackupNoFile.
  ///
  /// In zh, this message translates to:
  /// **'云端备份：还没有备份文件（将新建一份）'**
  String get dialogCloudBackupNoFile;

  /// No description provided for @dialogLastLocalBackupLine.
  ///
  /// In zh, this message translates to:
  /// **'本机上次成功备份：{time}'**
  String dialogLastLocalBackupLine(String time);

  /// No description provided for @actionRestoreRemote.
  ///
  /// In zh, this message translates to:
  /// **'恢复云端'**
  String get actionRestoreRemote;

  /// No description provided for @actionUpload.
  ///
  /// In zh, this message translates to:
  /// **'上传'**
  String get actionUpload;

  /// No description provided for @actionOverwriteAnyway.
  ///
  /// In zh, this message translates to:
  /// **'仍要覆盖'**
  String get actionOverwriteAnyway;

  /// No description provided for @actionOverwriteUpload.
  ///
  /// In zh, this message translates to:
  /// **'覆盖上传'**
  String get actionOverwriteUpload;

  /// No description provided for @dialogWarningRemoteNewer.
  ///
  /// In zh, this message translates to:
  /// **'云端备份比本机上次成功备份更新，可能来自其他设备；覆盖后云端那份将无法找回。'**
  String get dialogWarningRemoteNewer;

  /// No description provided for @dialogWarningRemoteTimeUnknown.
  ///
  /// In zh, this message translates to:
  /// **'无法获取云端备份时间；覆盖后云端那份将无法找回。'**
  String get dialogWarningRemoteTimeUnknown;

  /// No description provided for @dialogWarningLocalNoRecord.
  ///
  /// In zh, this message translates to:
  /// **'本机没有成功备份记录，无法确认云端那份的来源；覆盖后无法找回。'**
  String get dialogWarningLocalNoRecord;

  /// No description provided for @dialogRestoreCloudSource.
  ///
  /// In zh, this message translates to:
  /// **'{hasTime, select, yes{云端备份（{time}）} other{云端备份}}{hasSize, select, yes{，{size} KB} other{}}'**
  String dialogRestoreCloudSource(
    String hasTime,
    String time,
    String hasSize,
    String size,
  );

  /// No description provided for @snackFetchRemoteFailed.
  ///
  /// In zh, this message translates to:
  /// **'获取云端备份失败：{reason}'**
  String snackFetchRemoteFailed(String reason);

  /// No description provided for @snackInvalidCloudFile.
  ///
  /// In zh, this message translates to:
  /// **'云端文件无效：{reason}'**
  String snackInvalidCloudFile(String reason);

  /// No description provided for @dialogWarningRestoreOlder.
  ///
  /// In zh, this message translates to:
  /// **'{hasTime, select, yes{云端备份早于本机上次成功备份（{time}），恢复会退回较旧的数据。} other{云端备份早于本机上次成功备份，恢复会退回较旧的数据。}}'**
  String dialogWarningRestoreOlder(String hasTime, String time);

  /// No description provided for @dialogWarningRestoreNewer.
  ///
  /// In zh, this message translates to:
  /// **'云端备份比本机上次成功备份更新，可能来自其他设备。'**
  String get dialogWarningRestoreNewer;

  /// No description provided for @dialogWarningRestoreUnknown.
  ///
  /// In zh, this message translates to:
  /// **'无法判断云端备份与本机记录的新旧，恢复前请确认来源。'**
  String get dialogWarningRestoreUnknown;

  /// No description provided for @snackExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败，请稍后重试'**
  String get snackExportFailed;

  /// No description provided for @dialogTitleExportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出数据备份'**
  String get dialogTitleExportBackup;

  /// No description provided for @snackExportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已导出到文件'**
  String get snackExportSuccess;

  /// No description provided for @dialogTitlePickBackupFile.
  ///
  /// In zh, this message translates to:
  /// **'选择备份文件'**
  String get dialogTitlePickBackupFile;

  /// No description provided for @snackInvalidFile.
  ///
  /// In zh, this message translates to:
  /// **'文件无效：{reason}'**
  String snackInvalidFile(String reason);

  /// No description provided for @snackReadFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取文件失败，请确认是导出的备份文件'**
  String get snackReadFileFailed;

  /// No description provided for @dialogPickLocalFileSource.
  ///
  /// In zh, this message translates to:
  /// **'本机文件：{name}'**
  String dialogPickLocalFileSource(String name);

  /// No description provided for @dialogRestoreSource.
  ///
  /// In zh, this message translates to:
  /// **'来源：{source}'**
  String dialogRestoreSource(String source);

  /// No description provided for @actionOverwriteRestore.
  ///
  /// In zh, this message translates to:
  /// **'覆盖恢复'**
  String get actionOverwriteRestore;

  /// No description provided for @snackRestoreSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已恢复本地数据'**
  String get snackRestoreSuccess;

  /// No description provided for @snackRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败：{error}'**
  String snackRestoreFailed(String error);

  /// No description provided for @labelBackupTime.
  ///
  /// In zh, this message translates to:
  /// **'备份时间：{time}'**
  String labelBackupTime(String time);

  /// No description provided for @labelUserCount.
  ///
  /// In zh, this message translates to:
  /// **'用户数：{count}'**
  String labelUserCount(int count);

  /// No description provided for @labelTrackRecordCount.
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹记录：{count} 条'**
  String labelTrackRecordCount(int count);

  /// No description provided for @labelIncludesItemRules.
  ///
  /// In zh, this message translates to:
  /// **'包含：词条高亮规则'**
  String get labelIncludesItemRules;

  /// No description provided for @labelIncludesAppSettings.
  ///
  /// In zh, this message translates to:
  /// **'包含：应用设置'**
  String get labelIncludesAppSettings;

  /// No description provided for @snackDefaultUserNoRename.
  ///
  /// In zh, this message translates to:
  /// **'默认用户不可重命名'**
  String get snackDefaultUserNoRename;

  /// No description provided for @snackDefaultUserNoDelete.
  ///
  /// In zh, this message translates to:
  /// **'默认用户不可删除'**
  String get snackDefaultUserNoDelete;

  /// No description provided for @tooltipDetails.
  ///
  /// In zh, this message translates to:
  /// **'详细信息'**
  String get tooltipDetails;

  /// No description provided for @actionAddUser.
  ///
  /// In zh, this message translates to:
  /// **'添加用户'**
  String get actionAddUser;

  /// No description provided for @errorUserDataNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到用户「{name}」的数据'**
  String errorUserDataNotFound(String name);

  /// No description provided for @dialogDeleteUser.
  ///
  /// In zh, this message translates to:
  /// **'删除用户'**
  String get dialogDeleteUser;

  /// No description provided for @dialogDeleteUserConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除用户 \"{name}\" 吗？'**
  String dialogDeleteUserConfirm(String name);

  /// No description provided for @labelUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get labelUsername;

  /// No description provided for @labelGuildOptional.
  ///
  /// In zh, this message translates to:
  /// **'公会（选填）'**
  String get labelGuildOptional;

  /// No description provided for @actionAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get actionAdd;

  /// No description provided for @dialogEditUser.
  ///
  /// In zh, this message translates to:
  /// **'编辑用户'**
  String get dialogEditUser;

  /// No description provided for @tooltipShowPassword.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get tooltipShowPassword;

  /// No description provided for @tooltipHidePassword.
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get tooltipHidePassword;

  /// No description provided for @labelUsernameHint.
  ///
  /// In zh, this message translates to:
  /// **'0-9, a-z, A-Z, -, _, space'**
  String get labelUsernameHint;

  /// No description provided for @waveStatus.
  ///
  /// In zh, this message translates to:
  /// **'跳波状态'**
  String get waveStatus;

  /// No description provided for @wavePushIncomeCalc.
  ///
  /// In zh, this message translates to:
  /// **'推波收益计算'**
  String get wavePushIncomeCalc;

  /// No description provided for @tabIncome.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get tabIncome;

  /// No description provided for @noRecord.
  ///
  /// In zh, this message translates to:
  /// **'无记录'**
  String get noRecord;

  /// No description provided for @timeSecondsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 秒前'**
  String timeSecondsAgo(int count);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟前'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时前'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String timeDaysAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 月前'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeYearsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 年前'**
  String timeYearsAgo(int count);

  /// No description provided for @labelGameSpeed.
  ///
  /// In zh, this message translates to:
  /// **'游戏速度'**
  String get labelGameSpeed;

  /// No description provided for @optionSpeed2x.
  ///
  /// In zh, this message translates to:
  /// **'2速'**
  String get optionSpeed2x;

  /// No description provided for @optionSpeed2xAds10.
  ///
  /// In zh, this message translates to:
  /// **'2速 + 10广'**
  String get optionSpeed2xAds10;

  /// No description provided for @optionSpeed3x.
  ///
  /// In zh, this message translates to:
  /// **'3速'**
  String get optionSpeed3x;

  /// No description provided for @optionChronoWhite.
  ///
  /// In zh, this message translates to:
  /// **'白闹钟(+10%)'**
  String get optionChronoWhite;

  /// No description provided for @optionChronoYellow.
  ///
  /// In zh, this message translates to:
  /// **'黄闹钟(+14%)'**
  String get optionChronoYellow;

  /// No description provided for @optionChronoBlue.
  ///
  /// In zh, this message translates to:
  /// **'蓝闹钟(+20%)'**
  String get optionChronoBlue;

  /// No description provided for @optionEquipped.
  ///
  /// In zh, this message translates to:
  /// **'已装备'**
  String get optionEquipped;

  /// No description provided for @optionNotEquipped.
  ///
  /// In zh, this message translates to:
  /// **'未装备'**
  String get optionNotEquipped;

  /// No description provided for @optionNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get optionNone;

  /// No description provided for @optionAutoBattleGoldBreak.
  ///
  /// In zh, this message translates to:
  /// **'金挂(GAB) / 破挂(FAB)'**
  String get optionAutoBattleGoldBreak;

  /// No description provided for @optionAutoBattleTime.
  ///
  /// In zh, this message translates to:
  /// **'时挂(TAB)'**
  String get optionAutoBattleTime;

  /// No description provided for @dialogWaveStatusDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'数据仅供参考，实际游戏中可能会有较大偏差。'**
  String get dialogWaveStatusDisclaimer;

  /// No description provided for @actionClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get actionClose;

  /// No description provided for @labelChronoType.
  ///
  /// In zh, this message translates to:
  /// **'闹钟类型'**
  String get labelChronoType;

  /// No description provided for @labelHorn10.
  ///
  /// In zh, this message translates to:
  /// **'10%角'**
  String get labelHorn10;

  /// No description provided for @labelHorn30.
  ///
  /// In zh, this message translates to:
  /// **'30%角'**
  String get labelHorn30;

  /// No description provided for @labelDevilHornSkip.
  ///
  /// In zh, this message translates to:
  /// **'恶魔号角跳波数'**
  String get labelDevilHornSkip;

  /// No description provided for @labelAutoBattleType.
  ///
  /// In zh, this message translates to:
  /// **'挂机类型'**
  String get labelAutoBattleType;

  /// No description provided for @infoAutoBattleTab.
  ///
  /// In zh, this message translates to:
  /// **'时挂 (TAB) 选项默认启用释放乐队技能 (BAND SKILL) ，且兽人号角和经验号角同时上场。'**
  String get infoAutoBattleTab;

  /// No description provided for @snackTrackDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除轨迹记录'**
  String get snackTrackDeleted;

  /// No description provided for @actionUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get actionUndo;

  /// No description provided for @dialogWarning.
  ///
  /// In zh, this message translates to:
  /// **'注意'**
  String get dialogWarning;

  /// No description provided for @dialogGameTrackOff.
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹记录功能已关闭，无法记录新的轨迹数据。'**
  String get dialogGameTrackOff;

  /// No description provided for @tooltipViewTrackChart.
  ///
  /// In zh, this message translates to:
  /// **'查看轨迹图表'**
  String get tooltipViewTrackChart;

  /// No description provided for @tooltipSortOldestFirst.
  ///
  /// In zh, this message translates to:
  /// **'按时间由远到近'**
  String get tooltipSortOldestFirst;

  /// No description provided for @tooltipSortNewestFirst.
  ///
  /// In zh, this message translates to:
  /// **'按时间由近到远'**
  String get tooltipSortNewestFirst;

  /// No description provided for @emptyTrackDefaultUser.
  ///
  /// In zh, this message translates to:
  /// **'当前为默认用户，无法记录轨迹'**
  String get emptyTrackDefaultUser;

  /// No description provided for @emptyTrackDisabled.
  ///
  /// In zh, this message translates to:
  /// **'轨迹记录功能已关闭，请在设置中打开「游戏轨迹记录」'**
  String get emptyTrackDisabled;

  /// No description provided for @emptyGameTrack.
  ///
  /// In zh, this message translates to:
  /// **'暂无轨迹记录'**
  String get emptyGameTrack;

  /// No description provided for @tooltipDeleteRecord.
  ///
  /// In zh, this message translates to:
  /// **'删除记录'**
  String get tooltipDeleteRecord;

  /// No description provided for @labelTrackCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条记录'**
  String labelTrackCount(int count);

  /// No description provided for @gameTrackChart.
  ///
  /// In zh, this message translates to:
  /// **'轨迹图表'**
  String get gameTrackChart;

  /// No description provided for @labelChartRange.
  ///
  /// In zh, this message translates to:
  /// **'起始 {start}\n截止 {end}'**
  String labelChartRange(String start, String end);

  /// No description provided for @emptyChartNeedTwoRecords.
  ///
  /// In zh, this message translates to:
  /// **'至少需要两条轨迹记录'**
  String get emptyChartNeedTwoRecords;

  /// No description provided for @labelChartDownsampled.
  ///
  /// In zh, this message translates to:
  /// **'已压缩显示：共 {total} 条，显示 {shown} 条'**
  String labelChartDownsampled(int total, int shown);

  /// No description provided for @totalEconomy.
  ///
  /// In zh, this message translates to:
  /// **'总经济'**
  String get totalEconomy;

  /// No description provided for @metricIndex.
  ///
  /// In zh, this message translates to:
  /// **'指数'**
  String get metricIndex;

  /// No description provided for @dialogConfirmApplyIncome.
  ///
  /// In zh, this message translates to:
  /// **'确认填入收益'**
  String get dialogConfirmApplyIncome;

  /// No description provided for @dialogApplyGabBonusContent.
  ///
  /// In zh, this message translates to:
  /// **'金挂收益：{from}% -> {to}%？'**
  String dialogApplyGabBonusContent(String from, String to);

  /// No description provided for @snackAppliedGabBonus.
  ///
  /// In zh, this message translates to:
  /// **'已填入金挂平均收益 {value}%'**
  String snackAppliedGabBonus(String value);

  /// No description provided for @actionConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get actionConfirm;

  /// No description provided for @actionReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get actionReset;

  /// No description provided for @dialogResetIncomeSamples.
  ///
  /// In zh, this message translates to:
  /// **'确认清空当前用户的所有收入样本？'**
  String get dialogResetIncomeSamples;

  /// No description provided for @emptyIncomeSamples.
  ///
  /// In zh, this message translates to:
  /// **'暂无收入样本'**
  String get emptyIncomeSamples;

  /// No description provided for @labelGabCost.
  ///
  /// In zh, this message translates to:
  /// **'金挂成本'**
  String get labelGabCost;

  /// No description provided for @labelAverageIncome.
  ///
  /// In zh, this message translates to:
  /// **'平均收入'**
  String get labelAverageIncome;

  /// No description provided for @labelPercent.
  ///
  /// In zh, this message translates to:
  /// **'百分比'**
  String get labelPercent;

  /// No description provided for @actionFillIn.
  ///
  /// In zh, this message translates to:
  /// **'填入'**
  String get actionFillIn;

  /// No description provided for @dialogInputWaveIncome.
  ///
  /// In zh, this message translates to:
  /// **'输入每波金币收入'**
  String get dialogInputWaveIncome;

  /// No description provided for @labelWaveGoldIncome.
  ///
  /// In zh, this message translates to:
  /// **'每波金币收入'**
  String get labelWaveGoldIncome;

  /// No description provided for @tooltipInfo.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get tooltipInfo;

  /// No description provided for @dialogIncomeNotice.
  ///
  /// In zh, this message translates to:
  /// **'填写“跳波状态”后再填写此处，否则计算结果不准确。\n\n此处计算结果为每日收入。'**
  String get dialogIncomeNotice;

  /// No description provided for @tabIncomeColony.
  ///
  /// In zh, this message translates to:
  /// **'殖民地'**
  String get tabIncomeColony;

  /// No description provided for @tabIncomeWave.
  ///
  /// In zh, this message translates to:
  /// **'推波'**
  String get tabIncomeWave;

  /// No description provided for @tabIncomeOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get tabIncomeOther;

  /// No description provided for @labelInfiniteColonyLevel.
  ///
  /// In zh, this message translates to:
  /// **'通天塔等级'**
  String get labelInfiniteColonyLevel;

  /// No description provided for @labelExtraColonyCooldownSkill.
  ///
  /// In zh, this message translates to:
  /// **'额外殖民地C'**
  String get labelExtraColonyCooldownSkill;

  /// No description provided for @labelExtraColonyGoldSkill.
  ///
  /// In zh, this message translates to:
  /// **'额外殖民地G'**
  String get labelExtraColonyGoldSkill;

  /// No description provided for @labelWheel.
  ///
  /// In zh, this message translates to:
  /// **'车轮'**
  String get labelWheel;

  /// No description provided for @labelWhip.
  ///
  /// In zh, this message translates to:
  /// **'鞭子'**
  String get labelWhip;

  /// No description provided for @labelGabAverageBonus.
  ///
  /// In zh, this message translates to:
  /// **'金挂平均收益'**
  String get labelGabAverageBonus;

  /// No description provided for @labelDailyGabTime.
  ///
  /// In zh, this message translates to:
  /// **'每日金挂/破挂时间'**
  String get labelDailyGabTime;

  /// No description provided for @labelDailyTabTime.
  ///
  /// In zh, this message translates to:
  /// **'每日时挂时间'**
  String get labelDailyTabTime;

  /// No description provided for @labelSeasonColony.
  ///
  /// In zh, this message translates to:
  /// **'赛季殖民地'**
  String get labelSeasonColony;

  /// No description provided for @labelGoldenTree.
  ///
  /// In zh, this message translates to:
  /// **'金币大树'**
  String get labelGoldenTree;

  /// No description provided for @toolDragonSimulator.
  ///
  /// In zh, this message translates to:
  /// **'刷龙模拟器'**
  String get toolDragonSimulator;

  /// No description provided for @toolItemComparer.
  ///
  /// In zh, this message translates to:
  /// **'装备对比'**
  String get toolItemComparer;

  /// No description provided for @toolBestLineCalc.
  ///
  /// In zh, this message translates to:
  /// **'最优装备词条组合'**
  String get toolBestLineCalc;

  /// No description provided for @rankingKindPlayer.
  ///
  /// In zh, this message translates to:
  /// **'个人排行榜'**
  String get rankingKindPlayer;

  /// No description provided for @rankingKindGuild.
  ///
  /// In zh, this message translates to:
  /// **'公会排行榜'**
  String get rankingKindGuild;

  /// No description provided for @rankingKindHell.
  ///
  /// In zh, this message translates to:
  /// **'无尽排行榜'**
  String get rankingKindHell;

  /// No description provided for @emptyRankingData.
  ///
  /// In zh, this message translates to:
  /// **'暂无榜单数据'**
  String get emptyRankingData;

  /// No description provided for @emptyData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get emptyData;

  /// No description provided for @labelRankingTrend.
  ///
  /// In zh, this message translates to:
  /// **'{kind}趋势'**
  String labelRankingTrend(String kind);

  /// No description provided for @labelTopCount.
  ///
  /// In zh, this message translates to:
  /// **'前 {count}'**
  String labelTopCount(int count);

  /// No description provided for @labelRankSummary.
  ///
  /// In zh, this message translates to:
  /// **'前 {count} 名 · 最高 {max} · 最低 {min}'**
  String labelRankSummary(int count, String max, String min);

  /// No description provided for @snackRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'刷新失败：{reason}'**
  String snackRefreshFailed(String reason);

  /// No description provided for @dialogRankMilestones.
  ///
  /// In zh, this message translates to:
  /// **'{kind}名次'**
  String dialogRankMilestones(String kind);

  /// No description provided for @tooltipViewScoreTrend.
  ///
  /// In zh, this message translates to:
  /// **'查看分数趋势'**
  String get tooltipViewScoreTrend;

  /// No description provided for @tooltipViewMilestoneRanks.
  ///
  /// In zh, this message translates to:
  /// **'查看特殊名次'**
  String get tooltipViewMilestoneRanks;

  /// No description provided for @hintSelectPlayerDetail.
  ///
  /// In zh, this message translates to:
  /// **'点击左侧条目查看玩家详情'**
  String get hintSelectPlayerDetail;

  /// No description provided for @actionRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get actionRetry;

  /// No description provided for @snackNeedEnabledRule.
  ///
  /// In zh, this message translates to:
  /// **'请先在“高亮规则”中启用至少一条规则'**
  String get snackNeedEnabledRule;

  /// No description provided for @rollToHitHit.
  ///
  /// In zh, this message translates to:
  /// **'命中！共 roll 了 {count} 次'**
  String rollToHitHit(String count);

  /// No description provided for @rollToHitStopped.
  ///
  /// In zh, this message translates to:
  /// **'已手动停止，共 roll 了 {count} 次'**
  String rollToHitStopped(String count);

  /// No description provided for @labelItemSource.
  ///
  /// In zh, this message translates to:
  /// **'装备来源'**
  String get labelItemSource;

  /// No description provided for @labelHighestTierBonus.
  ///
  /// In zh, this message translates to:
  /// **'最高品阶掉落率加成'**
  String get labelHighestTierBonus;

  /// No description provided for @labelRollBatchSize.
  ///
  /// In zh, this message translates to:
  /// **'roll 单次数量'**
  String get labelRollBatchSize;

  /// No description provided for @actionRollOnce.
  ///
  /// In zh, this message translates to:
  /// **'roll 单次'**
  String get actionRollOnce;

  /// No description provided for @actionStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get actionStop;

  /// No description provided for @actionRollToHit.
  ///
  /// In zh, this message translates to:
  /// **'roll 到死'**
  String get actionRollToHit;

  /// No description provided for @rollToHitRunning.
  ///
  /// In zh, this message translates to:
  /// **'roll 到死进行中：已 roll {count} 次…'**
  String rollToHitRunning(String count);

  /// No description provided for @unnamedRule.
  ///
  /// In zh, this message translates to:
  /// **'未命名规则'**
  String get unnamedRule;

  /// No description provided for @itemTypeBow.
  ///
  /// In zh, this message translates to:
  /// **'弓'**
  String get itemTypeBow;

  /// No description provided for @itemTypeSword.
  ///
  /// In zh, this message translates to:
  /// **'剑'**
  String get itemTypeSword;

  /// No description provided for @itemTypeStaff.
  ///
  /// In zh, this message translates to:
  /// **'杖'**
  String get itemTypeStaff;

  /// No description provided for @itemTypeHammer.
  ///
  /// In zh, this message translates to:
  /// **'锤'**
  String get itemTypeHammer;

  /// No description provided for @itemTypeRing.
  ///
  /// In zh, this message translates to:
  /// **'戒指'**
  String get itemTypeRing;

  /// No description provided for @itemTypeNecklace.
  ///
  /// In zh, this message translates to:
  /// **'项链'**
  String get itemTypeNecklace;

  /// No description provided for @itemTypeBracelet.
  ///
  /// In zh, this message translates to:
  /// **'手镯'**
  String get itemTypeBracelet;

  /// No description provided for @itemTypeEarrings.
  ///
  /// In zh, this message translates to:
  /// **'耳环'**
  String get itemTypeEarrings;

  /// No description provided for @actionAddRule.
  ///
  /// In zh, this message translates to:
  /// **'新增规则'**
  String get actionAddRule;

  /// No description provided for @emptyItemRuleHint.
  ///
  /// In zh, this message translates to:
  /// **'暂无规则，点击右下角新增'**
  String get emptyItemRuleHint;

  /// No description provided for @tooltipPinToTop.
  ///
  /// In zh, this message translates to:
  /// **'命中后置顶'**
  String get tooltipPinToTop;

  /// No description provided for @actionEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get actionEdit;

  /// No description provided for @labelItemTypes.
  ///
  /// In zh, this message translates to:
  /// **'装备类型：{types}'**
  String labelItemTypes(String types);

  /// No description provided for @errorWhiteLinesWithRed.
  ///
  /// In zh, this message translates to:
  /// **'已有红色词条，白色词条最多 2 条'**
  String get errorWhiteLinesWithRed;

  /// No description provided for @errorWhiteLinesMax.
  ///
  /// In zh, this message translates to:
  /// **'白色词条最多 3 条'**
  String get errorWhiteLinesMax;

  /// No description provided for @errorRedWithThreeWhite.
  ///
  /// In zh, this message translates to:
  /// **'白色词条已达 3 条，不能选择红色词条'**
  String get errorRedWithThreeWhite;

  /// No description provided for @errorNoLineSelected.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个词条'**
  String get errorNoLineSelected;

  /// No description provided for @errorValueNotNumber.
  ///
  /// In zh, this message translates to:
  /// **'数值需为数字或留空'**
  String get errorValueNotNumber;

  /// No description provided for @errorMinGreaterThanMax.
  ///
  /// In zh, this message translates to:
  /// **'下限（大于）必须小于上限（小于）'**
  String get errorMinGreaterThanMax;

  /// No description provided for @errorMinOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'\"{line}\" 的下限超出 roll 值范围（{min} ~ {max}）'**
  String errorMinOutOfRange(String line, String min, String max);

  /// No description provided for @errorMaxOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'\"{line}\" 的上限超出 roll 值范围（{min} ~ {max}）'**
  String errorMaxOutOfRange(String line, String min, String max);

  /// No description provided for @titleEditRule.
  ///
  /// In zh, this message translates to:
  /// **'编辑规则'**
  String get titleEditRule;

  /// No description provided for @labelHintText.
  ///
  /// In zh, this message translates to:
  /// **'提示文本'**
  String get labelHintText;

  /// No description provided for @hintRuleHintExample.
  ///
  /// In zh, this message translates to:
  /// **'如：红白加强（可留空）'**
  String get hintRuleHintExample;

  /// No description provided for @labelPinToTop.
  ///
  /// In zh, this message translates to:
  /// **'命中后置顶显示'**
  String get labelPinToTop;

  /// No description provided for @labelSelectItemTypes.
  ///
  /// In zh, this message translates to:
  /// **'指定装备类型（不选则不限）'**
  String get labelSelectItemTypes;

  /// No description provided for @helpRuleForm.
  ///
  /// In zh, this message translates to:
  /// **'提示：红/金词条各最多选 1 条；白色词条合计 3 条时不能选红色词条；\n输入数值范围时，判断的是词条原始值（加强前的值），留空表示不限。\n\n大于下限必须小于上限；输入值还需在词条的允许范围内。'**
  String get helpRuleForm;

  /// No description provided for @labelLineCount.
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

  /// No description provided for @dialogItemCompareHelpIntro.
  ///
  /// In zh, this message translates to:
  /// **'该工具用于对比两件装备的期望。\n\n'**
  String get dialogItemCompareHelpIntro;

  /// No description provided for @dialogItemCompareHelpStepsTitle.
  ///
  /// In zh, this message translates to:
  /// **'使用步骤：\n'**
  String get dialogItemCompareHelpStepsTitle;

  /// No description provided for @dialogItemCompareHelpStep1.
  ///
  /// In zh, this message translates to:
  /// **'1. 确认需要对比的装备 / 宝珠 / 宝物槽位，然后将对应的物品卸下，根据此时的面板填写“无装备面板”数据；\n'**
  String get dialogItemCompareHelpStep1;

  /// No description provided for @dialogItemCompareHelpStep2.
  ///
  /// In zh, this message translates to:
  /// **'2. 将两件装备的白词条填写到“装备 1 / 装备 2”中，'**
  String get dialogItemCompareHelpStep2;

  /// No description provided for @dialogItemCompareHelpStep2Note.
  ///
  /// In zh, this message translates to:
  /// **'请注意词条类型，元素伤害统一并入 \"Element Damage\"，请自行根据单位属性填入对应元素伤害词条；\n'**
  String get dialogItemCompareHelpStep2Note;

  /// No description provided for @dialogItemCompareHelpStep3.
  ///
  /// In zh, this message translates to:
  /// **'3. 对比结果：实时显示三组 DPS 结果，并给出结论。\n\n\n'**
  String get dialogItemCompareHelpStep3;

  /// No description provided for @dialogItemCompareHelpNormalUnit.
  ///
  /// In zh, this message translates to:
  /// **'普攻型单位：'**
  String get dialogItemCompareHelpNormalUnit;

  /// No description provided for @dialogItemCompareHelpNormalUnitDesc.
  ///
  /// In zh, this message translates to:
  /// **'需要填写 Attacks Per Second 和 Increased Speed，Attack Speed % 词条参与计算。\n'**
  String get dialogItemCompareHelpNormalUnitDesc;

  /// No description provided for @dialogItemCompareHelpSkillUnit.
  ///
  /// In zh, this message translates to:
  /// **'技能型单位：'**
  String get dialogItemCompareHelpSkillUnit;

  /// No description provided for @dialogItemCompareHelpSkillUnitDesc.
  ///
  /// In zh, this message translates to:
  /// **'不填写上述两项，Attack Speed % 词条不参与计算。'**
  String get dialogItemCompareHelpSkillUnitDesc;

  /// No description provided for @dialogItemCompareHelpNoteLabel.
  ///
  /// In zh, this message translates to:
  /// **'\n\n注：'**
  String get dialogItemCompareHelpNoteLabel;

  /// No description provided for @dialogItemCompareHelpNoteDesc.
  ///
  /// In zh, this message translates to:
  /// **'宝珠、宝物等词条也可用于计算，但需要注意词条类型。'**
  String get dialogItemCompareHelpNoteDesc;

  /// No description provided for @dialogResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'是否清空所有输入？'**
  String get dialogResetConfirm;

  /// No description provided for @labelNoItemPanel.
  ///
  /// In zh, this message translates to:
  /// **'无装备面板'**
  String get labelNoItemPanel;

  /// No description provided for @actionAddLine.
  ///
  /// In zh, this message translates to:
  /// **'添加词条'**
  String get actionAddLine;

  /// No description provided for @hintSelectLineType.
  ///
  /// In zh, this message translates to:
  /// **'选择词条类型'**
  String get hintSelectLineType;

  /// No description provided for @hintValue.
  ///
  /// In zh, this message translates to:
  /// **'数值'**
  String get hintValue;

  /// No description provided for @tooltipDeleteLine.
  ///
  /// In zh, this message translates to:
  /// **'删除词条'**
  String get tooltipDeleteLine;

  /// No description provided for @labelNoCrit.
  ///
  /// In zh, this message translates to:
  /// **'无暴击'**
  String get labelNoCrit;

  /// No description provided for @labelWithCrit.
  ///
  /// In zh, this message translates to:
  /// **'有暴击'**
  String get labelWithCrit;

  /// No description provided for @labelNoItem.
  ///
  /// In zh, this message translates to:
  /// **'无装备'**
  String get labelNoItem;

  /// No description provided for @labelItemNumber.
  ///
  /// In zh, this message translates to:
  /// **'装备 {index}'**
  String labelItemNumber(int index);

  /// No description provided for @labelCompareGainSummary.
  ///
  /// In zh, this message translates to:
  /// **'装备 1 较无装备 {gain1} · 装备 2 较无装备 {gain2}'**
  String labelCompareGainSummary(String gain1, String gain2);

  /// No description provided for @compareVerdictPending.
  ///
  /// In zh, this message translates to:
  /// **'填写数据后自动对比'**
  String get compareVerdictPending;

  /// No description provided for @compareVerdictItem1.
  ///
  /// In zh, this message translates to:
  /// **'装备 1 更优{gap}'**
  String compareVerdictItem1(String gap);

  /// No description provided for @compareGapItem2.
  ///
  /// In zh, this message translates to:
  /// **'，DPS 比装备 2 高 {gain}'**
  String compareGapItem2(String gain);

  /// No description provided for @compareVerdictItem2.
  ///
  /// In zh, this message translates to:
  /// **'装备 2 更优{gap}'**
  String compareVerdictItem2(String gap);

  /// No description provided for @compareGapItem1.
  ///
  /// In zh, this message translates to:
  /// **'，DPS 比装备 1 高 {gain}'**
  String compareGapItem1(String gain);

  /// No description provided for @compareVerdictTie.
  ///
  /// In zh, this message translates to:
  /// **'两件装备 DPS 相同'**
  String get compareVerdictTie;

  /// No description provided for @labelNoDamageLines.
  ///
  /// In zh, this message translates to:
  /// **'（无输出词条）'**
  String get labelNoDamageLines;

  /// No description provided for @dialogBestLineHelpAvgDmg.
  ///
  /// In zh, this message translates to:
  /// **'Avg. Dmg 和下方列表中的 Damage 都是 Damage 与 Elemental Damage 的均值。'**
  String get dialogBestLineHelpAvgDmg;

  /// No description provided for @labelPanelWithoutItem.
  ///
  /// In zh, this message translates to:
  /// **'面板无装备数值'**
  String get labelPanelWithoutItem;

  /// No description provided for @labelLineSlot.
  ///
  /// In zh, this message translates to:
  /// **'{count} 词条'**
  String labelLineSlot(int count);

  /// No description provided for @labelComboCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 种'**
  String labelComboCount(int count);

  /// No description provided for @gameTrack.
  ///
  /// In zh, this message translates to:
  /// **'游戏轨迹'**
  String get gameTrack;

  /// No description provided for @snackSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步失败：{reason}'**
  String snackSyncFailed(String reason);

  /// No description provided for @errorGuildNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到公会「{name}」的信息'**
  String errorGuildNotFound(String name);

  /// No description provided for @emptyGuildDefaultUserHint.
  ///
  /// In zh, this message translates to:
  /// **'当前为默认用户，仅用于体验基础功能。\n请到「设置」页的「用户管理」创建自己的账号，并填写公会名。'**
  String get emptyGuildDefaultUserHint;

  /// No description provided for @emptyGuildHint.
  ///
  /// In zh, this message translates to:
  /// **'当前用户未设置公会，请先到「用户管理」中填写公会名'**
  String get emptyGuildHint;

  /// No description provided for @emptyGuildMembers.
  ///
  /// In zh, this message translates to:
  /// **'该公会暂无成员'**
  String get emptyGuildMembers;

  /// No description provided for @actionGoToUserManagement.
  ///
  /// In zh, this message translates to:
  /// **'前往用户管理'**
  String get actionGoToUserManagement;

  /// No description provided for @emptySelectMemberHint.
  ///
  /// In zh, this message translates to:
  /// **'点击左侧成员查看玩家详情'**
  String get emptySelectMemberHint;

  /// No description provided for @guildMemberCountAndScore.
  ///
  /// In zh, this message translates to:
  /// **'{count} 人 · {score}'**
  String guildMemberCountAndScore(int count, String score);

  /// No description provided for @tooltipCloseDetail.
  ///
  /// In zh, this message translates to:
  /// **'关闭详情'**
  String get tooltipCloseDetail;

  /// No description provided for @errorPlayerBanned.
  ///
  /// In zh, this message translates to:
  /// **'玩家「{name}」已被封禁'**
  String errorPlayerBanned(String name);

  /// No description provided for @labelWphHistory.
  ///
  /// In zh, this message translates to:
  /// **'每小时波速（第三方 API）'**
  String get labelWphHistory;

  /// No description provided for @labelSeason.
  ///
  /// In zh, this message translates to:
  /// **'赛季 {season}'**
  String labelSeason(String season);

  /// No description provided for @hellModeScore.
  ///
  /// In zh, this message translates to:
  /// **'无尽分数'**
  String get hellModeScore;

  /// No description provided for @lastOnline.
  ///
  /// In zh, this message translates to:
  /// **'上次在线'**
  String get lastOnline;

  /// No description provided for @unitEnabledCount.
  ///
  /// In zh, this message translates to:
  /// **'{enabled}/{total} 启用'**
  String unitEnabledCount(int enabled, int total);

  /// No description provided for @metricGoldShare.
  ///
  /// In zh, this message translates to:
  /// **'金币占比'**
  String get metricGoldShare;

  /// No description provided for @metricUnitPerWave.
  ///
  /// In zh, this message translates to:
  /// **'单位 / 波数'**
  String get metricUnitPerWave;

  /// No description provided for @metricWavePerUnit.
  ///
  /// In zh, this message translates to:
  /// **'波数 / 单位'**
  String get metricWavePerUnit;

  /// No description provided for @seasonProgress.
  ///
  /// In zh, this message translates to:
  /// **'赛季进度'**
  String get seasonProgress;

  /// No description provided for @labelStart.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get labelStart;

  /// No description provided for @labelEnd.
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get labelEnd;

  /// No description provided for @labelRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get labelRemaining;

  /// No description provided for @incomeTotal.
  ///
  /// In zh, this message translates to:
  /// **'总收入'**
  String get incomeTotal;

  /// No description provided for @tooltipInfiniteColonyRatio.
  ///
  /// In zh, this message translates to:
  /// **'殖波比'**
  String get tooltipInfiniteColonyRatio;

  /// No description provided for @tabHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get tabHome;

  /// No description provided for @income.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get income;

  /// No description provided for @wavePushIncome.
  ///
  /// In zh, this message translates to:
  /// **'推波收益'**
  String get wavePushIncome;

  /// No description provided for @infiniteColony.
  ///
  /// In zh, this message translates to:
  /// **'通天塔'**
  String get infiniteColony;

  /// No description provided for @guildTotalScore.
  ///
  /// In zh, this message translates to:
  /// **'公会总分'**
  String get guildTotalScore;

  /// No description provided for @sectionQuickAccess.
  ///
  /// In zh, this message translates to:
  /// **'快捷入口'**
  String get sectionQuickAccess;

  /// No description provided for @tabCheckCurrentUserWph.
  ///
  /// In zh, this message translates to:
  /// **'查询波速'**
  String get tabCheckCurrentUserWph;

  /// No description provided for @labelExpectedValueOfEachLine.
  ///
  /// In zh, this message translates to:
  /// **'装备词条期望值'**
  String get labelExpectedValueOfEachLine;

  /// No description provided for @toolSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get toolSearch;

  /// No description provided for @labelName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get labelName;

  /// No description provided for @toolSearchUser.
  ///
  /// In zh, this message translates to:
  /// **'搜索玩家'**
  String get toolSearchUser;

  /// No description provided for @toolSearchGuild.
  ///
  /// In zh, this message translates to:
  /// **'搜索公会'**
  String get toolSearchGuild;

  /// No description provided for @sidebarCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起侧栏'**
  String get sidebarCollapse;

  /// No description provided for @sidebarExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开侧栏'**
  String get sidebarExpand;

  /// No description provided for @actionResetToDefault.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get actionResetToDefault;

  /// No description provided for @toolQuickCalculation.
  ///
  /// In zh, this message translates to:
  /// **'快速计算'**
  String get toolQuickCalculation;

  /// No description provided for @quickCalcHint.
  ///
  /// In zh, this message translates to:
  /// **'输入任意一项并锁定，填写其余项将自动计算'**
  String get quickCalcHint;

  /// No description provided for @quickCalcLock.
  ///
  /// In zh, this message translates to:
  /// **'锁定该项'**
  String get quickCalcLock;

  /// No description provided for @quickCalcUnlock.
  ///
  /// In zh, this message translates to:
  /// **'解锁该项'**
  String get quickCalcUnlock;

  /// No description provided for @quickCalcFill.
  ///
  /// In zh, this message translates to:
  /// **'填入'**
  String get quickCalcFill;

  /// No description provided for @reward.
  ///
  /// In zh, this message translates to:
  /// **'奖励'**
  String get reward;

  /// No description provided for @incomeTrend.
  ///
  /// In zh, this message translates to:
  /// **'经济趋势预测'**
  String get incomeTrend;

  /// No description provided for @incomeTrendNow.
  ///
  /// In zh, this message translates to:
  /// **'当前数据'**
  String get incomeTrendNow;

  /// No description provided for @incomeTrendEnd.
  ///
  /// In zh, this message translates to:
  /// **'结束数据'**
  String get incomeTrendEnd;

  /// No description provided for @incomeTrendCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get incomeTrendCustom;

  /// No description provided for @incomeTrendDaysHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入天数'**
  String get incomeTrendDaysHint;

  /// No description provided for @incomeTrendDaysInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入大于 0 的整数'**
  String get incomeTrendDaysInvalid;

  /// No description provided for @dataDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'数据仅供参考'**
  String get dataDisclaimer;

  /// No description provided for @fromDev.
  ///
  /// In zh, this message translates to:
  /// **'欢迎加入 POC 谢谢喵！'**
  String get fromDev;

  /// No description provided for @labelGabBonusNote.
  ///
  /// In zh, this message translates to:
  /// **'破挂请点击「FAB」按钮后保存，金挂收益将被视为 0%'**
  String get labelGabBonusNote;

  /// No description provided for @dailyIncome.
  ///
  /// In zh, this message translates to:
  /// **'每日收入'**
  String get dailyIncome;
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
