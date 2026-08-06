import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 跳波状态页：WPH/WPS 实时计算 + 游戏速度等参数设置。
///
/// 参数与理论 WPH 由 InfoStore 持久化（data 字段，按用户隔离）；
/// 计算逻辑见 core/calc/wave_speed.dart。
class WaveStatusPage extends StatelessWidget {
  const WaveStatusPage({super.key});

  // ── 选择框选项 ──────────────────────────────────────────────────────────

  static const _gameSpeedEntries = [(0, '2速'), (1, '2速+10广'), (2, '3速')];
  static const _chronoEntries = [
    (0, '白闹钟(+10%)'),
    (1, '黄闹钟(+14%)'),
    (2, '蓝闹钟(+20%)'),
  ];
  static const _equipEntries = [(false, '未装备'), (true, '已装备')];
  static const _devilHornEntries = [
    (1, '无'),
    (2, '+1'),
    (3, '+2'),
    (4, '+3'),
    (5, '+4'),
    (6, '+5'),
  ];
  static const _autoBattleEntries = [(true, '金挂(GAB) / 破挂(NAB)'), (false, '时挂(TAB)')];

  // 各选择框的 key：点击 ListTile 时定位按钮合成点击以打开下拉框
  static final _gameSpeedKey = GlobalKey();
  static final _chronoKey = GlobalKey();
  static final _hornKey = GlobalKey();
  static final _goldenHornKey = GlobalKey();
  static final _devilHornKey = GlobalKey();
  static final _autoBattleKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return UserPageScaffold(
      title: '跳波状态',
      // 监听 store：参数变更与切换用户都驱动列表重建，数据始终来自当前用户
      body: ValueListenableBuilder<int>(
        valueListenable: Stores.infoStore.waveStatusNotifier,
        builder: (context, _, _) {
          final store = Stores.infoStore;
          final wph = store.getCurrentUserTheoreticalWph();
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _ResultCard(wph: wph, wps: wph * 120),
              ),
              // 游戏速度：gameSpeed
              _settingTile<int>(
                context,
                label: '游戏速度',
                dropdownKey: _gameSpeedKey,
                value: store.getCurrentUserGameSpeed(),
                entries: _gameSpeedEntries,
                onChanged: store.setCurrentUserGameSpeed,
              ),
              // 闹钟转职：chronoClass
              _settingTile<int>(
                context,
                label: '闹钟类型',
                dropdownKey: _chronoKey,
                value: store.getCurrentUserChronoClass(),
                entries: _chronoEntries,
                onChanged: store.setCurrentUserChronoClass,
              ),
              // 10%角：horn
              _settingTile<bool>(
                context,
                label: '10%角',
                dropdownKey: _hornKey,
                value: store.getCurrentUserHorn(),
                entries: _equipEntries,
                onChanged: store.setCurrentUserHorn,
              ),
              // 30%角：goldenHorn
              _settingTile<bool>(
                context,
                label: '30%角',
                dropdownKey: _goldenHornKey,
                value: store.getCurrentUserGoldenHorn(),
                entries: _equipEntries,
                onChanged: store.setCurrentUserGoldenHorn,
              ),
              // 恶魔号角跳波数：devilHornSkip
              _settingTile<int>(
                context,
                label: '恶魔号角跳波数',
                dropdownKey: _devilHornKey,
                value: store.getCurrentUserDevilHornSkip(),
                entries: _devilHornEntries,
                onChanged: store.setCurrentUserDevilHornSkip,
              ),
              // 挂机类型：isGoldAutoBattle
              _settingTile<bool>(
                context,
                label: '挂机类型',
                dropdownKey: _autoBattleKey,
                value: store.getCurrentUserIsGoldAutoBattle(),
                entries: _autoBattleEntries,
                infoContent: const Text(
                  '时挂 (TAB) 选项默认启用释放乐队技能 (BAND SKILL) ，'
                  '且兽人号角 (ORC BAND) 和经验号角 (MILITARY BANDS(F)) 同时上场。',
                ),
                onChanged: store.setCurrentUserIsGoldAutoBattle,
              ),
            ],
          );
        },
      ),
    );
  }

  /// 参数设置行：左侧标签（可选 info 说明）+ 右侧选择框；
  /// 点击整行（[dropdownKey] 对应按钮的 key）也能打开下拉框
  Widget _settingTile<T>(
    BuildContext context, {
    required String label,
    required GlobalKey dropdownKey,
    required T value,
    required List<(T, String)> entries,
    Widget? infoContent,
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      onTap: () => _openDropdown(dropdownKey),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (infoContent != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(label),
                    content: infoContent,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
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
      trailing: _TrailingDropdown<T>(
        buttonKey: dropdownKey,
        value: value,
        entries: entries,
        onChanged: onChanged,
      ),
    );
  }

  /// 程序化打开 [key] 对应的 DropdownButton：向按钮中心合成一次点击事件，
  /// 走正常的命中测试与手势竞技场，等价于用户点按按钮。
  /// DropdownButton 没有公开的打开 API，只能用这种方式触发。
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
  const _ResultCard({required this.wph, required this.wps});

  // 理论wph: theoreticalWph
  final int wph;
  // 理论wps: theoreticalWps
  final int wps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: _HeroMetric(label: 'WPH', value: '$wph')),
            Container(
              width: 1,
              height: 36,
              color: colorScheme.onPrimaryContainer.withAlpha(40),
            ),
            Expanded(child: _HeroMetric(label: 'WPS', value: '$wps')),
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

/// ListTile trailing 的紧凑选择框（M3 主题色，无下划线）
class _TrailingDropdown<T> extends StatelessWidget {
  const _TrailingDropdown({
    required this.buttonKey,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  /// 挂在 DropdownButton 上，供页面点击 ListTile 时定位按钮
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
        // 选中文本右对齐：贴着右侧的下拉箭头
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
            DropdownMenuItem<T>(value: v, child: Text(label)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
