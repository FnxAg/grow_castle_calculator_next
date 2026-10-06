import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/item_display_rules.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';

/// 词条颜色标识
Color lineColorOf(LineColor color) => switch (color) {
  LineColor.white => Colors.white,
  LineColor.red => Colors.redAccent,
  LineColor.yellow => Colors.amber,
  LineColor.purple => Colors.purpleAccent,
};

/// 装备类型显示名：数据层 [ItemType] 没有显示名，也没有可取的 l10n，
/// 故由调用点传入 l10n 后按类型解析。
String _typeLabel(AppLocalizations l10n, ItemType type) => switch (type) {
  ItemType.bow => l10n.itemTypeBow,
  ItemType.sword => l10n.itemTypeSword,
  ItemType.staff => l10n.itemTypeStaff,
  ItemType.hammer => l10n.itemTypeHammer,
  ItemType.ring => l10n.itemTypeRing,
  ItemType.necklace => l10n.itemTypeNecklace,
  ItemType.bracelet => l10n.itemTypeBracelet,
  ItemType.earrings => l10n.itemTypeEarrings,
};

/// 词条要求显示文本：如 "Cooldown % ×2 > 3.5 < 4.5"
String _conditionLabel(LineCondition condition, ItemLine line) {
  final parts = [line.label];
  if (condition.count > 1) parts.add('×${condition.count}');
  if (condition.minValue != null) parts.add('> ${condition.minValue}');
  if (condition.maxValue != null) parts.add('< ${condition.maxValue}');
  return parts.join(' ');
}

String? _valueRangeHelperText(ItemLine line, {required bool isMin}) {
  final range = line.overallValueRange();
  if (range == null) return null;
  final (min, max) = range;
  return isMin
      ? '${min.format(fractionDigits: 1)} ≤ value ≤ ${max.format()}'
      : '${min.format(fractionDigits: 1)} < value ≤ ${max.format()}';
}

/// 高亮规则管理页：查看、新增、编辑、删除用户自定义高亮规则
class ItemRuleEditPage extends StatelessWidget {
  const ItemRuleEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.highlightRules)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const _RuleFormPage())),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddRule),
      ),
      body: ValueListenableBuilder<List<UserHighlightRule>>(
        valueListenable: Stores.itemRuleStore.rulesNotifier,
        builder: (context, rules, _) {
          if (rules.isEmpty) {
            return Center(child: Text(l10n.emptyItemRuleHint));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: rules.length,
            itemBuilder: (context, index) => _RuleCard(rule: rules[index]),
          );
        },
      ),
    );
  }
}

/// 单条规则卡片
class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule});

  final UserHighlightRule rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // 未启用的规则置灰显示
      child: Opacity(
        opacity: rule.enabled ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 启用勾选：可直接勾选/取消，决定该规则是否参与匹配
                  Checkbox(
                    value: rule.enabled,
                    onChanged: (v) => Stores.itemRuleStore.updateRule(
                      rule.copyWith(enabled: v ?? false),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rule.hint.isEmpty ? l10n.unnamedRule : rule.hint,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (rule.pinToTop)
                    Tooltip(
                      message: l10n.tooltipPinToTop,
                      child: Icon(
                        Icons.vertical_align_top,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: l10n.actionEdit,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => _RuleFormPage(initial: rule),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: l10n.actionDelete,
                    onPressed: () => Stores.itemRuleStore.removeRule(rule.id),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final entry in rule.lines.entries)
                      Chip(
                        label: Text(
                          _conditionLabel(entry.value, entry.key),
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: lineColorOf(entry.key.color)
                            .withValues(alpha: 0.15),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ),
              // 装备类型限制
              if (rule.types != null && rule.types!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6),
                  child: Text(
                    l10n.labelItemTypes(
                      rule.types!
                          .map((t) => _typeLabel(l10n, t))
                          .join(l10n.listSeparator),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 规则编辑表单（新增/编辑共用）
class _RuleFormPage extends StatefulWidget {
  const _RuleFormPage({this.initial});

  final UserHighlightRule? initial;

  @override
  State<_RuleFormPage> createState() => _RuleFormPageState();
}

class _RuleFormPageState extends State<_RuleFormPage> {
  late final TextEditingController _hintController;

  /// 各词条的要求数量（containsKey 表示已勾选）
  late final Map<ItemLine, int> _counts;

  /// 各词条的数值范围输入（留空表示不限）
  final Map<ItemLine, TextEditingController> _minControllers = {};
  final Map<ItemLine, TextEditingController> _maxControllers = {};
  late final Set<ItemType> _selectedTypes;
  bool _pinToTop = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _hintController = TextEditingController(text: initial?.hint ?? '');
    _counts = {
      for (final entry in (initial?.lines ?? const {}).entries)
        entry.key: entry.value.count,
    };
    for (final entry in (initial?.lines ?? const {}).entries) {
      _minControllers[entry.key] = TextEditingController(
        text: entry.value.minValue?.toString() ?? '',
      );
      _maxControllers[entry.key] = TextEditingController(
        text: entry.value.maxValue?.toString() ?? '',
      );
    }
    _selectedTypes = {...?initial?.types};
    _pinToTop = initial?.pinToTop ?? true;
  }

  @override
  void dispose() {
    _hintController.dispose();
    for (final controller in _minControllers.values) {
      controller.dispose();
    }
    for (final controller in _maxControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 白色词条要求数量合计（跨词条）
  int get _whiteSum {
    var sum = 0;
    for (final entry in _counts.entries) {
      if (entry.key.color == LineColor.white) sum += entry.value;
    }
    return sum;
  }

  /// 是否已勾选红色词条
  bool get _hasRed => _counts.keys.any((l) => l.color == LineColor.red);

  /// 词条是否有可约束的数值范围
  bool _hasValueRange(ItemLine line) =>
      line.color == LineColor.white ||
      line == ItemLine.itemQuality ||
      (line.color == LineColor.red && !line.isFixed) ||
      (line.color == LineColor.purple && !line.isFixed);

  /// 勾选/取消一个词条（含防呆：红/金同色最多 1 条，白 3 条与红互斥，
  /// 紫词条与其它颜色互斥）
  void _toggleLine(ItemLine line, bool checked) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (!checked) {
        _counts.remove(line);
        return;
      }
      // 紫词条与其他颜色词条互斥，且只能同时出现一条
      if (line.color == LineColor.purple) {
        _counts.removeWhere((existing, _) => existing != line);
        _counts[line] = 1;
        _ensureRangeControllers(line);
        return;
      }
      _counts.removeWhere((existing, _) => existing.color == LineColor.purple);

      // 红/金词条同色最多一条：选择新词条时自动取消同色已选项
      if (line.color == LineColor.red || line.color == LineColor.yellow) {
        final sameColor = _counts.keys
            .where((l) => l.color == line.color)
            .toList();
        for (final existing in sameColor) {
          _counts.remove(existing);
        }
      }
      // 防呆：已有红词条时白色合计最多 2 条
      if (line.color == LineColor.white && _hasRed && _whiteSum + 1 > 2) {
        _showHint(l10n.errorWhiteLinesWithRed);
        return;
      }
      if (line.color == LineColor.white && _whiteSum + 1 > 3) {
        _showHint(l10n.errorWhiteLinesMax);
        return;
      }
      if (line.color == LineColor.red && _whiteSum >= 3) {
        _showHint(l10n.errorRedWithThreeWhite);
        return;
      }
      _counts[line] = 1;
      _ensureRangeControllers(line);
    });
  }

  /// 勾选后才需要范围输入框的控制器（取消勾选时不销毁，保留已输入的数值）
  void _ensureRangeControllers(ItemLine line) {
    if (!_hasValueRange(line)) return;
    _minControllers.putIfAbsent(line, TextEditingController.new);
    _maxControllers.putIfAbsent(line, TextEditingController.new);
  }

  /// 调整白色词条数量（1 ↔ 2），带合计上限检查
  void _setWhiteCount(ItemLine line, int count) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      final current = _counts[line] ?? 1;
      if (count > current) {
        // 1 → 2：白色合计 +1
        final newSum = _whiteSum + 1;
        if (_hasRed && newSum > 2) {
          _showHint(l10n.errorWhiteLinesWithRed);
          return;
        }
        if (newSum > 3) {
          _showHint(l10n.errorWhiteLinesMax);
          return;
        }
      }
      _counts[line] = count;
    });
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    if (_counts.isEmpty) {
      _showHint(l10n.errorNoLineSelected);
      return;
    }
    // 解析数值范围（留空 = 不限）
    final lines = <ItemLine, LineCondition>{};
    for (final entry in _counts.entries) {
      final minText = _minControllers[entry.key]?.text.trim() ?? '';
      final maxText = _maxControllers[entry.key]?.text.trim() ?? '';
      final minValue = minText.isEmpty ? null : double.tryParse(minText);
      final maxValue = maxText.isEmpty ? null : double.tryParse(maxText);
      if ((minText.isNotEmpty && minValue == null) ||
          (maxText.isNotEmpty && maxValue == null)) {
        _showHint(l10n.errorValueNotNumber);
        return;
      }
      // 防呆：下限必须小于上限
      if (minValue != null && maxValue != null && minValue >= maxValue) {
        _showHint(l10n.errorMinGreaterThanMax);
        return;
      }
      // 防呆：数值不能超出该词条的 roll 值范围（跨等级并集）
      final overall = entry.key.overallValueRange();
      if (overall != null) {
        final (overallMin, overallMax) = overall;
        if (minValue != null &&
            (minValue < overallMin || minValue >= overallMax)) {
          _showHint(
            l10n.errorMinOutOfRange(
              entry.key.label,
              overallMin.format(),
              overallMax.format(),
            ),
          );
          return;
        }
        if (maxValue != null &&
            (maxValue <= overallMin || maxValue > overallMax)) {
          _showHint(
            l10n.errorMaxOutOfRange(
              entry.key.label,
              overallMin.format(),
              overallMax.format(),
            ),
          );
          return;
        }
      }
      lines[entry.key] = LineCondition(
        count: entry.value,
        minValue: minValue,
        maxValue: maxValue,
      );
    }
    final store = Stores.itemRuleStore;
    final initial = widget.initial;
    // 完整构造新规则（编辑也走完整构造）：
    // 未选类型时 types 为 null（不限），copyWith 无法把 types 清回 null
    final rule = UserHighlightRule(
      id: initial?.id ?? newRuleId(),
      hint: _hintController.text.trim(),
      lines: lines,
      pinToTop: _pinToTop,
      enabled: initial?.enabled ?? true,
      types: _selectedTypes.isEmpty ? null : {..._selectedTypes},
    );
    if (initial == null) {
      store.addRule(rule);
    } else {
      store.updateRule(rule);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? l10n.actionAddRule : l10n.titleEditRule,
        ),
        actions: [TextButton(onPressed: _save, child: Text(l10n.actionSave))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _hintController,
                  // 不指定 border：与页内其它输入框一致走默认的底部横线
                  decoration: InputDecoration(
                    labelText: l10n.labelHintText,
                    hintText: l10n.hintRuleHintExample,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.labelPinToTop),
                  value: _pinToTop,
                  onChanged: (v) => setState(() => _pinToTop = v),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.labelSelectItemTypes,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final type in ItemType.values)
                      FilterChip(
                        label: Text(_typeLabel(l10n, type)),
                        visualDensity: VisualDensity.compact,
                        selected: _selectedTypes.contains(type),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedTypes.add(type);
                          } else {
                            _selectedTypes.remove(type);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 词条多选
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    l10n.helpRuleForm,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final color in LineColor.values) ...[
                  _sectionHeader(l10n, color),
                  for (final line in ItemLine.values.where(
                    (l) => l.color == color,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _counts.containsKey(line),
                                // 白色词条合计 3 条时禁止勾选红色词条
                                onChanged:
                                    line.color == LineColor.red &&
                                        _whiteSum >= 3
                                    ? null
                                    : (checked) =>
                                          _toggleLine(line, checked ?? false),
                              ),
                              Expanded(
                                child: Text(
                                  line.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              // 白词条可同时出现两条
                              if (_counts.containsKey(line) &&
                                  line.color == LineColor.white)
                                SegmentedButton<int>(
                                  segments: [
                                    ButtonSegment(
                                      value: 1,
                                      label: Text(l10n.labelLineCount(1)),
                                    ),
                                    ButtonSegment(
                                      value: 2,
                                      label: Text(l10n.labelLineCount(2)),
                                    ),
                                  ],
                                  selected: {_counts[line] ?? 1},
                                  showSelectedIcon: false,
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onSelectionChanged: (s) =>
                                      _setWhiteCount(line, s.first),
                                ),
                            ],
                          ),
                          // 数值范围
                          if (_counts.containsKey(line) && _hasValueRange(line))
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 48,
                                right: 8,
                                bottom: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _minControllers[line],
                                      textAlign: TextAlign.center,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      // 只允许数字与一个小数点
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                      // 下限校验允许等于词条最小值，但必须小于最大值。
                                      decoration: InputDecoration(
                                        helperText: _valueRangeHelperText(
                                          line,
                                          isMin: true,
                                        ),
                                        suffixText:
                                            line.numType == LineNumType.percent
                                            ? '%'
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    ' ≤ target ≤ ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _maxControllers[line],
                                      textAlign: TextAlign.center,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        helperText: _valueRangeHelperText(
                                          line,
                                          isMin: false,
                                        ),
                                        suffixText:
                                            line.numType == LineNumType.percent
                                            ? '%'
                                            : null,
                                        // isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(AppLocalizations l10n, LineColor color) {
    final (background, foreground) = switch (color) {
      LineColor.white => (Colors.grey.shade400, Colors.black87),
      LineColor.red => (Colors.redAccent, Colors.white),
      LineColor.yellow => (Colors.amber, Colors.black87),
      LineColor.purple => (Colors.purpleAccent, Colors.white),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          switch (color) {
            LineColor.white => l10n.lineColorWhite,
            LineColor.red => l10n.lineColorRed,
            LineColor.yellow => l10n.lineColorGold,
            LineColor.purple => l10n.lineColorPurple,
          },
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: foreground, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
