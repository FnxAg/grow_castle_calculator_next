import 'package:material_ui/material_ui.dart';

/// 当前 locale 的读取扩展。
///
/// 文案本身走 gen-l10n 的 `AppLocalizations`，这里只处理"同一份数据按语言换
/// 写法"的场景（数字单位、日期格式这类），它们不属于词条表。
///
/// 与 [ResponsiveContext] 同理：语言取 `Localizations.localeOf`，即 MaterialApp
/// 解析后的实际语言（含用户在设置里的覆盖），而不是 `PlatformDispatcher.locale`。
extension L10nLocale on BuildContext {
  /// 界面语言是否为中文。
  bool get isChineseLocale => Localizations.localeOf(this).languageCode == 'zh';

  /// 界面语言是否为繁体中文（`zh_Hant`）。
  ///
  /// 只影响中文字形本身有简繁之分的场合，如 `formatCompact` 的 `traditional`
  /// 参数（繁体用「億」而非「亿」）。
  bool get isTraditionalChineseLocale =>
      Localizations.localeOf(this).scriptCode == 'Hant';

  /// `formatCompact` 是否使用英文缩写单位（K/M/B）。
  ///
  /// 非中文界面固定英文；中文界面由设置项决定，默认中文（万/亿）。
  bool get isCompactUnitEnglish =>
      !isChineseLocale || CompactUnitScope.of(this);
}

/// 把"中文界面下用英文缩写单位"的设置下发给 [L10nLocale.isCompactUnitEnglish]
/// 的读取者；设置变化时依赖它的界面跟着重建。
class CompactUnitScope extends InheritedNotifier<ValueNotifier<bool>> {
  const CompactUnitScope({
    super.key,
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CompactUnitScope>()
          ?.notifier
          ?.value ??
      false;
}
