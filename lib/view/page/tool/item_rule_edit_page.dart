import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/item_display_rules.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';

/// 词条颜色标识
Color lineColorOf(LineColor color) => switch (color) {
      LineColor.white => Colors.white,
      LineColor.red => Colors.redAccent,
      LineColor.yellow => Colors.amber,
    };

/// 装备类型显示名
const _typeLabels = <ItemType, String>{
  ItemType.bow: '弓',
  ItemType.sword: '剑',
  ItemType.staff: '杖',
  ItemType.hammer: '锤',
  ItemType.ring: '戒指',
  ItemType.necklace: '项链',
  ItemType.bracelet: '手镯',
  ItemType.earrings: '耳环',
};

/// 词条要求显示文本：如 "Cooldown % ×2 > 3.5 < 4.5"
String _conditionLabel(LineCondition condition, ItemLine line) {
  final parts = [line.label];
  if (condition.count > 1) parts.add('×${condition.count}');
  if (condition.minValue != null) parts.add('> ${condition.minValue}');
  if (condition.maxValue != null) parts.add('< ${condition.maxValue}');
  return parts.join(' ');
}

/// 高亮规则管理页：查看、新增、编辑、删除用户自定义高亮规则
class ItemRuleEditPage extends StatelessWidget {
  const ItemRuleEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高亮规则')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const _RuleFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新增规则'),
      ),
      body: ValueListenableBuilder<List<UserHighlightRule>>(
        valueListenable: Stores.itemRuleStore.rulesNotifier,
        builder: (context, rules, _) {
          if (rules.isEmpty) {
            return const Center(child: Text('暂无规则，点击右下角新增'));
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
                    onChanged: (v) => Stores.itemRuleStore
                        .updateRule(rule.copyWith(enabled: v ?? false)),
                  ),
                  Expanded(
                    child: Text(
                      rule.hint.isEmpty ? '未命名规则' : rule.hint,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (rule.pinToTop)
                    Tooltip(
                      message: '命中后置顶',
                      child: Icon(
                        Icons.vertical_align_top,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: '编辑',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => _RuleFormPage(initial: rule),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: '删除',
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
                        backgroundColor:
                            lineColorOf(entry.key.color).withValues(alpha: 0.15),
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
                    '装备类型：${rule.types!.map((t) => _typeLabels[t]).join('、')}',
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

  /// 词条是否有可约束的数值范围（白词条、itemQuality、非固定值红词条）
  bool _hasValueRange(ItemLine line) =>
      line.color == LineColor.white ||
      line == ItemLine.itemQuality ||
      (line.color == LineColor.red && !line.isFixed);

  /// 勾选/取消一个词条（含防呆：红/黄同色最多 1 条，白 3 条与红互斥）
  void _toggleLine(ItemLine line, bool checked) {
    setState(() {
      if (!checked) {
        _counts.remove(line);
        return;
      }
      // 红/黄词条同色最多一条：选择新词条时自动取消同色已选项
      if (line.color == LineColor.red || line.color == LineColor.yellow) {
        final sameColor =
            _counts.keys.where((l) => l.color == line.color).toList();
        for (final existing in sameColor) {
          _counts.remove(existing);
        }
      }
      // 防呆：已有红词条时白色合计最多 2 条
      if (line.color == LineColor.white && _hasRed && _whiteSum + 1 > 2) {
        _showHint('已有红色词条，白色词条最多 2 条');
        return;
      }
      if (line.color == LineColor.white && _whiteSum + 1 > 3) {
        _showHint('白色词条最多 3 条');
        return;
      }
      if (line.color == LineColor.red && _whiteSum >= 3) {
        _showHint('白色词条已达 3 条，不能选择红色词条');
        return;
      }
      _counts[line] = 1;
      if (_hasValueRange(line)) {
        _minControllers.putIfAbsent(line, TextEditingController.new);
        _maxControllers.putIfAbsent(line, TextEditingController.new);
      }
    });
  }

  /// 调整白色词条数量（1 ↔ 2），带合计上限检查
  void _setWhiteCount(ItemLine line, int count) {
    setState(() {
      final current = _counts[line] ?? 1;
      if (count > current) {
        // 1 → 2：白色合计 +1
        final newSum = _whiteSum + 1;
        if (_hasRed && newSum > 2) {
          _showHint('已有红色词条，白色词条最多 2 条');
          return;
        }
        if (newSum > 3) {
          _showHint('白色词条最多 3 条');
          return;
        }
      }
      _counts[line] = count;
    });
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (_counts.isEmpty) {
      _showHint('请至少选择一个词条');
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
        _showHint('数值需为数字或留空');
        return;
      }
      // 防呆：下限必须小于上限
      if (minValue != null && maxValue != null && minValue >= maxValue) {
        _showHint('下限（大于）必须小于上限（小于）');
        return;
      }
      // 防呆：数值不能超出该词条的 roll 值范围（跨等级并集）
      final overall = entry.key.overallValueRange();
      if (overall != null) {
        final (overallMin, overallMax) = overall;
        if (minValue != null &&
            (minValue < overallMin || minValue >= overallMax)) {
          _showHint(
            '"${entry.key.label}" 的下限超出 roll 值范围'
            '（${overallMin.format()} ~ ${overallMax.format()}）',
          );
          return;
        }
        if (maxValue != null &&
            (maxValue <= overallMin || maxValue > overallMax)) {
          _showHint(
            '"${entry.key.label}" 的上限超出 roll 值范围'
            '（${overallMin.format()} ~ ${overallMax.format()}）',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '新增规则' : '编辑规则'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _hintController,
                  decoration: const InputDecoration(
                    labelText: '提示文本',
                    hintText: '如：红白加强（可留空）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('命中后置顶显示'),
                  value: _pinToTop,
                  onChanged: (v) => setState(() => _pinToTop = v),
                ),
                const SizedBox(height: 8),
                Text(
                  '指定装备类型（不选则不限）',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final type in ItemType.values)
                      FilterChip(
                        label: Text(_typeLabels[type]!),
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
          // 词条多选：按颜色分组；白词条可要求同时出现两条（1条/2条切换）
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    '提示：红/金词条各最多选 1 条；白色词条合计 3 条时不能选红色词条；\n'
                    '输入数值范围时，判断的是词条原始值（加强前的值），留空表示不限。\n\n'
                    '注意：数值范围没有强校验，请确认后再保存，否则可能导致规则无法命中。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final color in LineColor.values) ...[
                  _sectionHeader(color),
                  for (final line
                      in ItemLine.values.where((l) => l.color == color))
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
                              // 白词条可同时出现两条（其他颜色词条每槽最多一条）
                              if (_counts.containsKey(line) &&
                                  line.color == LineColor.white)
                                SegmentedButton<int>(
                                  segments: const [
                                    ButtonSegment(value: 1, label: Text('1条')),
                                    ButtonSegment(value: 2, label: Text('2条')),
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
                          // 数值范围（留空不限）：判断的是词条原始值（加强前的值）。
                          // 没有数值范围的词条（黄词条、固定值红词条）不显示
                          if (_counts.containsKey(line) &&
                              _hasValueRange(line))
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
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      // 只允许数字与一个小数点
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: '大于',
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _maxControllers[line],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: '小于',
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
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

  Widget _sectionHeader(LineColor color) {
    // 背景色：白词条用灰色底（白色底在浅色模式下看不见），红/黄用词条本色；
    // 文字颜色按背景深浅取黑白，保证两种主题模式都可读
    final (background, foreground) = switch (color) {
      LineColor.white => (Colors.grey.shade400, Colors.black87),
      LineColor.red => (Colors.redAccent, Colors.white),
      LineColor.yellow => (Colors.amber, Colors.black87),
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
            LineColor.white => '白词条',
            LineColor.red => '红词条',
            LineColor.yellow => '金词条',
          },
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
