import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/calc/item_dps.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/backup_service.dart';
import 'package:grow_castle_calculator_next/core/src/item/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/item_comparer_store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/utils/divider.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:material_ui/material_ui.dart';

/// 装备对比
class ItemComparerPage extends StatefulWidget {
  const ItemComparerPage({super.key});

  @override
  State<ItemComparerPage> createState() => _ItemComparerPageState();
}

enum Actions { reset, help }

/// 无装备面板中的一个属性
enum AttributeType {
  baseAttack('Base Attack', isPercent: false),
  increasedDmg('Increased Damage'),
  moreDmg('More Damage'),
  critChance('Critical Chance'),
  critDmg('Critical Damage'),
  baseAps('Attacks Per Second', isPercent: false),
  increasedSpeed('Increased Speed');

  const AttributeType(this.label, {this.isPercent = true});

  final String label;

  /// 是否按百分比显示（输入框后缀、面板数值）
  final bool isPercent;
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

/// 一件装备的一条词条（词条选项 + 数值文本）
class _LineInput {
  _LineInput({this.line, this.value = ''});

  _LineOption? line;
  String value;
}

/// 一侧对比中的一件装备（最多 [kMaxLinesPerItem] 条词条）
class _EquipInput {
  final List<_LineInput> lines = [];
}

class _ItemComparerPageState extends State<ItemComparerPage> {
  /// 无装备面板各属性的输入框
  final Map<AttributeType, TextEditingController> _ctrls = {
    for (final type in AttributeType.values) type: TextEditingController(),
  };

  /// 两侧对比的装备
  final _equip1 = <_EquipInput>[];
  final _equip2 = <_EquipInput>[];

  bool _restoring = false;

  Iterable<TextEditingController> get _panelCtrls => _ctrls.values;

  TextEditingController _ctrl(AttributeType type) => _ctrls[type]!;

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
    super.dispose();
  }

  /// 数据恢复/导入完成：整页输入按新 store 数据重建
  void _onDataRestored() {
    if (!mounted) return;
    _restoring = true;
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

  _EquipInput _createEquip() => _EquipInput()..lines.add(_LineInput());

  void _addEquip(List<_EquipInput> equips) {
    if (equips.length >= kMaxEquipsPerSide) return;
    setState(() => equips.add(_createEquip()));
    _saveToStore();
  }

  void _removeEquip(List<_EquipInput> equips, _EquipInput equip) {
    if (equips.length <= 1) return;
    setState(() => equips.remove(equip));
    _saveToStore();
  }

  /// 打开一件装备的词条编辑页，保存后写回并持久化
  Future<void> _editEquip(_EquipInput equip, int index) async {
    final lines = await Navigator.of(context).push<List<_LineInput>>(
      MaterialPageRoute(
        builder: (context) => _EquipEditPage(
          title: AppLocalizations.of(context).labelEquipPiece(index + 1),
          lines: equip.lines,
        ),
      ),
    );
    if (lines == null || !mounted) return;
    equip.lines
      ..clear()
      ..addAll(lines);
    _onInputChanged();
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
    for (final type in AttributeType.values) {
      _ctrl(type).text = _readStore(store, type);
    }
    _restoreEquips(_equip1, store.item1);
    _restoreEquips(_equip2, store.item2);
    if (_equip1.isEmpty) _equip1.add(_createEquip());
    if (_equip2.isEmpty) _equip2.add(_createEquip());
  }

  /// 面板输入在 store 中的持久化字段
  static String _readStore(ItemComparerStore store, AttributeType type) =>
      switch (type) {
        AttributeType.baseAttack => store.baseAttack,
        AttributeType.increasedDmg => store.increasedDmg,
        AttributeType.moreDmg => store.moreDmg,
        AttributeType.critChance => store.critChance,
        AttributeType.critDmg => store.critDmg,
        AttributeType.baseAps => store.baseAps,
        AttributeType.increasedSpeed => store.speed,
      };

  static void _writeStore(
    ItemComparerStore store,
    AttributeType type,
    String value,
  ) {
    switch (type) {
      case AttributeType.baseAttack:
        store.baseAttack = value;
      case AttributeType.increasedDmg:
        store.increasedDmg = value;
      case AttributeType.moreDmg:
        store.moreDmg = value;
      case AttributeType.critChance:
        store.critChance = value;
      case AttributeType.critDmg:
        store.critDmg = value;
      case AttributeType.baseAps:
        store.baseAps = value;
      case AttributeType.increasedSpeed:
        store.speed = value;
    }
  }

  void _restoreEquips(
    List<_EquipInput> target,
    List<List<ItemComparerLineInput>> saved,
  ) {
    for (final savedLines in saved) {
      final equip = _EquipInput();
      for (final input in savedLines) {
        equip.lines.add(
          _LineInput(
            line: input.isMoreDmg
                ? const _LineOption.moreDmg()
                : input.isElementDamage
                ? const _LineOption.elementDamage()
                : input.line != null
                ? _LineOption.item(input.line!)
                : null,
            value: input.value,
          ),
        );
      }
      if (equip.lines.isEmpty) equip.lines.add(_LineInput());
      target.add(equip);
    }
  }

  void _saveToStore() {
    final store = Stores.itemComparerStore;
    for (final type in AttributeType.values) {
      _writeStore(store, type, _ctrl(type).text);
    }
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
                value: input.value,
              ),
          ],
      ]);
  }

  double _valueOf(AttributeType type) => _valueOfText(_ctrl(type).text);

  double _valueOfText(String text) => double.tryParse(text.trim()) ?? 0;

  /// 空文本表示未填写（攻速相关字段未填时按未提供处理）
  double? _optionalValue(AttributeType type) {
    final text = _ctrl(type).text.trim();
    return text.isEmpty ? null : double.tryParse(text) ?? 0;
  }

  ItemDpsResult _computeItemResult(List<_EquipInput> equips) {
    // 同一侧多件装备的词条叠加计算
    final lines = [for (final equip in equips) ...equip.lines];
    return computeItemDps(
      baseAttack: _valueOf(AttributeType.baseAttack),
      increasedDmg: _valueOf(AttributeType.increasedDmg),
      moreDmg: _valueOf(AttributeType.moreDmg),
      critChance: _valueOf(AttributeType.critChance),
      critDmg: _valueOf(AttributeType.critDmg),
      baseAps: _optionalValue(AttributeType.baseAps),
      increasedSpeed: _optionalValue(AttributeType.increasedSpeed),
      lines: [
        for (final input in lines)
          if (input.line != null &&
              !input.line!.isMoreDmg &&
              !input.line!.isElementDamage &&
              input.value.trim().isNotEmpty)
            (line: input.line!.line!, value: _valueOfText(input.value)),
      ],
      moreDmgLines: [
        for (final input in lines)
          if (input.line?.isMoreDmg == true && input.value.trim().isNotEmpty)
            _valueOfText(input.value),
      ],
      elementDmgLines: [
        for (final input in lines)
          if (input.line?.isElementDamage == true &&
              input.value.trim().isNotEmpty)
            _valueOfText(input.value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    final baseResult = _computeItemResult(const []);
    final item1Result = _computeItemResult(_equip1);
    final item2Result = _computeItemResult(_equip2);
    final baseDps = baseResult.dps;
    final item1Dps = item1Result.dps;
    final item2Dps = item2Result.dps;
    final bool ready = _valueOf(AttributeType.baseAttack) > 0;

    final Widget list = ListView(
      key: const PageStorageKey('item_comparer_list'),
      padding: UIs.padding,
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
        ..._buildPanelCard(),
        const SizedBox(height: 20),
        _buildCompareCards(
          ready: ready,
          baseDps: baseDps,
          item1Dps: item1Dps,
          item2Dps: item2Dps,
        ),
      ],
    );

    final popupMenuButton = PopupMenuButton<Actions>(
      itemBuilder: (context) => [
        PopupMenuItem(value: Actions.reset, child: Text(l10n.actionReset)),
        PopupMenuItem(value: Actions.help, child: Text(l10n.actionHelp)),
      ],
      onSelected: (value) => switch (value) {
        Actions.reset => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.actionReset),
            content: Text(l10n.dialogReset),
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
        Actions.help => showDialog<void>(
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
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Text(l10n.toolItemComparer)]),
        actions: [popupMenuButton],
      ),
      body: SafeArea(top: false, child: list),
    );
  }

  List<Widget> _buildPanelCard() => [
    for (final type in AttributeType.values) _panelField(type),
  ];

  Widget _panelField(AttributeType type) {
    final ctrl = _ctrl(type);
    return CardTile(
      title: Text(type.label),
      trailing: Text(
        ctrl.text.trim().isEmpty
            ? '—'
            : '${ctrl.text}${type.isPercent ? '%' : ''}',
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _editPanelField(type),
    );
  }

  Future<void> _editPanelField(AttributeType type) async {
    final ctrl = _ctrl(type);
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _PanelFieldDialog(attribute: type, initialValue: ctrl.text),
    );
    if (text != null) ctrl.text = text;
  }

  Widget _buildCompareCards({
    required bool ready,
    required double baseDps,
    required double item1Dps,
    required double item2Dps,
  }) {
    final item1Card = _buildItemCard(
      equips: _equip1,
      otherEquips: _equip2,
      side: 1,
      itemDps: item1Dps,
      otherDps: item2Dps,
      baseDps: baseDps,
      ready: ready,
    );
    final item2Card = _buildItemCard(
      equips: _equip2,
      otherEquips: _equip1,
      side: 2,
      itemDps: item2Dps,
      otherDps: item1Dps,
      baseDps: baseDps,
      ready: ready,
    );

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [item1Card, item2Card],
      ),
    );
  }

  Widget _buildItemCard({
    required List<_EquipInput> equips,
    required List<_EquipInput> otherEquips,
    required int side,
    required double itemDps,
    required double otherDps,
    required double baseDps,
    required bool ready,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final winning = ready && itemDps > otherDps;
    final hasGain = baseDps > 0;
    final gainText = hasGain
        ? '${((itemDps / baseDps - 1) * 100).toStringAsFixed(2)}%'
        : '—';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SectionHeader(
            l10n.labelItemNumber(side),
            trailing: PillChip(
              leading: !ready || itemDps == otherDps
                  ? null
                  : Icon(winning ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              backgroundColor: winning ? Colors.green : null,
              text: gainText,
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            color: ListTileTheme.of(context).tileColor,
            shape: RoundedRectangleBorder(
              borderRadius: UIs.cardShape.borderRadius,
              side: BorderSide(
                color: winning ? scheme.primary : scheme.outlineVariant,
                width: winning ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < equips.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildEquipRow(equips, otherEquips, side, i),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipRow(
    List<_EquipInput> equips,
    List<_EquipInput> otherEquips,
    int side,
    int index,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final equip = equips[index];
    final summary = _equipSummary(equip);
    return CardTile(
      leading: CircleAvatar(
        radius: 14.0,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        summary.isEmpty ? '—' : summary,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: summary.isEmpty ? scheme.onSurfaceVariant : null,
        ),
      ),
      onTap: () => _editEquip(equip, index),
      trailing: PopupMenuButton<String>(
        padding: const EdgeInsets.all(8),
        iconSize: 20,
        itemBuilder: (context) => [
          if (equips.length < kMaxEquipsPerSide)
            PopupMenuItem(value: 'add', child: Text(l10n.actionAddEquip)),
          for (var i = 0; i < otherEquips.length; i++)
            PopupMenuItem(
              value: 'swap:$i',
              child: Text(
                dividerText([
                  l10n.tooltipSwapEquip,
                  l10n.labelItemNumber(side == 1 ? 2 : 1),
                  l10n.labelEquipPiece(i + 1),
                ]),
              ),
            ),
          if (equips.length > 1)
            PopupMenuItem(
              value: 'delete',
              child: Text(l10n.tooltipDeleteEquip),
            ),
        ],
        onSelected: (value) {
          if (value == 'add') {
            _addEquip(equips);
          } else if (value == 'delete') {
            _removeEquip(equips, equip);
          } else if (value.startsWith('swap:')) {
            final otherIndex = int.tryParse(value.substring(5));
            if (otherIndex != null && otherIndex < otherEquips.length) {
              _swapEquips(equips, equip, otherEquips, otherEquips[otherIndex]);
            }
          }
        },
      ),
    );
  }

  String _equipSummary(_EquipInput equip) {
    final lines = [
      for (final input in equip.lines)
        if (input.line != null) _lineSummary(input.line!, input.value),
    ];
    return lines.join('\n');
  }

  static String _lineSummary(_LineOption line, String value) {
    final text = value.trim();
    if (text.isEmpty) return line.label;
    if (!line.isPercent) return '${line.label} $text';
    // 词条名已自带 “%”，数值后不再重复
    return '${line.label.replaceAll('%', '').trim()} $text%';
  }
}

class _PanelFieldDialog extends StatefulWidget {
  const _PanelFieldDialog({
    required this.attribute,
    required this.initialValue,
  });

  final AttributeType attribute;
  final String initialValue;

  @override
  State<_PanelFieldDialog> createState() => _PanelFieldDialogState();
}

class _PanelFieldDialogState extends State<_PanelFieldDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.attribute.label),
      content: SelectAllTextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        decoration: InputDecoration(
          suffixText: widget.attribute.isPercent ? '%' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

/// 编辑一件装备的词条：三组词条常驻，未选择的组不参与计算
class _EquipEditPage extends StatefulWidget {
  const _EquipEditPage({required this.title, required this.lines});

  final String title;
  final List<_LineInput> lines;

  @override
  State<_EquipEditPage> createState() => _EquipEditPageState();
}

/// 编辑页内的词条草稿：取消时不影响装备，保存时才写回
class _LineDraft {
  _LineDraft({this.line, String value = ''})
    : valueCtrl = TextEditingController(text: value);

  _LineOption? line;
  final TextEditingController valueCtrl;

  void dispose() => valueCtrl.dispose();

  _LineInput toInput() => _LineInput(line: line, value: valueCtrl.text);
}

class _EquipEditPageState extends State<_EquipEditPage> {
  late final List<_LineDraft> _drafts = [
    for (var i = 0; i < kMaxLinesPerItem; i++)
      i < widget.lines.length
          ? _LineDraft(line: widget.lines[i].line, value: widget.lines[i].value)
          : _LineDraft(),
  ];

  late final List<ExpansibleController> _expansionController = [
    for (var i = 0; i < kMaxLinesPerItem; i++) ExpansibleController(),
  ];

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    for (final controller in _expansionController) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 仅写回已选择的词条，未选择的组丢弃
  void _save() {
    Navigator.of(context).pop([
      for (final draft in _drafts)
        if (draft.line != null) draft.toInput(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: Text(l10n.actionSave),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 88,
            left: UIs.padding.left,
            right: UIs.padding.right,
          ),
          children: [
            for (var i = 0; i < _drafts.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _buildLineGroup(i, _drafts[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineGroup(int index, _LineDraft draft) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = draft.line != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpansionCardTile(
          key: PageStorageKey('item_line_$index'),
          controller: _expansionController[index],
          title: Text(
            draft.line?.label ?? l10n.optionNotSelected,
            style: selected ? null : TextStyle(color: scheme.onSurfaceVariant),
          ),
          children: [
            for (final option in <_LineOption?>[null, ..._lineOptions])
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: Icon(
                  draft.line == option
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: draft.line == option
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                title: Text(option?.label ?? l10n.optionNotSelected),
                onTap: () => setState(() {
                  draft.line = option;
                  _expansionController[index].collapse();
                }),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SelectAllTextField(
            controller: draft.valueCtrl,
            enabled: selected,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.hintValue,
              suffixText: draft.line?.isPercent == true ? '%' : null,
            ),
          ),
        ),
      ],
    );
  }
}
