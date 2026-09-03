import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:measure_size/measure_size.dart';

import 'package:grow_castle_calculator_next/core/calc/item_dps.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/item_comparer_store.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';

/// 装备对比
class ItemComparerPage extends StatefulWidget {
  const ItemComparerPage({super.key});

  @override
  State<ItemComparerPage> createState() => _ItemComparerPageState();
}

const int kMaxLinesPerItem = 3;

class _LineOption {
  const _LineOption._({
    this.line,
    this.isMoreDmg = false,
    this.isElementDamage = false,
  });

  /// 普通白词条
  const _LineOption.item(ItemLine line) : this._(line: line);

  /// Element Damage 词条
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

  @override
  bool operator ==(Object other) =>
      other is _LineOption &&
      other.isMoreDmg == isMoreDmg &&
      other.isElementDamage == isElementDamage &&
      other.line == line;

  @override
  int get hashCode => Object.hash(isMoreDmg, isElementDamage, line);
}

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

  _LineOption? line;

  bool _disposed = false;

  /// 幂等：处于退场动画中的行可能经由页面 dispose / 重置路径被二次释放
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    valueCtrl.removeListener(_onChanged);
    valueCtrl.dispose();
  }
}

class _ItemComparerPageState extends State<ItemComparerPage> {
  final _baseAttackCtrl = TextEditingController();
  final _increasedDmgCtrl = TextEditingController();
  final _moreDmgCtrl = TextEditingController();
  final _critChanceCtrl = TextEditingController();
  final _critDmgCtrl = TextEditingController();

  /// 基础每秒攻击次数（与 [_speedCtrl] 都填写后，DPS 才按攻击次数计算）
  final _baseApsCtrl = TextEditingController();

  /// 面板 Increased Speed：与 [_baseApsCtrl] 一起参与攻击次数计算
  final _speedCtrl = TextEditingController();

  final _item1Lines = <_LineInput>[];
  final _item2Lines = <_LineInput>[];
  int _lineListGeneration = 0;

  final ValueNotifier<double> _summaryBarHeightNotifier = ValueNotifier(0.0);

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
    _restoring = true;
    _restoreFromStore();
    _restoring = false;
    for (final ctrl in _panelCtrls) {
      ctrl.addListener(_onInputChanged);
    }
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
    _summaryBarHeightNotifier.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (_restoring) return;
    _saveToStore();
    setState(() {});
  }

  _LineInput _createLineInput() => _LineInput(_onInputChanged);

  void _reset() {
    for (final input in [..._item1Lines, ..._item2Lines]) {
      input.dispose();
    }
    for (final ctrl in _panelCtrls) {
      ctrl.clear();
    }
    setState(() {
      _item1Lines
        ..clear()
        ..add(_createLineInput());
      _item2Lines
        ..clear()
        ..add(_createLineInput());
      _lineListGeneration++;
    });
    _saveToStore();
  }

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

  void _saveLines(List<_LineInput> source, List<ItemComparerLineInput> target) {
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
        title: Row(children: [const Text('装备对比')]),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使用说明',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('使用说明'),
                content: const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 14),
                    children: [
                      TextSpan(text: '该工具用于对比两件装备的期望。\n\n'),
                      TextSpan(
                        text: '使用步骤：\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '1. 确认需要对比的装备 / 宝珠 / 宝物槽位，然后将对应的物品卸下，根据此时的面板填写“无装备面板”数据；\n',
                      ),
                      TextSpan(text: '2. 将两件装备的白词条填写到“装备 1 / 装备 2”中，'),
                      TextSpan(
                        text: '请注意词条类型，元素伤害统一并入 "Element Damage"，请自行根据单位属性填入对应元素伤害词条；\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '3. 对比结果：实时显示三组 DPS 结果，并给出结论。\n\n\n'),
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
                      TextSpan(text: '不填写上述两项，Attack Speed % 词条不参与计算。'),
                      TextSpan(
                        text: '\n\n注：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '宝珠、宝物等词条也可用于计算，但需要注意词条类型。'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: '重置',
            icon: const Icon(Icons.restore_page),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('重置'),
                content: const Text('是否清空所有输入？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _reset();
                    },
                    child: const Text('确认'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder(
              valueListenable: _summaryBarHeightNotifier,
              builder: (context, height, child) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, height),
                  children: [
                    Card(margin: EdgeInsets.zero, child: _buildPanelCard()),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: _buildItemCard(
                        _item1Lines,
                        '装备 1 词条',
                        'item1',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: _buildItemCard(
                        _item2Lines,
                        '装备 2 词条',
                        'item2',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MeasureSize(
              onChange: (size) {
                final next = size.height;
                final current = _summaryBarHeightNotifier.value;
                if ((current - next).abs() > 0.5) {
                  _summaryBarHeightNotifier.value = next;
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 3.0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _ResultView(
                      baseResult: baseResult,
                      item1Result: item1Result,
                      item2Result: item2Result,
                      ready: _valueOf(_baseAttackCtrl) > 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '无装备面板',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _panelField('Base Attack', _baseAttackCtrl, isPercent: false),
          _panelField('Increased Dmg', _increasedDmgCtrl),
          _panelField('More Dmg', _moreDmgCtrl),
          _panelField('Critical Chance', _critChanceCtrl),
          _panelField('Critical Dmg', _critDmgCtrl),
          _panelField('Attacks Per Second', _baseApsCtrl, isPercent: false),
          _panelField('Increased Speed', _speedCtrl),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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

  Widget _buildItemCard(
    List<_LineInput> lines,
    String title,
    String listId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          _AnimatedItemLineList(
            key: ValueKey('$listId-$_lineListGeneration'),
            lines: lines,
            onChanged: _onInputChanged,
            createLine: _createLineInput,
            ),
        ],
      ),
    );
  }
}

class _AnimatedItemLineList extends StatefulWidget {
  const _AnimatedItemLineList({
    super.key,
    required this.lines,
    required this.onChanged,
    required this.createLine,
  });

  final List<_LineInput> lines;
  final VoidCallback onChanged;
  final _LineInput Function() createLine;

  @override
  State<_AnimatedItemLineList> createState() => _AnimatedItemLineListState();
}

class _AnimatedItemLineListState extends State<_AnimatedItemLineList> {
  static const _animationDuration = Duration(milliseconds: 280);

  final _listKey = GlobalKey<AnimatedListState>();
  final _removingInputs = <_LineInput>{};

  @override
  void dispose() {
    // 页面或列表被重建时，退场动画可能还没走完；此时统一兜底释放。
    for (final input in _removingInputs) {
      input.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    if (widget.lines.length >= kMaxLinesPerItem) return;
    final index = widget.lines.length;
    widget.lines.add(widget.createLine());
    _listKey.currentState?.insertItem(
      index,
      duration: _animationDuration,
    );
    widget.onChanged();
  }

  void _removeLine(_LineInput input) {
    final index = widget.lines.indexOf(input);
    if (index < 0 || !_removingInputs.add(input)) return;

    widget.lines.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _RemovedLineItem(
        key: ObjectKey(input),
        input: input,
        animation: animation,
        onRemoved: _finishRemove,
      ),
      duration: _animationDuration,
    );
    widget.onChanged();
  }

  void _finishRemove(_LineInput input) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removingInputs.remove(input);
      input.dispose();
    });
  }

  /// 构建带入场动画的词条行（itemBuilder 使用）
  Widget _buildAnimatedRow(
    _LineInput input,
    Animation<double> animation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final offset = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizeTransition(
        sizeFactor: curvedAnimation,
        alignment: const Alignment(-1.0, -1.0),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: offset,
            child: _ItemLineRow(
              key: ObjectKey(input),
              input: input,
              onChanged: widget.onChanged,
              onRemove: () => _removeLine(input),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedList(
          key: _listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: widget.lines.length,
          itemBuilder: (context, index, animation) => _buildAnimatedRow(
            widget.lines[index],
            animation,
          ),
        ),
        if (widget.lines.length < kMaxLinesPerItem)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _addLine,
              icon: const Icon(Icons.add),
              label: const Text('添加词条'),
            ),
          ),
      ],
    );
  }
}

/// 删除退场动画期间挂在树上的占位行。
///
/// AnimatedList 的 removeItem builder 产物会一直留在树上直到退场动画结束，
/// 因此不能在动画结束（dismissed）回调里直接释放 controller —— 此刻该行
/// 组件尚未卸载，若期间发生重建或输入法事件访问到已销毁的 controller，
/// 会抛出 "A TextEditingController was used after being disposed"。
/// 这里把释放推迟到本组件真正被卸载时（State.dispose），保证行已离开树。
class _RemovedLineItem extends StatefulWidget {
  const _RemovedLineItem({
    super.key,
    required this.input,
    required this.animation,
    required this.onRemoved,
  });

  final _LineInput input;

  /// 退场动画（AnimatedList 传入，播放方向为 1 -> 0）
  final Animation<double> animation;
  final ValueChanged<_LineInput> onRemoved;

  @override
  State<_RemovedLineItem> createState() => _RemovedLineItemState();
}

class _RemovedLineItemState extends State<_RemovedLineItem> {
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: widget.animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.12, 0),
  ).animate(_curved);

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      widget.onRemoved(widget.input);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 退场期间禁止交互，避免焦点/输入法在释放边界上访问行内容
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizeTransition(
          sizeFactor: _curved,
          alignment: const Alignment(-1.0, -1.0),
          child: FadeTransition(
            opacity: _curved,
            child: SlideTransition(
              position: _offset,
              child: _ItemLineRow(
                key: ObjectKey(widget.input),
                input: widget.input,
                onChanged: () {},
                onRemove: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ready
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: ready
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
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
    if (!ready) return ('填写数据后自动对比', -1);
    if (item1Dps > item2Dps) {
      final gap = item2Dps > 0
          ? '，DPS 比装备 2 高 ${_pct(item1Dps / item2Dps - 1)}'
          : '';
      return ('装备 1 更优$gap', 0);
    }
    if (item2Dps > item1Dps) {
      final gap = item1Dps > 0
          ? '，DPS 比装备 1 高 ${_pct(item2Dps / item1Dps - 1)}'
          : '';
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

/// 比率转百分比文本
String _pct(double ratio) {
  final value = ratio * 100;
  return value == value.roundToDouble()
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(1)}%';
}
