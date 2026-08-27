import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/game_track.dart';
import 'package:grow_castle_calculator_next/view/page/function/game_track_chart_page.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

class GameTrackPage extends StatefulWidget {
  const GameTrackPage({super.key});

  @override
  State<GameTrackPage> createState() => _GameTrackPageState();
}

class _GameTrackPageState extends State<GameTrackPage> {
  late List<GameTrackRecord> _records;
  bool _newestFirst = true;

  int get _userId => Stores.infoStore.getCurrentUserId();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _records = Stores.gameTrackStore.getRecords(_userId);
    if (_newestFirst) {
      _records = _records.reversed.toList();
    }
  }

  void _toggleSort() {
    setState(() {
      _newestFirst = !_newestFirst;
      _loadRecords();
    });
  }

  Future<void> _deleteRecord(GameTrackRecord record) async {
    final userId = _userId;
    await Stores.gameTrackStore.deleteRecord(userId, record.id);
    if (!mounted) return;
    setState(_loadRecords);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已删除轨迹记录'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            await Stores.gameTrackStore.restoreRecord(userId, record);
            if (mounted) setState(_loadRecords);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UserPageScaffold(
      title: '游戏轨迹',
      actions: [
        IconButton(
          icon: const Icon(Icons.show_chart),
          tooltip: '查看轨迹图表',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const GameTrackChartPage(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: _newestFirst ? '按时间由远到近' : '按时间由近到远',
          onPressed: _toggleSort,
        ),
      ],
      body: _records.isEmpty
          ? const Center(child: Text('暂无轨迹记录'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _records.length * 2 - 1,
              itemBuilder: (context, index) {
                if (index.isOdd) {
                  return _TrackDelta(
                    previous: _records[index ~/ 2 + 1],
                    current: _records[index ~/ 2],
                  );
                }
                return _TrackCard(
                  record: _records[index ~/ 2],
                  onDelete: () => _deleteRecord(_records[index ~/ 2]),
                );
              },
            ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.record, required this.onDelete});

  final GameTrackRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(record.recordedAt),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除记录',
                  onPressed: onDelete,
                ),
              ],
            ),
            Text(
              '总波数 ${record.wave.format()}  ·  总经济 ${record.totalGold.formatCompact(english: false)}',
            ),
            Text(
              'GP ${record.gp.format(fractionDigits: 3)}  ·  指数 ${record.gpCN.format(fractionDigits: 3)}',
            ),
            if (record.units.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final unit in record.units)
                    PillChip(text: Text('${unit.name} Lv.${unit.level}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackDelta extends StatelessWidget {
  const _TrackDelta({required this.previous, required this.current});

  final GameTrackRecord previous;
  final GameTrackRecord current;

  @override
  Widget build(BuildContext context) {
    final earlier = previous.recordedAt.isBefore(current.recordedAt)
        ? previous
        : current;
    final later = identical(earlier, previous) ? current : previous;
    final duration = later.recordedAt.difference(earlier.recordedAt);
    final hours = duration.inSeconds / 3600;
    final waveDelta = later.wave - earlier.wave;
    final waveSpeed = hours > 0 ? waveDelta / hours : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          '${_formatDuration(duration)}  ·  波数 +${waveDelta.format()}  ·  平均 WPH ${waveSpeed.format(fractionDigits: 2)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

String _formatDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  final seconds = value.inSeconds.remainder(60);
  return hours > 0
      ? '$hours小时$minutes分$seconds秒'
      : minutes > 0
          ? '$minutes分$seconds秒'
          : '$seconds秒';
}

