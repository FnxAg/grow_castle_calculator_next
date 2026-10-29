import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:material_ui/material_ui.dart';

/// 跳波状态页
class WaveStatusPage extends ConsumerWidget {
  const WaveStatusPage({super.key});

  static List<(int, String)> _gameSpeedEntries(AppLocalizations l10n) => [
    (0, l10n.optionSpeed2x),
    (1, l10n.optionSpeed2xAds10),
    (2, l10n.optionSpeed3x),
  ];

  static List<(int, String)> _chronoEntries(AppLocalizations l10n) => [
    (0, l10n.optionChronoWhite),
    (1, l10n.optionChronoYellow),
    (2, l10n.optionChronoBlue),
  ];

  static List<(bool, String)> _equipEntries(AppLocalizations l10n) => [
    (false, l10n.optionNotEquipped),
    (true, l10n.optionEquipped),
  ];

  static List<(int, String)> _devilHornEntries(AppLocalizations l10n) => [
    (1, l10n.optionNone),
    (2, '+1'),
    (3, '+2'),
    (4, '+3'),
    (5, '+4'),
    (6, '+5'),
  ];

  static List<(bool, String)> _autoBattleEntries(AppLocalizations l10n) => [
    (true, l10n.optionAutoBattleGoldBreak),
    (false, l10n.optionAutoBattleTime),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final wph = ref.watch(theoreticalWphProvider);
    final rwph = ref.watch(theoreticalRwphProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.waveStatus), _AppBarInfo()],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _ResultCard(wph: wph, rwph: rwph, wps: wph * 120),
            ),
            // 游戏速度：gameSpeed
            ExpansionTile(
              title: Text(l10n.labelGameSpeed),
              subtitle: Text(
                _gameSpeedEntries(l10n)
                    .firstWhere((entry) => entry.$1 == user.gameSpeed)
                    .$2,
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              children: [
                RadioGroup<int>(
                  groupValue: user.gameSpeed,
                  onChanged: (value) {
                    if (value != null) {
                      ref.users.setCurrentUserGameSpeed(value);
                    }
                  },
                  child: Column(
                    children: [
                      for (final (value, label) in _gameSpeedEntries(l10n))
                        RadioListTile<int>(title: Text(label), value: value),
                    ],
                  ),
                ),
              ],
            ),
            // 闹钟转职：chronoClass
            ExpansionTile(
              title: Text(l10n.labelChronoType),
              subtitle: Text(
                _chronoEntries(l10n)
                    .firstWhere((entry) => entry.$1 == user.chronoClass)
                    .$2,
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              children: [
                RadioGroup<int>(
                  groupValue: user.chronoClass,
                  onChanged: (value) {
                    if (value != null) {
                      ref.users.setCurrentUserChronoClass(value);
                    }
                  },
                  child: Column(
                    children: [
                      for (final (value, label) in _chronoEntries(l10n))
                        RadioListTile<int>(title: Text(label), value: value),
                    ],
                  ),
                ),
              ],
            ),
            // 10%角：horn
            SwitchListTile(
              title: Text(l10n.labelHorn10),
              subtitle: Text(
                _equipEntries(l10n)
                    .firstWhere((entry) => entry.$1 == user.horn)
                    .$2,
              ),
              value: user.horn,
              onChanged: (value) => ref.users.setCurrentUserHorn(value),
            ),
            // 30%角：goldenHorn
            SwitchListTile(
              title: Text(l10n.labelHorn30),
              subtitle: Text(
                _equipEntries(l10n)
                    .firstWhere((entry) => entry.$1 == user.goldenHorn)
                    .$2,
              ),
              value: user.goldenHorn,
              onChanged: (value) => ref.users.setCurrentUserGoldenHorn(value),
            ),
            // 恶魔号角跳波数：devilHornSkip
            ExpansionTile(
              title: Text(l10n.labelDevilHornSkip),
              subtitle: Text(
                _devilHornEntries(l10n)
                    .firstWhere((entry) => entry.$1 == user.devilHornSkip)
                    .$2,
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              children: [
                RadioGroup<int>(
                  groupValue: user.devilHornSkip,
                  onChanged: (value) {
                    if (value != null) {
                      ref.users.setCurrentUserDevilHornSkip(value);
                    }
                  },
                  child: Column(
                    children: [
                      for (final (value, label) in _devilHornEntries(l10n))
                        RadioListTile<int>(title: Text(label), value: value),
                    ],
                  ),
                ),
              ],
            ),
            // 挂机类型：isGoldAutoBattle
            SwitchListTile(
              title: Text(l10n.labelAutoBattleType),
              // subtitle: Text(l10n.infoAutoBattleTab),
              subtitle: Text(
                _autoBattleEntries(l10n)
                    .firstWhere((entry) => entry.$1 == user.isGoldAutoBattle)
                    .$2,
              ),
              value: !user.isGoldAutoBattle,
              onChanged: (value) =>
                  ref.users.setCurrentUserIsGoldAutoBattle(!value),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.dataDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// WPH / WPS 结果展示卡
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.wph, required this.rwph, required this.wps});

  /// 理论 WPH
  final int wph;

  /// 理论 RWPH
  final int rwph;

  /// 理论 WPS（wph * 120）
  final int wps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _HeroMetric(label: 'RWPH', value: '$rwph'),
            ),
            Container(
              width: 1,
              height: 36,
              color: colorScheme.onPrimaryContainer.withAlpha(40),
            ),
            Expanded(
              child: _HeroMetric(label: 'WPH', value: '$wph'),
            ),
            Container(
              width: 1,
              height: 36,
              color: colorScheme.onPrimaryContainer.withAlpha(40),
            ),
            Expanded(
              child: _HeroMetric(label: 'WPS', value: '$wps'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 结果卡内的单个指标
class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withAlpha(179),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedTextSwitcher(
          alignment: .center,
          child: Text(
            value,
            key: ValueKey(value),
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = [CurrentUser()];
    return AppBarInfo(children: segments);
  }
}
