import 'package:flutter/gestures.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:material_ui/material_ui.dart';

/// 跳波状态页
class WaveStatusPage extends StatelessWidget {
  const WaveStatusPage({super.key});

  /// 下拉项文案随语言变化，故按当前 [AppLocalizations] 现取
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

  static final _gameSpeedKey = GlobalKey();
  static final _chronoKey = GlobalKey();
  static final _hornKey = GlobalKey();
  static final _goldenHornKey = GlobalKey();
  static final _devilHornKey = GlobalKey();
  static final _autoBattleKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = Stores.infoStore;
    return ListenableBuilder(
      listenable: Listenable.merge([
        store.currentUserNotifier,
        store.dataVersionNotifier,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: .start,
              children: [Text(l10n.waveStatus), _AppBarInfo()],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.sectionInfo),
                    content: Text(l10n.dialogWaveStatusDisclaimer),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.actionClose),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: ValueListenableBuilder<int>(
            valueListenable: Stores.infoStore.waveStatusNotifier,
            builder: (context, _, _) {
              final store = Stores.infoStore;
              final wph = store.getCurrentUserWph();
              final rwph = store.getCurrentUserRwph();
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _ResultCard(wph: wph, rwph: rwph, wps: wph * 120),
                  ),
                  // 游戏速度：gameSpeed
                  _settingTile<int>(
                    context,
                    label: l10n.labelGameSpeed,
                    dropdownKey: _gameSpeedKey,
                    value: store.getCurrentUserGameSpeed(),
                    entries: _gameSpeedEntries(l10n),
                    onChanged: store.setCurrentUserGameSpeed,
                  ),
                  // 闹钟转职：chronoClass
                  _settingTile<int>(
                    context,
                    label: l10n.labelChronoType,
                    dropdownKey: _chronoKey,
                    value: store.getCurrentUserChronoClass(),
                    entries: _chronoEntries(l10n),
                    onChanged: store.setCurrentUserChronoClass,
                  ),
                  // 10%角：horn
                  _settingTile<bool>(
                    context,
                    label: l10n.labelHorn10,
                    dropdownKey: _hornKey,
                    value: store.getCurrentUserHorn(),
                    entries: _equipEntries(l10n),
                    onChanged: store.setCurrentUserHorn,
                  ),
                  // 30%角：goldenHorn
                  _settingTile<bool>(
                    context,
                    label: l10n.labelHorn30,
                    dropdownKey: _goldenHornKey,
                    value: store.getCurrentUserGoldenHorn(),
                    entries: _equipEntries(l10n),
                    onChanged: store.setCurrentUserGoldenHorn,
                  ),
                  // 恶魔号角跳波数：devilHornSkip
                  _settingTile<int>(
                    context,
                    label: l10n.labelDevilHornSkip,
                    dropdownKey: _devilHornKey,
                    value: store.getCurrentUserDevilHornSkip(),
                    entries: _devilHornEntries(l10n),
                    onChanged: store.setCurrentUserDevilHornSkip,
                  ),
                  // 挂机类型：isGoldAutoBattle
                  _settingTile<bool>(
                    context,
                    label: l10n.labelAutoBattleType,
                    dropdownKey: _autoBattleKey,
                    value: store.getCurrentUserIsGoldAutoBattle(),
                    entries: _autoBattleEntries(l10n),
                    infoContent: Text(l10n.infoAutoBattleTab),
                    onChanged: store.setCurrentUserIsGoldAutoBattle,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _settingTile<T>(
    BuildContext context, {
    required String label,
    required GlobalKey dropdownKey,
    required T value,
    required List<(T, String)> entries,
    Widget? infoContent,
    required ValueChanged<T> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => ListTile(
        onTap: () => _openDropdown(dropdownKey),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 英文标签比中文长得多，给它弹性并允许省略
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (infoContent != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(label),
                      content: infoContent,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            AppLocalizations.of(context).actionCancel,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        // 英文选项明显长于中文，若不加约束，trailing 会占满整行并触发
        // ListTile 的 "Trailing widget consumes the entire tile width" 断言
        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
          child: _TrailingDropdown<T>(
            buttonKey: dropdownKey,
            value: value,
            entries: entries,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  static void _openDropdown(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    GestureBinding.instance
      ..handlePointerEvent(PointerDownEvent(position: center))
      ..handlePointerEvent(PointerUpEvent(position: center));
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

/// 结果卡内的单个指标：小标签 + 加粗大数值
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
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TrailingDropdown<T> extends StatelessWidget {
  const _TrailingDropdown({
    required this.buttonKey,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  final GlobalKey buttonKey;
  final T value;
  final List<(T, String)> entries;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: buttonKey,
        value: value,
        isDense: true,
        // 与调用方的宽度约束配合：撑满可用宽度并让超长选项省略，
        // 而不是把文字挤出边界
        isExpanded: true,
        alignment: AlignmentDirectional.centerEnd,
        borderRadius: BorderRadius.circular(8),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          size: 22,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        items: [
          for (final (v, label) in entries)
            DropdownMenuItem<T>(
              value: v,
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
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
