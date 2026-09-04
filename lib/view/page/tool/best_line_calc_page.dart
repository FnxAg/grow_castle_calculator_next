import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grow_castle_calculator_next/core/calc/item_dps.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 词条数量搭配：(Damage, Critical Chance, Critical Damage, Attack Speed) 各几条。
///
/// 装备加成不提供 More Damage，故只枚举四种输出词条。
typedef _LineCombo = (int, int, int, int);

/// 词条位上限 [slot] 的全部数量搭配：每种词条 0–4 条、
/// 合计不超过 [slot]（其余词条位为不影响本 DPS 模型的词条）。
List<_LineCombo> _lineCombos(int slot) {
  return [
    for (var damage = 0; damage <= 4; damage++)
      for (var chance = 0; chance <= 4; chance++)
        for (var critDmg = 0; critDmg <= 4; critDmg++)
          for (var atkSpeed = 0; atkSpeed <= 4; atkSpeed++)
            if (damage + chance + critDmg + atkSpeed <= slot)
              (damage, chance, critDmg, atkSpeed),
  ];
}

/// 最优词条组合计算
class BestLineCalcPage extends StatefulWidget {
  const BestLineCalcPage({super.key});

  @override
  State<BestLineCalcPage> createState() => _BestLineCalcPageState();
}

class _BestLineCalcPageState extends State<BestLineCalcPage> {
  /// $0 Damage、$1 Critical Chance、$2 Critical Damage、$3 Attack Speed
  static const List<(String name, String short, double min, double max)>
  presetLines = [
    ('Damage', 'Avg. Dmg', 18, 25),
    ('Critical Chance', 'Crit. Chance', 9, 10),
    ('Critical Damage', 'Crit. Dmg', 44, 50),
    ('Attack Speed', 'Atk. Speed', 18, 20),
  ];

  /// 6 词条位搭配（190 种）
  static final List<_LineCombo> sixLineNum = _lineCombos(6);

  /// 5 词条位搭配（122 种）
  static final List<_LineCombo> fiveLineNum = _lineCombos(5);

  /// 4 词条位搭配（70 种）
  static final List<_LineCombo> fourLineNum = _lineCombos(4);

  /// 基础面板输入：Base Attack、每秒攻击次数与 More Dmg 都是乘性/线性倍率，
  /// 会在“提升比例”中约去，页面不提供；保留的均为与词条收益交互的百分比输入
  final _increasedDmgCtrl = TextEditingController();
  final _critChanceCtrl = TextEditingController();
  final _critDmgCtrl = TextEditingController();
  final _speedCtrl = TextEditingController();

  List<TextEditingController> get _baseCtrls => [
    _increasedDmgCtrl,
    _critChanceCtrl,
    _critDmgCtrl,
    _speedCtrl,
  ];

  /// 各词条的预设单条数值（默认取各自量程上限，拖动条可调）
  late final List<double> _presetValues = [
    for (final (_, _, _, max) in presetLines) max,
  ];

  /// 当前查看的搭配组词条位数量（6 / 5 / 4）
  int _lineSlots = 6;

  /// 攻速开关：开启后 Attack Speed 词条才参与攻速公式（配合 Increased Speed）；
  /// 关闭时按技能型处理，词条不参与
  bool _speedEnabled = false;

  @override
  void initState() {
    super.initState();
    for (final ctrl in _baseCtrls) {
      ctrl.addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    for (final ctrl in _baseCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onInputChanged() => setState(() {});

  double _valueOf(TextEditingController ctrl) =>
      double.tryParse(ctrl.text.trim()) ?? 0;

  /// 面板与某数量搭配共用的 DPS 计算，与“装备对比”同一模型。
  ///
  /// Base Attack、每秒攻击次数、More Dmg 都是乘性/线性倍率，在本页的
  /// “提升比例”中会约去，故固定为常数（1 / 1 / 0）。攻速开关 [_speedEnabled]
  /// 关闭时按技能型处理（Attack Speed 词条不参与）；开启时传入
  /// [increasedSpeed]，留空按 0。
  ItemDpsResult _compute({List<ItemDpsLine> lines = const []}) {
    return computeItemDps(
      baseAttack: 1,
      increasedDmg: _valueOf(_increasedDmgCtrl),
      moreDmg: 0,
      critChance: _valueOf(_critChanceCtrl),
      critDmg: _valueOf(_critDmgCtrl) == 0 ? 100 : _valueOf(_critDmgCtrl),
      baseAps: 1,
      increasedSpeed: _speedEnabled ? _valueOf(_speedCtrl) : null,
      lines: lines,
    );
  }

  /// 某数量搭配 + 预设数值下的 DPS
  ///
  /// Damage/Critical Chance/Critical Damage 词条按条数累加进面板，
  /// Attack Speed 词条按条数累加进攻速。
  ItemDpsResult _resultOf(_LineCombo combo) {
    final (damage, chance, critDmg, atkSpeed) = combo;
    final presets = _presetValues;
    return _compute(
      lines: [
        if (damage > 0)
          (line: ItemLine.damagePercent, value: presets[0] * damage),
        if (chance > 0)
          (line: ItemLine.criticalChance, value: presets[1] * chance),
        if (critDmg > 0)
          (line: ItemLine.criticalDamage, value: presets[2] * critDmg),
        if (atkSpeed > 0)
          (line: ItemLine.attackSpeed, value: presets[3] * atkSpeed),
      ],
    );
  }

  /// 全部搭配按“较基础面板的提升”降序；提升相同保持枚举顺序。
  ///
  /// 提升 = 搭配 DPS / 基础 DPS − 1，与 Base Attack、攻速基准无关（约去）。
  List<(int index, _LineCombo combo, double gain)> _ranked(
    List<_LineCombo> combos,
    ItemDpsResult base,
  ) {
    final baseDps = base.dps;
    final items = <(int, _LineCombo, double)>[
      for (final (i, combo) in combos.indexed)
        (i, combo, baseDps > 0 ? _resultOf(combo).dps / baseDps - 1 : 0),
    ];
    items.sort((a, b) {
      final byGain = b.$3.compareTo(a.$3);
      return byGain != 0 ? byGain : a.$1.compareTo(b.$1);
    });
    return items;
  }

  String _comboText(_LineCombo combo) {
    final (damage, chance, critDmg, atkSpeed) = combo;
    final tokens = <String>[
      if (damage > 0) '${presetLines[0].$1} ×$damage',
      if (chance > 0) '${presetLines[1].$1} ×$chance',
      if (critDmg > 0) '${presetLines[2].$1} ×$critDmg',
      if (atkSpeed > 0) '${presetLines[3].$1} ×$atkSpeed',
    ];
    return tokens.isEmpty ? '（无输出词条）' : tokens.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final combos = switch (_lineSlots) {
      6 => sixLineNum,
      5 => fiveLineNum,
      _ => fourLineNum,
    };
    final base = _compute();
    final ranked = _ranked(combos, base);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('最优装备词条组合'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使用说明',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                scrollable: true,
                title: const Text('使用说明'),
                content: MarkdownBody(data: _helpMarkdown),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _buildPresetStrip(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ranked.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildBasePanel(context);
          }
          if (index == 1) {
            return _buildListHeader(context, ranked.length);
          }
          final (_, combo, gain) = ranked[index - 2];
          final best = index == 2;
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            selected: best,
            title: Text(_comboText(combo)),
            trailing: Text(
              _gainText(gain),
              style: best
                  ? TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ── AppBar 底部：词条预设数值拖动条 ─────────────────────────

  Widget _buildPresetStrip(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          for (final (i, (_, short, min, max)) in presetLines.indexed)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$short ${_numText(_presetValues[i])}%',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: Slider(
                      value: _presetValues[i].clamp(min, max),
                      min: min,
                      max: max,
                      onChanged: (v) => setState(() {
                        _presetValues[i] = (v * 10).round() / 10;
                      }),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── 基础数值输入面板 ───────────────────────────────────────

  Widget _buildBasePanel(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '面板无装备数值',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            _baseField('Increased Dmg', _increasedDmgCtrl),
            _baseField('Critical Chance', _critChanceCtrl),
            _baseField('Critical Dmg', _critDmgCtrl),
            _baseField(
              'Increased Speed',
              _speedCtrl,
              prefix: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _speedEnabled,
                  onChanged: (v) => setState(() => _speedEnabled = v!),
                ),
              ),
              enabled: _speedEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _baseField(
    String label,
    TextEditingController ctrl, {
    Widget? prefix,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Spacer(),
          if (prefix != null) ...[prefix, const SizedBox(width: 16)],
          SizedBox(
            width: 80,
            child: SelectAllTextField(
              controller: ctrl,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(isDense: true, suffixText: '%'),
            ),
          ),
        ],
      ),
    );
  }

  // ── 列表头部（词条位切换 + 提示） ──────────────────────────

  Widget _buildListHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: 6, label: Text('6 词条')),
              ButtonSegment(value: 5, label: Text('5 词条')),
              ButtonSegment(value: 4, label: Text('4 词条')),
            ],
            selected: {_lineSlots},
            onSelectionChanged: (selection) => setState(() {
              _lineSlots = selection.first;
            }),
          ),
          const Spacer(),
          Text(
            '共 $count 种',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── 文本工具 ───────────────────────────────────────────────

  /// 单条数值文本：整数不带小数点，其余保留 1 位小数
  String _numText(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);

  String _gainText(double gain) {
    if (gain == 0) {
      return '0%';
    }
    final value = gain * 100;
    final abs = value.abs();
    final prefix = value < 0 ? '-' : '+';
    final text = abs == abs.roundToDouble()
        ? '${abs.round()}%'
        : '${abs.toStringAsFixed(1)}%';
    return '$prefix$text';
  }

  /// 使用说明（Markdown）：词条区间随 [presetLines] 动态生成
  String get _helpMarkdown {
    return '**Avg. Dmg** 和 **下方列表中的 Damage** 都是 Damage 与 Elemental Damage 的均值。';
  }
}
