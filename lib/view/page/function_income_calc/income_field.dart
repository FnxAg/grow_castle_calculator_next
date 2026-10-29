import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/model/userdata/user_data.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:material_ui/material_ui.dart';

/// 金挂 / 时挂时间合计超过 24h 的提示
const String _timeSumError = 'gabTime + tabTime > 24h';

/// 对话框里展示的原始输入值（整数不带小数位）
String _doubleText(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String? _checkTimeSum(double other, String text) {
  final value = double.tryParse(text) ?? 0.0;
  return value + other > 24.0 + 1e-9 ? _timeSumError : null;
}

/// 收入页可编辑的数值项：标题、输入限制、取值与保存都集中在这里
enum IncomeField {
  /// 通天塔等级
  infiniteColony,

  /// 额外殖民地 C
  icCooldown,

  /// 额外殖民地 G
  icGold,

  /// 金挂平均收益
  gabBonus,

  /// 每日金挂时间
  gabTime,

  /// 每日时挂时间
  tabTime;

  String label(AppLocalizations l10n) => switch (this) {
    infiniteColony => l10n.labelInfiniteColonyLevel,
    icCooldown => l10n.labelExtraColonyCooldownSkill,
    icGold => l10n.labelExtraColonyGoldSkill,
    gabBonus => l10n.labelGabAverageBonus,
    gabTime => l10n.labelDailyGabTime,
    tabTime => l10n.labelDailyTabTime,
  };

  /// 输入是否只允许整数
  bool get digitsOnly => switch (this) {
    infiniteColony || icCooldown || icGold => true,
    gabBonus || gabTime || tabTime => false,
  };

  String get prefixText => switch (this) {
    infiniteColony => 'Lv.',
    _ => '',
  };

  String get suffixText => switch (this) {
    gabBonus => '%',
    gabTime || tabTime => 'h',
    _ => '',
  };

  /// 列表行展示的值
  String display(UserData user) => switch (this) {
    infiniteColony => 'Lv.${user.infiniteColony.format()}',
    icCooldown => user.icCooldownSkill.format(),
    icGold => user.icGoldSkill.format(),
    gabBonus => '${user.gabBonus.format(fractionDigits: 2)}%',
    gabTime => '${user.gabTime.format(fractionDigits: 2)}h',
    tabTime => '${user.tabTime.format(fractionDigits: 2)}h',
  };

  /// 对话框的初始文本
  String inputText(UserData user) => switch (this) {
    infiniteColony => '${user.infiniteColony}',
    icCooldown => '${user.icCooldownSkill}',
    icGold => '${user.icGoldSkill}',
    gabBonus => _doubleText(user.gabBonus),
    gabTime => _doubleText(user.gabTime),
    tabTime => _doubleText(user.tabTime),
  };

  /// 行内错误提示
  String? error(UserData user) => switch (this) {
    gabTime ||
    tabTime => user.gabTime + user.tabTime > 24.0 + 1e-9 ? _timeSumError : null,
    _ => null,
  };

  /// 保存前校验
  String? validate(UserData user, String text) => switch (this) {
    gabTime => _checkTimeSum(user.tabTime, text),
    tabTime => _checkTimeSum(user.gabTime, text),
    _ => null,
  };

  /// 应用输入
  void save(Users users, String text) {
    switch (this) {
      case infiniteColony:
        users.setCurrentUserInfiniteColony(int.tryParse(text) ?? 0);
      case icCooldown:
        users.setCurrentUserIcCooldown(int.tryParse(text) ?? 0);
      case icGold:
        users.setCurrentUserIcGold(int.tryParse(text) ?? 0);
      case gabBonus:
        users.setCurrentUserGabBonus(double.tryParse(text) ?? 0.0);
      case gabTime:
        users.setCurrentUserGabTime(double.tryParse(text) ?? 0.0);
      case tabTime:
        users.setCurrentUserTabTime(double.tryParse(text) ?? 0.0);
    }
  }

  /// 对话框附加说明
  Widget? extraDialogContent(
    BuildContext context,
    TextEditingController controller,
  ) => switch (this) {
    gabBonus => Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          AppLocalizations.of(context).labelGabBonusNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    _ => null,
  };

  /// 对话框附加按钮，通过 [controller] 改写输入内容
  List<Widget> extraDialogActions(
    BuildContext context,
    TextEditingController controller,
  ) => switch (this) {
    gabBonus => [
        TextButton(
          onPressed: () {
            controller.text = '0';
          },
          child: Text('FAB'),
        ),
      ],
    _ => const [],
  };
}
