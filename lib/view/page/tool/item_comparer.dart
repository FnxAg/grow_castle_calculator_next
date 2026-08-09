import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/calc/item_dps.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/item_comparer_store.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 装备对比：填写无装备面板与两件装备的 DPS 相关白词条，
/// 通过期望 DPS（暴击与非暴击的加权平均）判断哪件装备更好。
class ItemComparerPage extends StatefulWidget {
  const ItemComparerPage({super.key});

  @override
  State<ItemComparerPage> createState() => _ItemComparerPageState();
}

/// 一件装备最多可对比的词条数
/// （真实装备第 1、2 槽必定白，第 3 槽为白或红，最多 3 白）
const int kMaxLinesPerItem = 3;

/// 词条下拉选项：白词条或特殊词条。
/// - Element Damage：白词条池中 5 种元素伤害的整合项，与普通增伤无差异
/// - More Dmg：累乘进更多伤害（见 computeItemDps）
class _LineOption {
  const _LineOption._({
    this.line,
    this.isMoreDmg = false,
    this.isElementDamage = false,
  });

  /// 普通白词条
  const _LineOption.item(ItemLine line) : this._(line: line);

  /// Element Damage（元素伤害整合项，视为普通增伤）
  const _LineOption.elementDamage() : this._(isElementDamage: true);

  /// More Dmg 词条
  const _LineOption.moreDmg() : this._(isMoreDmg: true);

  final ItemLine? line;
  final bool isMoreDmg;
  final bool isElementDamage;

  String get label => isMoreDmg
      ? 'More Dmg %'
      : isElementDamage
          ? 'Element Damage %'
          : line!.label;

  bool get isPercent => isMoreDmg || isElementDamage || line!.isPercent;

  /// 值相等：恢复内存时新建的实例需与下拉框 items 中的实例匹配
  /// （DropdownButton 通过 == 查找当前选中项，身份比较会断言失败）
  @override
  bool operator ==(Object other) =>
      other is _LineOption &&
      other.isMoreDmg == isMoreDmg &&
      other.isElementDamage == isElementDamage &&
      other.line == line;

  @override
  int get hashCode => Object.hash(isMoreDmg, isElementDamage, line);
}

/// 装备词条下拉选项：DPS 相关白词条 + 特殊词条
final List<_LineOption> _lineOptions = [
  _LineOption.item(ItemLine.damageInt),
  _LineOption.item(ItemLine.damagePercent),
  const _LineOption.elementDamage(),
  _LineOption.item(ItemLine.criticalChance),
  _LineOption.item(ItemLine.criticalDamage),
  _LineOption.item(ItemLine.attackSpeed),
  const _LineOption.moreDmg(),
];

/// 一条装备词条输入（词条选项 + 数值输入框）
class _LineInput {
  _LineInput(this._onChanged) {
    valueCtrl.addListener(_onChanged);
  }

  final VoidCallback _onChanged;
  final valueCtrl = TextEditingController();

  /// 已选择的词条选项；null 表示尚未选择
  _LineOption? line;

  void dispose() {
    valueCtrl.removeListener(_onChanged);
    valueCtrl.dispose();
  }
}

class _ItemComparerPageState extends State<ItemComparerPage> {
  // ── 无装备面板 ──
  final _baseAttackCtrl = TextEditingController();
  final _increasedDmgCtrl = TextEditingController();
  final _moreDmgCtrl = TextEditingController();
  final _critChanceCtrl = TextEditingController();
  final _critDmgCtrl = TextEditingController();

  /// 基础每秒攻击次数（与 [_speedCtrl] 都填写后，DPS 才按攻击次数计算）
  final _baseApsCtrl = TextEditingController();

  /// 面板 Increased Speed：与 [_baseApsCtrl] 一起参与攻击次数计算
  final _speedCtrl = TextEditingController();

  // ── 两件装备的词条行 ──
  final _item1Lines = <_LineInput>[];
  final _item2Lines = <_LineInput>[];

  /// 从内存恢复输入期间为 true，跳过保存与重建（恢复时监听器尚未就绪）
  bool _restoring = false;

  List<TextEditingController> get _panelCtrls => [
        _baseAttackCtrl,
        _increasedDmgCtrl,
        _moreDmgCtrl,
        _critChanceCtrl,
        _critDmgCtrl,
        _baseApsCtrl,
        _speedCtrl,
      ];

  @override
  void initState() {
    super.initState();
    // 先恢复上次输入，再挂监听（避免恢复过程触发重建）
    _restoring = true;
    _restoreFromStore();
    _restoring = false;
    for (final ctrl in _panelCtrls) {
      ctrl.addListener(_onInputChanged);
    }
    // 恢复后仍为空时补一条空词条行
    if (_item1Lines.isEmpty) _item1Lines.add(_createLineInput());
    if (_item2Lines.isEmpty) _item2Lines.add(_createLineInput());
  }

  @override
  void dispose() {
    for (final ctrl in _panelCtrls) {
      ctrl.dispose();
    }
    for (final input in [..._item1Lines, ..._item2Lines]) {
      input.dispose();
    }
    super.dispose();
  }

  /// 输入变化：持久化并重算结果区
  void _onInputChanged() {
    if (_restoring) return;
    _saveToStore();
    setState(() {});
  }

  _LineInput _createLineInput() => _LineInput(_onInputChanged);

  void _addLine(List<_LineInput> lines) {
    if (lines.length >= kMaxLinesPerItem) return;
    setState(() => lines.add(_createLineInput()));
    _saveToStore();
  }

  void _removeLine(List<_LineInput> lines, _LineInput input) {
    setState(() => lines.remove(input));
    _saveToStore();
    // 输入框本帧卸载后才释放控制器，避免 dispose 时序问题
    WidgetsBinding.instance.addPostFrameCallback((_) => input.dispose());
  }

  /// 重置所有输入：清空面板，两件装备各恢复为一条空词条行
  void _reset() {
    for (final ctrl in _panelCtrls) {
      ctrl.clear(); // 触发 _onInputChanged 保存（此时词条行尚未重置）
    }
    // 被移除行的控制器随页面销毁统一释放（本帧卸载输入框时仍在使用）
    setState(() {
      _item1Lines
        ..clear()
        ..add(_createLineInput());
      _item2Lines
        ..clear()
        ..add(_createLineInput());
    });
    _saveToStore();
  }

  // ── 持久化（Hive，app_meta box）───────────────────────

  void _restoreFromStore() {
    final store = Stores.itemComparerStore;
    _baseAttackCtrl.text = store.baseAttack;
    _increasedDmgCtrl.text = store.increasedDmg;
    _moreDmgCtrl.text = store.moreDmg;
    _critChanceCtrl.text = store.critChance;
    _critDmgCtrl.text = store.critDmg;
    _baseApsCtrl.text = store.baseAps;
    _speedCtrl.text = store.speed;
    _restoreLines(_item1Lines, store.item1);
    _restoreLines(_item2Lines, store.item2);
  }

  void _restoreLines(
    List<_LineInput> target,
    List<ItemComparerLineInput> saved,
  ) {
    for (final input in saved) {
      final row = _createLineInput();
      if (input.isMoreDmg) {
        row.line = const _LineOption.moreDmg();
      } else if (input.isElementDamage) {
        row.line = const _LineOption.elementDamage();
      } else if (input.line != null) {
        row.line = _LineOption.item(input.line!);
      }
      row.valueCtrl.text = input.value;
      target.add(row);
    }
  }

  void _saveToStore() {
    final store = Stores.itemComparerStore;
    store.baseAttack = _baseAttackCtrl.text;
    store.increasedDmg = _increasedDmgCtrl.text;
    store.moreDmg = _moreDmgCtrl.text;
    store.critChance = _critChanceCtrl.text;
    store.critDmg = _critDmgCtrl.text;
    store.baseAps = _baseApsCtrl.text;
    store.speed = _speedCtrl.text;
    _saveLines(_item1Lines, store.item1);
    _saveLines(_item2Lines, store.item2);
    store.save();
  }

  void _saveLines(
    List<_LineInput> source,
    List<ItemComparerLineInput> target,
  ) {
    target
      ..clear()
      ..addAll([
        for (final input in source)
          ItemComparerLineInput(
            line: input.line?.line,
            isMoreDmg: input.line?.isMoreDmg ?? false,
            isElementDamage: input.line?.isElementDamage ?? false,
            value: input.valueCtrl.text,
          ),
      ]);
  }

  double _valueOf(TextEditingController ctrl) =>
      double.tryParse(ctrl.text.trim()) ?? 0;

  /// 文本为空返回 null（表示未填写，用于攻击速度的两项开关），否则解析数值
  double? _optionalValue(TextEditingController ctrl) =>
      ctrl.text.trim().isEmpty ? null : double.tryParse(ctrl.text.trim()) ?? 0;

  ItemDpsResult _computeItemResult(List<_LineInput> lines) {
    return computeItemDps(
      baseAttack: _valueOf(_baseAttackCtrl),
      increasedDmg: _valueOf(_increasedDmgCtrl),
      moreDmg: _valueOf(_moreDmgCtrl),
      critChance: _valueOf(_critChanceCtrl),
      critDmg: _valueOf(_critDmgCtrl),
      baseAps: _optionalValue(_baseApsCtrl),
      increasedSpeed: _optionalValue(_speedCtrl),
      lines: [
        for (final input in lines)
          if (input.line != null &&
              !input.line!.isMoreDmg &&
              !input.line!.isElementDamage &&
              input.valueCtrl.text.trim().isNotEmpty)
            (line: input.line!.line!, value: _valueOf(input.valueCtrl)),
      ],
      moreDmgLines: [
        for (final input in lines)
          if (input.line?.isMoreDmg == true &&
              input.valueCtrl.text.trim().isNotEmpty)
            _valueOf(input.valueCtrl),
      ],
      elementDmgLines: [
        for (final input in lines)
          if (input.line?.isElementDamage == true &&
              input.valueCtrl.text.trim().isNotEmpty)
            _valueOf(input.valueCtrl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 三组结果随输入实时重算：无装备基准 / 装备 1 / 装备 2
    final baseResult = computeItemDps(
      baseAttack: _valueOf(_baseAttackCtrl),
      increasedDmg: _valueOf(_increasedDmgCtrl),
      moreDmg: _valueOf(_moreDmgCtrl),
      critChance: _valueOf(_critChanceCtrl),
      critDmg: _valueOf(_critDmgCtrl),
      baseAps: _optionalValue(_baseApsCtrl),
      increasedSpeed: _optionalValue(_speedCtrl),
    );
    final item1Result = _computeItemResult(_item1Lines);
    final item2Result = _computeItemResult(_item2Lines);

    return Scaffold(
      appBar: AppBar(
        title: const Text('装备对比'),
        actions: [
          IconButton(
            tooltip: '重置',
            icon: const Icon(Icons.restore_page),
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionHeader('无装备面板'),
          Card(margin: EdgeInsets.zero, child: _buildPanelCard()),
          const SectionHeader('装备 1'),
          Card(margin: EdgeInsets.zero, child: _buildItemCard(_item1Lines)),
          const SectionHeader('装备 2'),
          Card(margin: EdgeInsets.zero, child: _buildItemCard(_item2Lines)),
          const SectionHeader('对比结果'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ResultView(
                baseResult: baseResult,
                item1Result: item1Result,
                item2Result: item2Result,
                ready: _valueOf(_baseAttackCtrl) > 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 无装备面板 ──────────────────────────────────────

  Widget _buildPanelCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          _panelField('Base Attack', _baseAttackCtrl, isPercent: false),
          _panelField('Increased Dmg', _increasedDmgCtrl),
          _panelField('More Dmg', _moreDmgCtrl),
          _panelField('Critical Chance', _critChanceCtrl),
          _panelField('Critical Dmg', _critDmgCtrl),
          _panelField('Attacks Per Second', _baseApsCtrl, isPercent: false),
          _panelField('Increased Speed', _speedCtrl),
          const SizedBox(height: 8),
          Text.rich(
            const TextSpan(
              style: TextStyle(fontSize: 12),
              children: [
                TextSpan(
                  text: '普攻型单位：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '需要填写 Attacks Per Second 和 Increased Speed，Attack Speed % 词条参与计算。\n',
                ),
                TextSpan(
                  text: '技能型单位：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '不填写上述两项，Attack Speed % 词条不参与计算。',
                ),
                TextSpan(
                  text: '\n\n注：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '宝珠、宝物等词条也可用于计算，但需要注意词条类型。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelField(
    String label,
    TextEditingController ctrl, {
    bool isPercent = true,
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
          Expanded(
            child: SelectAllTextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                isDense: true,
                suffixText: isPercent ? '%' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 装备卡片 ────────────────────────────────────────

  Widget _buildItemCard(List<_LineInput> lines) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final input in lines)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _ItemLineRow(
                key: ObjectKey(input),
                input: input,
                onChanged: _onInputChanged,
                onRemove: () => _removeLine(lines, input),
              ),
            ),
          if (lines.length < kMaxLinesPerItem)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => _addLine(lines),
                icon: const Icon(Icons.add),
                label: const Text('添加词条'),
              ),
            ),
        ],
      ),
    );
  }
}

/// 一条装备词条输入行：词条类型下拉框 + 数值输入框 + 删除
class _ItemLineRow extends StatelessWidget {
  const _ItemLineRow({
    super.key,
    required this.input,
    required this.onChanged,
    required this.onRemove,
  });

  final _LineInput input;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final line = input.line;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<_LineOption>(
            initialValue: line,
            hint: const Text('选择词条类型'),
            // isDense: true,
            items: [
              for (final option in _lineOptions)
                DropdownMenuItem(value: option, child: Text(option.label)),
            ],
            onChanged: (value) {
              input.line = value;
              onChanged();
            },
            decoration: const InputDecoration(
              isDense: true,
              // border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: SelectAllTextField(
            controller: input.valueCtrl,
            enabled: line != null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              // isDense: true,
              // border: const OutlineInputBorder(),
              hintText: '数值',
              suffixText: line?.isPercent == true ? '%' : null,
            ),
          ),
        ),
        IconButton(
          tooltip: '删除词条',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

/// 对比结果：结论横幅 + 无装备/装备 1/装备 2 的伤害明细表
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.baseResult,
    required this.item1Result,
    required this.item2Result,
    required this.ready,
  });

  final ItemDpsResult baseResult;
  final ItemDpsResult item1Result;
  final ItemDpsResult item2Result;

  /// 已填写基础攻击（Base Attack > 0）时才开始对比
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseDps = baseResult.dps;
    final item1Dps = item1Result.dps;
    final item2Dps = item2Result.dps;

    // 结论：0 = 装备 1 更优，1 = 装备 2 更优，-1 = 相同/未就绪
    final (String text, int winner) = _verdict(item1Dps, item2Dps);
    final gain1 = baseDps > 0 ? _pct(item1Dps / baseDps - 1) : null;
    final gain2 = baseDps > 0 ? _pct(item2Dps / baseDps - 1) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 结论横幅
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ready ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: ready ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 表头
        Row(
          children: [
            const SizedBox(width: 68),
            for (final title in const ['无暴击', '有暴击', 'APS', 'DPS'])
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        _tableRow(context, '无装备', baseResult),
        _tableRow(context, '装备 1', item1Result, highlight: winner == 0),
        _tableRow(context, '装备 2', item2Result, highlight: winner == 1),
        const SizedBox(height: 12),
        Text(
          '装备 1 较无装备 ${gain1 ?? '—'} · 装备 2 较无装备 ${gain2 ?? '—'}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  (String, int) _verdict(double item1Dps, double item2Dps) {
    if (!ready) return ('填写上方数据后自动对比', -1);
    if (item1Dps > item2Dps) {
      final gap = item2Dps > 0 ? '，DPS 比装备 2 高 ${_pct(item1Dps / item2Dps - 1)}' : '';
      return ('装备 1 更优$gap', 0);
    }
    if (item2Dps > item1Dps) {
      final gap = item1Dps > 0 ? '，DPS 比装备 1 高 ${_pct(item2Dps / item1Dps - 1)}' : '';
      return ('装备 2 更优$gap', 1);
    }
    return ('两件装备 DPS 相同', -1);
  }

  Widget _tableRow(
    BuildContext context,
    String label,
    ItemDpsResult result, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: highlight ? theme.colorScheme.primary : null,
      fontWeight: highlight ? FontWeight.w700 : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 68, child: Text(label, style: style)),
          Expanded(
            child: Text(
              result.normalHit.formatCompact(),
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              result.critHit.formatCompact(),
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              // 面板攻速两项未填齐时为 null，显示 —（攻速未参与计算）
              result.aps?.format() ?? '—',
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              result.dps.formatCompact(),
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// 比率转百分比文本（1 位小数，整数不带小数）
String _pct(double ratio) {
  final value = ratio * 100;
  return value == value.roundToDouble()
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(1)}%';
}
