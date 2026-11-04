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
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// 装备对比
class ItemComparerPage extends StatefulWidget {
  const ItemComparerPage({super.key});

  @override
  State<ItemComparerPage> createState() => _ItemComparerPageState();
}

enum Actions { reset, help }

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
    final bool ready = _valueOf(_baseAttackCtrl) > 0;

    final Widget list = ListView(
      key: const PageStorageKey('item_comparer_list'),
      // padding: EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
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
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        ctrl.text.trim().isEmpty ? '—' : '${ctrl.text}${isPercent ? '%' : ''}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: () => _editPanelField(label, ctrl, isPercent: isPercent),
    );
  }

  Future<void> _editPanelField(
    String label,
    TextEditingController ctrl, {
    required bool isPercent,
  }) async {
    final controller = TextEditingController(text: ctrl.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: SelectAllTextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(suffixText: isPercent ? '%' : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context).actionSave),
          ),
        ],
      ),
    );
    if (saved == true) ctrl.text = controller.text;
    controller.dispose();
  }

  /// 两侧对比卡的并排阈值（列表内容宽度）
  static const double _sideBySideMinWidth = 600.0;

  /// 两侧装备对比区：宽度足够时左右并排，否则上下堆叠。
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
      listId: 'item1',
      itemDps: item1Dps,
      otherDps: item2Dps,
      baseDps: baseDps,
      ready: ready,
    );
    final item2Card = _buildItemCard(
      equips: _equip2,
      otherEquips: _equip1,
      side: 2,
      listId: 'item2',
      itemDps: item2Dps,
      otherDps: item1Dps,
      baseDps: baseDps,
      ready: ready,
    );

    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= _sideBySideMinWidth
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: item1Card),
                Expanded(child: item2Card),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [item1Card, item2Card],
            ),
    );
  }

  /// 一侧装备卡：标题 + 相对无装备的涨幅/胜负徽标，下挂各件装备。
  Widget _buildItemCard({
    required List<_EquipInput> equips,
    required List<_EquipInput> otherEquips,
    required int side,
    required String listId,
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
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.labelItemNumber(side),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PillChip(
                      leading: !ready || itemDps == otherDps
                          ? null
                          : Icon(
                              winning
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                            ),
                      backgroundColor: winning ? Colors.green : null,
                      text: gainText,
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < equips.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _buildEquipSection(equips, otherEquips, side, i, listId),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipSection(
    List<_EquipInput> equips,
    List<_EquipInput> otherEquips,
    int side,
    int index,
    String listId,
  ) {
    final equip = equips[index];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEquipHeader(equips, otherEquips, side, index),
        _AnimatedItemLineList(
          key: ValueKey('$listId-${equip.id}'),
          lines: equip.lines,
          onChanged: _onInputChanged,
          createLine: _createLineInput,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// 分件标题：将交换、删除、添加装备等次要操作收进菜单。
  Widget _buildEquipHeader(
    List<_EquipInput> equips,
    List<_EquipInput> otherEquips,
    int side,
    int index,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final equip = equips[index];
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.labelEquipPiece(index + 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${equip.lines.length}/$kMaxLinesPerItem',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          PopupMenuButton<String>(
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
                  _swapEquips(
                    equips,
                    equip,
                    otherEquips,
                    otherEquips[otherIndex],
                  );
                }
              }
            },
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

  Future<void> _editLine(_LineInput input) async {
    final l10n = AppLocalizations.of(context);
    final valueController = TextEditingController(text: input.valueCtrl.text);
    var selectedLine = input.line;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.actionEdit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<_LineOption>(
                initialValue: selectedLine,
                hint: Text(l10n.hintSelectLineType),
                items: [
                  for (final option in _lineOptions)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: (value) => setState(() => selectedLine = value),
              ),
              const SizedBox(height: 12),
              SelectAllTextField(
                controller: valueController,
                autofocus: selectedLine != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  hintText: l10n.hintValue,
                  suffixText: selectedLine?.isPercent == true ? '%' : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      input.line = selectedLine;
      input.valueCtrl.text = valueController.text;
      widget.onChanged();
    }
    valueController.dispose();
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
        padding: const EdgeInsets.only(top: 2),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: offset,
            child: _ItemLineRow(
              key: ObjectKey(input),
              input: input,
              onRemove: () => _removeLine(input),
              onEdit: () => _editLine(input),
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
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context).actionAddLine),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
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
          padding: const EdgeInsets.only(top: 2),
          child: FadeTransition(
            opacity: _curved,
            child: SlideTransition(
              position: _offset,
              child: _ItemLineRow(
                key: ObjectKey(widget.input),
                input: widget.input,
                onRemove: () {},
                onEdit: () {},
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
    required this.onRemove,
    required this.onEdit,
  });

  final _LineInput input;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = input.line;
    final hasValue = input.valueCtrl.text.trim().isNotEmpty;
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 4, 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                line?.label ?? AppLocalizations.of(context).hintSelectLineType,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: line == null ? scheme.onSurfaceVariant : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hasValue
                  ? '${input.valueCtrl.text}${line?.isPercent == true ? '%' : ''}'
                  : '—',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: hasValue ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).tooltipDeleteLine,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
