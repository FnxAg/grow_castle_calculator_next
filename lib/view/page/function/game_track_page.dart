import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/game_track.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/function/track/game_track_chart_page.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/current_user_reload.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

class GameTrackPage extends StatefulWidget {
  const GameTrackPage({super.key});

  @override
  State<GameTrackPage> createState() => _GameTrackPageState();
}

class _GameTrackPageState extends State<GameTrackPage> with CurrentUserReload {
  late List<GameTrackRecord> _records;
  bool _newestFirst = true;

  int get _userId => Stores.infoStore.getCurrentUserId();
  bool get _gameTrackEnabled =>
      Stores.appSettingsStore.gameTrackEnabledNotifier.value;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 轨迹记录按 userId 读取，切换用户后重新取一份
  @override
  void reloadForCurrentUser() {
    setState(_loadRecords);
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
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.snackTrackDeleted),
        action: SnackBarAction(
          label: l10n.actionUndo,
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
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        Stores.infoStore.currentUserNotifier,
        Stores.infoStore.dataVersionNotifier,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: .start,
              children: [
                Text(l10n.gameTrack),
                _AppBarInfo(trackLength: _records.length),
              ],
            ),
            actions: [
              if (!_gameTrackEnabled && _userId != 0 && _records.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.warning, color: Colors.orange),
                  tooltip: l10n.dialogWarning,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.dialogWarning),
                        content: Text(l10n.dialogGameTrackOff),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.actionGotIt),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.show_chart),
                tooltip: l10n.tooltipViewTrackChart,
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
                tooltip: _newestFirst
                    ? l10n.tooltipSortOldestFirst
                    : l10n.tooltipSortNewestFirst,
                onPressed: _toggleSort,
              ),
            ],
          ),
          body: Column(
            children: [
              _userId == 0
                  ? Expanded(
                      child: Center(child: Text(l10n.emptyTrackDefaultUser)),
                    )
                  : _records.isEmpty && !_gameTrackEnabled
                  ? Expanded(
                      child: Center(child: Text(l10n.emptyTrackDisabled)),
                    )
                  : _records.isEmpty
                  ? Expanded(child: Center(child: Text(l10n.emptyGameTrack)))
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _records.length * 2 - 1,
                        itemBuilder: (context, index) {
                          if (index.isOdd) {
                            return _TrackDelta(
                              previous: _records[index ~/ 2 + 1],
                              current: _records[index ~/ 2],
                            );
                          }
                          final record = _records[index ~/ 2];
                          return _TrackCard(
                            record: record,
                            onDelete: () => _deleteRecord(record),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
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
    final trackInfo = [
      PillChip(icon: Icons.emoji_events, text: Text('${record.wave}')),
      PillChip(
        icon: Icons.monetization_on,
        text: Text(
          record.totalGold.formatCompact(
            english: !context.isChineseLocale,
            traditional: context.isTraditionalChineseLocale,
          ),
        ),
      ),
      PillChip(
        icon: Icons.star,
        text: Text(
          '${record.gp.format(fractionDigits: 3)} · ${record.gpCN.format(fractionDigits: 3)}',
        ),
      ),
    ];
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
                  tooltip: AppLocalizations.of(context).tooltipDeleteRecord,
                  onPressed: onDelete,
                ),
              ],
            ),
            // 用 Wrap 而非 Row：英文单位（K/M）比中文（万/亿）宽一点，
            // 三个胶囊在窄屏排不下时应当换行而不是溢出
            Wrap(spacing: 4, runSpacing: 4, children: trackInfo),
            if (record.units.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final unit in record.units)
                    Builder(
                      builder: (context) => PillChip(
                        text: Text('${unit.name} Lv.${unit.level}'),
                        backgroundColor: unit.enabled
                            ? null
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                      ),
                    ),
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
          '${_formatDuration(duration)}  ·  +${waveDelta.format()}  ·  ${waveSpeed.format(fractionDigits: 2)}',
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
  return '${hours.toString()}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

class _AppBarInfo extends StatelessWidget {
  final int trackLength;

  const _AppBarInfo({required this.trackLength});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(fontSize: 12.0);
    final Widget trackInfo = Text(
      AppLocalizations.of(context).labelTrackCount(trackLength),
      style: textStyle,
    );
    final List<Widget> segments = <Widget>[CurrentUser(), trackInfo];
    return AppBarInfo(children: segments);
  }
}
