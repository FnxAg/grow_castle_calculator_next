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
  ///
  /// 例：`formatCompact` 的 `english` 参数——中文用 万/亿，其余语言用 K/M/B。
  bool get isChineseLocale => Localizations.localeOf(this).languageCode == 'zh';
}
