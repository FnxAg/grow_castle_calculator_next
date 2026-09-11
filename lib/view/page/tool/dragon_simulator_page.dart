import 'dart:isolate';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/item_display_rules.dart';
import 'package:grow_castle_calculator_next/core/src/item_generator.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/tool/item_rule_edit_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/short_window_fallback.dart';

const _rollBatchSize = 500;

Future<Map<String, dynamic>> _rollBatch(Map<String, dynamic> args) async {
  final generator = ItemGenerator(random: Random());
  final source = ItemSource.values[args['source'] as int];
  final rules = [
    for (final rule in args['rules'] as List)
      UserHighlightRule.fromJson(Map<String, dynamic>.from(rule as Map)),
  ];

  for (var i = 0; i < _rollBatchSize; i++) {
    final item = generator.generate(source: source);
    if (matchRule(item, rules) != null) {
      return {
        'count': i + 1,
        'item': {
          'level': item.level.index,
          'type': item.type.index,
          'lines': [
            for (final line in item.lines)
              {
                'line': line.line.index,
                'value': line.value,
                'rawValue': line.rawValue,
              },
          ],
        },
      };
    }
  }
  return {'count': _rollBatchSize};
}

Future<void> _rollBatchInIsolateEntry(List<dynamic> message) async {
  final sendPort = message[0] as SendPort;
  final args = Map<String, dynamic>.from(message[1] as Map);
  sendPort.send(await _rollBatch(args));
}

Future<Map<String, dynamic>> _rollBatchInIsolate(
  Map<String, dynamic> args,
) async {
  final resultPort = ReceivePort();
  final isolate = await Isolate.spawn(
    _rollBatchInIsolateEntry,
    [resultPort.sendPort, args],
  );
  try {
    return Map<String, dynamic>.from(await resultPort.first as Map);
  } finally {
    resultPort.close();
    isolate.kill(priority: Isolate.immediate);
  }
}

GeneratedItem _generatedItemFromMap(Map<String, dynamic> data) {
  return GeneratedItem(
    level: ItemLevel.values[data['level'] as int],
    type: ItemType.values[data['type'] as int],
    lines: [
      for (final rawLine in data['lines'] as List)
        GeneratedLine(
          ItemLine.values[(rawLine as Map)['line'] as int],
          (rawLine['value'] as num).toDouble(),
          rawValue: (rawLine['rawValue'] as num?)?.toDouble(),
        ),
    ],
  );
}

class DragonSimulatorPage extends StatefulWidget {
  const DragonSimulatorPage({super.key});

  @override
  State<DragonSimulatorPage> createState() => _DragonSimulatorPageState();
}

class _DragonSimulatorPageState extends State<DragonSimulatorPage> {
  final _generator = ItemGenerator(random: Random());

  ItemSource _source = ItemSource.dragon6;
  int _count = 1000;
  List<GeneratedItem> _items = [];

  /// roll到死 状态
  bool _rolling = false;
  int _rollRunId = 0;
  int _rollCount = 0;
  String? _rollResult;

  @override
  void initState() {
    super.initState();
  }

  void _generate() {
    _rollRunId++;
    setState(() {
      _rolling = false;
      _rollResult = null;
      _items = [
        for (var i = 0; i < _count; i++)
          _generator.generate(source: _source),
      ];
    });
  }

  /// roll到死：一件一件自动 roll，直到命中已启用的高亮规则（可手动停止）
  Future<void> _startRollToHit() async {
    if (_rolling) return;
    if (!Stores.itemRuleStore.rules.any((r) => r.enabled)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在“高亮规则”中启用至少一条规则')),
      );
      return;
    }
    setState(() {
      _rolling = true;
      _rollCount = 0;
      _rollResult = null;
      _items = [];
    });
    final runId = ++_rollRunId;
    final rules = [
      for (final rule in Stores.itemRuleStore.rules) rule.toJson(),
    ];
    final batchArgs = <String, dynamic>{
      'source': _source.index,
      'rules': rules,
    };
    var count = 0;
    while (_rolling && mounted && runId == _rollRunId) {
      // 批量计算放到后台 isolate，避免 Windows UI isolate 被长时间占满。
      final result = await _rollBatchInIsolate(batchArgs);
      count += result['count'] as int;
      if (!mounted || runId != _rollRunId) return;
      if (!_rolling) break;
      final rawItem = result['item'];
      if (rawItem != null) {
        final item = _generatedItemFromMap(Map<String, dynamic>.from(rawItem as Map));
        setState(() {
          _rolling = false;
          _rollCount = count;
          _rollResult = '命中！共 roll 了 ${count.format()} 次';
          _items = [item];
        });
        return;
      }
      setState(() => _rollCount = count);
    }
    // 手动停止
    if (!mounted || runId != _rollRunId) return;
    setState(() {
      _rolling = false;
      _rollCount = count;
      _rollResult = '已手动停止，共 roll 了 ${count.format()} 次';
    });
  }

  void _stopRollToHit() => setState(() => _rolling = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelCount = <ItemLevel, int>{};
    for (final item in _items) {
      levelCount.update(item.level, (c) => c + 1, ifAbsent: () => 1);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('刷龙模拟器'),
        actions: [
          IconButton(
            tooltip: '高亮规则',
            icon: const Icon(Icons.rule),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ItemRuleEditPage(),
                ),
              );
            },
          ),
        ],
      ),
      // 本页固定设置区最高（约 440），矮窗口下必须能滚
      body: ShortWindowFallback(minHeight: 460, child: Column(
        children: [
          // ── 设置区 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('装备来源', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ItemSource>(
                  segments: [
                    for (final source in ItemSource.values)
                      ButtonSegment(
                        value: source,
                        label: Text(source.label),
                        // 二龙起的掉落含高级装备，标注一下
                        tooltip: source.dropRates.entries
                            .map((e) => '${e.key.name} ${(e.value * 100).toStringAsFixed(1)}%')
                            .join(' / '),
                      ),
                  ],
                  selected: {_source},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _source = s.first),
                ),
                const SizedBox(height: 16),
                Text('roll 单次数量', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 10, label: Text('10')),
                    ButtonSegment(value: 100, label: Text('100')),
                    ButtonSegment(value: 1000, label: Text('1000')),
                    ButtonSegment(value: 10000, label: Text('10000')),
                  ],
                  selected: {_count},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _count = s.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.casino_outlined),
                        label: const Text('roll 单次'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _rolling ? _stopRollToHit : _startRollToHit,
                        icon: Icon(_rolling ? Icons.stop : Icons.autorenew),
                        label: Text(_rolling ? '停止' : 'roll 到死'),
                      ),
                    ),
                  ],
                ),
                // roll到死 状态提示
                if (_rolling || _rollResult != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _rolling
                          ? 'roll 到死进行中：已 roll ${_rollCount.format()} 次…'
                          : _rollResult!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _rolling ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      
          // ── 本次等级分布 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final entry in levelCount.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '${entry.key.name} ×${entry.value}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 16),
      
          // ── 结果区（规则变更时自动刷新排序与高亮）──
          Expanded(
            child: ValueListenableBuilder<List<UserHighlightRule>>(
              valueListenable: Stores.itemRuleStore.rulesNotifier,
              builder: (context, rules, _) {
                // 命中规则（如白cd + 红cd + 加强）的装备置顶，
                // 其余按装备等级从高到低排列：E > L > S > A > B
                final items = [..._items]..sort((a, b) {
                    final pinnedA = matchRule(a, rules)?.pinToTop ?? false;
                    final pinnedB = matchRule(b, rules)?.pinToTop ?? false;
                    if (pinnedA != pinnedB) return pinnedA ? -1 : 1;
                    return b.level.index.compareTo(a.level.index);
                  });
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ItemCard(item: item, rule: matchRule(item, rules));
                  },
                );
              },
            ),
          ),
        ],
      )),
    );
  }
}

/// 单件装备卡片
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, this.rule});

  final GeneratedItem item;

  /// 命中的用户高亮规则；null 表示无特殊规则
  final UserHighlightRule? rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rule = this.rule;
    final highlight = rule != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // 命中特殊规则时整体高亮
      color: highlight ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 特殊规则提示
            if (rule != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '✦ ${rule.hint.isEmpty ? '未命名规则' : rule.hint}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // 头部：等级 + 类型
            Row(
              children: [
                Text('[${item.level.name}]', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(item.type.name, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in item.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _lineColorOf(line.line.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line.line.label)),
                    Text(
                      _valueText(line),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            // itemQuality 提示
            // if (quality != null)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 4),
            //     child: Text(
            //       'Item Quality ${_natural(quality)}% → 前 3 条 ×${_natural(1 + quality / 100)}',
            //       style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Color _lineColorOf(LineColor color) => switch (color) {
        LineColor.white => Colors.white,
        LineColor.red => Colors.redAccent,
        LineColor.yellow => Colors.amber,
      };

  /// 数值显示：被加强的词条显示“原始值 -> 加强后的值”，
  /// 加强后的值不受小数位限制，该有几位小数就有几位小数
  String _valueText(GeneratedLine line) {
    final raw = line.rawValue;
    if (line.isBoosted && raw != null) {
      return '${_natural(raw)} -> ${_natural(line.value)}';
    }
    return _natural(line.value);
  }

  /// 按自然精度显示（最多 6 位小数，去掉多余的 0）
  String _natural(double value) {
    var text = value.toStringAsFixed(6);
    if (text.contains('.')) {
      text = text
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }
}
