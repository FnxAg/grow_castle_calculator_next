import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/calc/item_dps.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/src/item/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/item_comparer_store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/utils/divider.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/responsive/short_window_fallback.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// 装备对比
class ItemComparerPage extends StatefulWidget {
  const ItemComparerPage({super.key});

  @override
  State<ItemComparerPage> createState() => _ItemComparerPageState();
}

const int kMaxLinesPerItem = 3;
const int kMaxEquipsPerSide = 3;

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
      ? 'More Damage %'
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

/// 一侧对比中的一件装备（最多 [kMaxLinesPerItem] 条词条）
class _EquipInput {
  _EquipInput(this.id);

  /// 稳定标识：作为行列表的 key，增删装备后不会串用其他装备的动画状态
  final int id;
  final List<_LineInput> lines = [];

  void dispose() {
    for (final line in lines) {
      line.dispose();
    }
  }
}

class _ItemComparerPageState extends State<ItemComparerPage>
    with SingleTickerProviderStateMixin {
  final _baseAttackCtrl = TextEditingController();
  final _increasedDmgCtrl = TextEditingController();
  final _moreDmgCtrl = TextEditingController();
  final _critChanceCtrl = TextEditingController();
  final _critDmgCtrl = TextEditingController();

  /// 基础每秒攻击次数（与 [_speedCtrl] 都填写后，DPS 才按攻击次数计算）
  final _baseApsCtrl = TextEditingController();

  /// 面板 Increased Speed：与 [_baseApsCtrl] 一起参与攻击次数计算
  final _speedCtrl = TextEditingController();

  /// 两侧对比的装备
  final _equip1 = <_EquipInput>[];
  final _equip2 = <_EquipInput>[];
  int _nextEquipId = 0;

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
    // 数据恢复/导入后从 store 重新回填输入（结构可能与旧输入不一致）
    BackupService.instance.dataRestoredNotifier.addListener(_onDataRestored);
    _restoring = true;
    _restoreFromStore();
    _restoring = false;
    for (final ctrl in _panelCtrls) {
      ctrl.addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    BackupService.instance.dataRestoredNotifier.removeListener(_onDataRestored);
    for (final ctrl in _panelCtrls) {
      ctrl.dispose();
    }
    for (final equip in [..._equip1, ..._equip2]) {
      equip.dispose();
    }
    super.dispose();
  }

  /// 数据恢复/导入完成：整页输入按新 store 数据重建
  void _onDataRestored() {
    if (!mounted) return;
    _restoring = true;
    for (final equip in [..._equip1, ..._equip2]) {
      equip.dispose();
    }
    _equip1.clear();
    _equip2.clear();
    _restoreFromStore();
    _restoring = false;
    setState(() {});
  }

  void _onInputChanged() {
    if (_restoring) return;
    _saveToStore();
    setState(() {});
  }

  _LineInput _createLineInput() => _LineInput(_onInputChanged);

  _EquipInput _createEquip() =>
      _EquipInput(_nextEquipId++)..lines.add(_createLineInput());

  void _addEquip(List<_EquipInput> equips) {
    if (equips.length >= kMaxEquipsPerSide) return;
    setState(() => equips.add(_createEquip()));
    _saveToStore();
  }

  void _removeEquip(List<_EquipInput> equips, _EquipInput equip) {
    if (equips.length <= 1) return;
    setState(() {
      equips.remove(equip);
      equip.dispose();
    });
    _saveToStore();
  }

  /// 两件装备互换位置（各自的行输入随对象一起移动）
  void _swapEquips(
    List<_EquipInput> from,
    _EquipInput fromEquip,
    List<_EquipInput> to,
    _EquipInput toEquip,
  ) {
    final fromIndex = from.indexOf(fromEquip);
    final toIndex = to.indexOf(toEquip);
    if (fromIndex < 0 || toIndex < 0) return;
    setState(() {
      from[fromIndex] = toEquip;
      to[toIndex] = fromEquip;
    });
    _saveToStore();
  }

  void _reset() {
    for (final equip in [..._equip1, ..._equip2]) {
      equip.dispose();
    }
    for (final ctrl in _panelCtrls) {
      ctrl.clear();
    }
    setState(() {
      _equip1
        ..clear()
        ..add(_createEquip());
      _equip2
        ..clear()
        ..add(_createEquip());
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
    _restoreEquips(_equip1, store.item1);
    _restoreEquips(_equip2, store.item2);
    if (_equip1.isEmpty) _equip1.add(_createEquip());
    if (_equip2.isEmpty) _equip2.add(_createEquip());
  }

  void _restoreEquips(
    List<_EquipInput> target,
    List<List<ItemComparerLineInput>> saved,
  ) {
    for (final savedLines in saved) {
      final equip = _EquipInput(_nextEquipId++);
      for (final input in savedLines) {
        final row = _createLineInput();
        if (input.isMoreDmg) {
          row.line = const _LineOption.moreDmg();
        } else if (input.isElementDamage) {
          row.line = const _LineOption.elementDamage();
        } else if (input.line != null) {
          row.line = _LineOption.item(input.line!);
        }
        row.valueCtrl.text = input.value;
        equip.lines.add(row);
      }
      if (equip.lines.isEmpty) equip.lines.add(_createLineInput());
      target.add(equip);
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
    _saveEquips(_equip1, store.item1);
    _saveEquips(_equip2, store.item2);
    store.save();
  }

  void _saveEquips(
    List<_EquipInput> source,
    List<List<ItemComparerLineInput>> target,
  ) {
    target
      ..clear()
      ..addAll([
        for (final equip in source)
          [
            for (final input in equip.lines)
              ItemComparerLineInput(
                line: input.line?.line,
                isMoreDmg: input.line?.isMoreDmg ?? false,
                isElementDamage: input.line?.isElementDamage ?? false,
                value: input.valueCtrl.text,
              ),
          ],
      ]);
  }

  double _valueOf(TextEditingController ctrl) =>
      double.tryParse(ctrl.text.trim()) ?? 0;

  double? _optionalValue(TextEditingController ctrl) =>
      ctrl.text.trim().isEmpty ? null : double.tryParse(ctrl.text.trim()) ?? 0;

  ItemDpsResult _computeItemResult(List<_EquipInput> equips) {
    // 同一侧多件装备的词条叠加计算
    final lines = [for (final equip in equips) ...equip.lines];
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
    final l10n = AppLocalizations.of(context);
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    final baseResult = computeItemDps(
      baseAttack: _valueOf(_baseAttackCtrl),
      increasedDmg: _valueOf(_increasedDmgCtrl),
      moreDmg: _valueOf(_moreDmgCtrl),
      critChance: _valueOf(_critChanceCtrl),
      critDmg: _valueOf(_critDmgCtrl),
      baseAps: _optionalValue(_baseApsCtrl),
      increasedSpeed: _optionalValue(_speedCtrl),
    );
    final item1Result = _computeItemResult(_equip1);
    final item2Result = _computeItemResult(_equip2);
    final baseDps = baseResult.dps;
    final item1Dps = item1Result.dps;
    final item2Dps = item2Result.dps;
    final item1Inc = item1Dps / baseDps;
    final item2Inc = item2Dps / baseDps;
    final bool isWide = context.isWideContent;

    final Widget list = ListView(
      key: const PageStorageKey('item_comparer_list'),
      padding: EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      children: [
        SectionHeader(
          l10n.labelNoItemPanel,
          trailing: PillChip(
            text: baseResult.dps.formatCompact(
              english: english,
              traditional: traditional,
            ),
          ),
        ),
        SummaryCard(children: _buildPanelCard()),
        SectionHeader(
          l10n.labelItemLines(1),
          trailing: PillChip(
            leading: item1Inc > item2Inc
                ? const Icon(Icons.arrow_drop_up)
                : item1Inc < item2Inc
                ? const Icon(Icons.arrow_drop_down)
                : null,
            backgroundColor: item1Inc > item2Inc ? Colors.green : null,
            text: '${((item1Inc - 1) * 100).toStringAsFixed(2)}%',
          ),
        ),
        SummaryCard(
          children: <Widget>[_buildItemCard(_equip1, _equip2, 1, 'item1')],
        ),
        SectionHeader(
          l10n.labelItemLines(2),
          trailing: PillChip(
            leading: item1Inc < item2Inc
                ? const Icon(Icons.arrow_drop_up)
                : item1Inc > item2Inc
                ? const Icon(Icons.arrow_drop_down)
                : null,
            backgroundColor: item1Inc < item2Inc ? Colors.green : null,
            text: '${((item2Inc - 1) * 100).toStringAsFixed(2)}%',
          ),
        ),
        SummaryCard(
          children: <Widget>[_buildItemCard(_equip2, _equip1, 2, 'item2')],
        ),
      ],
    );
    final Widget summaryView = Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: SummaryCard(
        children: <Widget>[
          _ResultView(
            baseResult: baseResult,
            item1Result: item1Result,
            item2Result: item2Result,
            ready: _valueOf(_baseAttackCtrl) > 0,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Text(l10n.toolItemComparer)]),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.aboutGuide,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.aboutGuide),
                content: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      TextSpan(text: l10n.dialogItemCompareHelpIntro),
                      TextSpan(
                        text: l10n.dialogItemCompareHelpStepsTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: l10n.dialogItemCompareHelpStep1),
                      TextSpan(text: l10n.dialogItemCompareHelpStep2),
                      TextSpan(
                        text: l10n.dialogItemCompareHelpStep2Note,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: l10n.dialogItemCompareHelpStep3),
                      TextSpan(
                        text: l10n.dialogItemCompareHelpNormalUnit,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: l10n.dialogItemCompareHelpNormalUnitDesc),
                      TextSpan(
                        text: l10n.dialogItemCompareHelpSkillUnit,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: l10n.dialogItemCompareHelpSkillUnitDesc),
                      TextSpan(
                        text: l10n.dialogItemCompareHelpNoteLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: l10n.dialogItemCompareHelpNoteDesc),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.actionClose),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.actionReset,
            icon: const Icon(Icons.refresh),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.actionReset),
                content: Text(l10n.dialogResetConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.actionCancel),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _reset();
                    },
                    child: Text(l10n.actionConfirm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ShortWindowFallback(
          minHeight: 340,
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 6, child: list),
                    Expanded(flex: 4, child: summaryView),
                  ],
                )
              : list,
        ),
      ),
    );
  }

  List<Widget> _buildPanelCard() {
    return [
      _panelField('Base Attack', _baseAttackCtrl, isPercent: false),
      _panelField('Increased Damage', _increasedDmgCtrl),
      _panelField('More Damage', _moreDmgCtrl),
      _panelField('Critical Chance', _critChanceCtrl),
      _panelField('Critical Damage', _critDmgCtrl),
      _panelField('Attacks Per Second', _baseApsCtrl, isPercent: false),
      _panelField('Increased Speed', _speedCtrl),
    ];
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
            width: 140.0,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 88.0,
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
    List<_EquipInput> equips,
    List<_EquipInput> otherEquips,
    int side,
    String listId,
  ) {
    final l10n = AppLocalizations.of(context);
    final showHeader = equips.length > 1 || otherEquips.length > 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < equips.length; i++) ...[
          if (i > 0) const Divider(height: 16),
          if (showHeader) _buildEquipHeader(equips, otherEquips, side, i),
          _AnimatedItemLineList(
            key: ValueKey('$listId-${equips[i].id}'),
            lines: equips[i].lines,
            onChanged: _onInputChanged,
            createLine: _createLineInput,
          ),
        ],
        if (equips.length < kMaxEquipsPerSide)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => _addEquip(equips),
              icon: const Icon(Icons.add),
              label: Text(l10n.actionAddEquip),
            ),
          ),
      ],
    );
  }

  /// 分件标题：对调菜单与删除按钮
  Widget _buildEquipHeader(
    List<_EquipInput> equips,
    List<_EquipInput> otherEquips,
    int side,
    int index,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final equip = equips[index];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            l10n.labelEquipPiece(index + 1),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          PopupMenuButton<int>(
            tooltip: l10n.tooltipSwapEquip,
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: const Icon(Icons.swap_horiz),
            itemBuilder: (context) => [
              for (var i = 0; i < otherEquips.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Text(
                    dividerText([
                      (l10n.labelItemNumber(side == 1 ? 2 : 1)),
                      (l10n.labelEquipPiece(i + 1)),
                    ]),
                  ),
                ),
            ],
            onSelected: (otherIndex) => _swapEquips(
              equips,
              equip,
              otherEquips,
              otherEquips[otherIndex],
            ),
          ),
          if (equips.length > 1)
            IconButton(
              tooltip: l10n.tooltipDeleteEquip,
              icon: const Icon(Icons.delete_outline, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: () => _removeEquip(equips, equip),
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
    for (final input in _removingInputs) {
      input.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    if (widget.lines.length >= kMaxLinesPerItem) return;
    final index = widget.lines.length;
    widget.lines.add(widget.createLine());
    _listKey.currentState?.insertItem(index, duration: _animationDuration);
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

  Widget _buildAnimatedRow(_LineInput input, Animation<double> animation) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(curvedAnimation);

    return SizeTransition(
      sizeFactor: curvedAnimation,
      alignment: const Alignment(-1.0, -1.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
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
          itemBuilder: (context, index, animation) =>
              _buildAnimatedRow(widget.lines[index], animation),
        ),
        if (widget.lines.length < kMaxLinesPerItem)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _addLine,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).actionAddLine),
            ),
          ),
      ],
    );
  }
}

class _RemovedLineItem extends StatefulWidget {
  const _RemovedLineItem({
    super.key,
    required this.input,
    required this.animation,
    required this.onRemoved,
  });

  final _LineInput input;

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
    end: const Offset(0, -0.12),
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
    return IgnorePointer(
      child: SizeTransition(
        sizeFactor: _curved,
        alignment: const Alignment(-1.0, -1.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
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
    final l10n = AppLocalizations.of(context);
    final line = input.line;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<_LineOption>(
            initialValue: line,
            hint: Text(l10n.hintSelectLineType),
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
              hintText: l10n.hintValue,
              suffixText: line?.isPercent == true ? '%' : null,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.tooltipDeleteLine,
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
    final l10n = AppLocalizations.of(context);
    final baseDps = baseResult.dps;
    final item1Dps = item1Result.dps;
    final item2Dps = item2Result.dps;

    // 结论：0 = 装备 1 更优，1 = 装备 2 更优，-1 = 相同/未就绪
    final (String text, int winner) = _verdict(l10n, item1Dps, item2Dps);
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
            for (final title in [
              l10n.labelNoCrit,
              l10n.labelWithCrit,
              'APS',
              'DPS',
            ])
              Expanded(
                child: Text(
                  title,
                  textAlign: .right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        _tableRow(context, l10n.labelNoItem, baseResult),
        _tableRow(
          context,
          l10n.labelItemNumber(1),
          item1Result,
          highlight: winner == 0,
        ),
        _tableRow(
          context,
          l10n.labelItemNumber(2),
          item2Result,
          highlight: winner == 1,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.labelCompareGainSummary(gain1 ?? '—', gain2 ?? '—'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  (String, int) _verdict(
    AppLocalizations l10n,
    double item1Dps,
    double item2Dps,
  ) {
    if (!ready) return (l10n.compareVerdictPending, -1);
    if (item1Dps > item2Dps) {
      final gap = item2Dps > 0
          ? l10n.compareGapItem2(_pct(item1Dps / item2Dps - 1))
          : '';
      return (l10n.compareVerdictItem1(gap), 0);
    }
    if (item2Dps > item1Dps) {
      final gap = item1Dps > 0
          ? l10n.compareGapItem1(_pct(item2Dps / item1Dps - 1))
          : '';
      return (l10n.compareVerdictItem2(gap), 1);
    }
    return (l10n.compareVerdictTie, -1);
  }

  Widget _tableRow(
    BuildContext context,
    String label,
    ItemDpsResult result, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
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
            child: AnimatedTextSwitcher(
              alignment: .centerRight,
              child: Text(
                result.normalHit.formatCompact(
                  english: english,
                  traditional: traditional,
                ),
                key: ValueKey(result.normalHit),
                textAlign: TextAlign.right,
                style: style,
              ),
            ),
          ),
          Expanded(
            child: AnimatedTextSwitcher(
              alignment: .centerRight,
              child: Text(
                result.critHit.formatCompact(
                  english: english,
                  traditional: traditional,
                ),
                key: ValueKey(result.critHit),
                textAlign: TextAlign.right,
                style: style,
              ),
            ),
          ),
          Expanded(
            child: AnimatedTextSwitcher(
              alignment: .centerRight,
              child: Text(
                result.aps?.format() ?? '—',
                key: ValueKey(result.aps),
                textAlign: TextAlign.right,
                style: style,
              ),
            ),
          ),
          Expanded(
            child: AnimatedTextSwitcher(
              alignment: .centerRight,
              child: Text(
                result.dps.formatCompact(
                  english: english,
                  traditional: traditional,
                ),
                key: ValueKey(result.dps),
                textAlign: TextAlign.right,
                style: style,
              ),
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
