import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/game_track.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';

class GameTrackChartPage extends ConsumerStatefulWidget {
  const GameTrackChartPage({super.key});

  @override
  ConsumerState<GameTrackChartPage> createState() => _GameTrackChartPageState();
}

class _GameTrackChartPageState extends ConsumerState<GameTrackChartPage> {
  static const int _maxChartPoints = 300;

  late List<GameTrackRecord> _records;
  late List<GameTrackRecord> _chartRecords;

  int get _userId => ref.read(currentUserIdProvider);

  @override
  void initState() {
    super.initState();
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      reloadForCurrentUser();
    });
    _loadRecords();
  }

  void reloadForCurrentUser() {
    setState(_loadRecords);
  }

  void _loadRecords() {
    _records = Stores.gameTrackStore.getRecords(_userId);
    _chartRecords = _downsampleRecords(_records);
  }

  List<GameTrackRecord> _downsampleRecords(List<GameTrackRecord> records) {
    if (records.length <= _maxChartPoints) {
      return records;
    }

    final bucketSize =
        (records.length + _maxChartPoints - 1) ~/ _maxChartPoints;
    final downsampled = <GameTrackRecord>[];

    void addIfNew(GameTrackRecord record) {
      if (downsampled.isEmpty || downsampled.last.id != record.id) {
        downsampled.add(record);
      }
    }

    addIfNew(records.first);
    for (var i = 1; i < records.length - 1; i += bucketSize) {
      final end = i + bucketSize < records.length - 1
          ? i + bucketSize
          : records.length - 1;
      var min = records[i];
      var max = records[i];
      for (var j = i + 1; j < end; j++) {
        final record = records[j];
        if (record.totalGold < min.totalGold) min = record;
        if (record.totalGold > max.totalGold) max = record;
      }
      addIfNew(min);
      addIfNew(max);
    }
    addIfNew(records.last);
    return downsampled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.gameTrackChart), _AppBarInfo()],
        ),
        actions: [
          if (_records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  l10n.labelChartRange(
                    _formatAppBarDate(_records.first.recordedAt),
                    _formatAppBarDate(_records.last.recordedAt),
                  ),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
        ],
      ),
      body: _chartRecords.length < 2
          ? Center(child: Text(l10n.emptyChartNeedTwoRecords))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _buildChartBody(context, constraints),
              ),
            ),
    );
  }

  /// 图表区
  Widget _buildChartBody(BuildContext context, BoxConstraints constraints) {
    final notice = _chartRecords.length == _records.length
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLocalizations.of(context)
                  .labelChartDownsampled(_records.length, _chartRecords.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );

    if (constraints.maxWidth < Breakpoints.chartGridMinWidth) {
      return ListView(
        children: [?notice, _buildChartGrid(context, fillHeight: false)],
      );
    }
    return Column(
      children: [
        ?notice,
        Expanded(child: _buildChartGrid(context, fillHeight: true)),
      ],
    );
  }

  /// 4 张图表
  Widget _buildChartGrid(BuildContext context, {required bool fillHeight}) {
    final l10n = AppLocalizations.of(context);
    final panels = [
      for (final chart in [
        (
          l10n.totalWave,
          (GameTrackRecord r) => r.wave.toDouble(),
          (double value) => value.round().format(),
        ),
        (
          l10n.totalEconomy,
          (GameTrackRecord r) => r.totalGold,
          (double value) => value.formatCompact(
            english: !context.isChineseLocale,
            traditional: context.isTraditionalChineseLocale,
          ),
        ),
        (
          'GP',
          (GameTrackRecord r) => r.gp,
          (double value) => value.format(fractionDigits: 3),
        ),
        (
          l10n.metricIndex,
          (GameTrackRecord r) => r.gpCN,
          (double value) => value.format(fractionDigits: 3),
        ),
      ])
        _ChartPanel(
          title: chart.$1,
          records: _chartRecords,
          valueOf: chart.$2,
          formatValue: chart.$3,
          fillHeight: fillHeight,
        ),
    ];
    if (!fillHeight) return Column(children: panels);

    return Column(
      children: [
        for (var row = 0; row < panels.length; row += 2)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: panels[row]),
                const SizedBox(width: 12),
                Expanded(child: panels[row + 1]),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.records,
    required this.valueOf,
    required this.formatValue,
    required this.fillHeight,
  });

  final String title;
  final List<GameTrackRecord> records;
  final double Function(GameTrackRecord) valueOf;
  final String Function(double) formatValue;

  /// 图表是否吃掉卡片剩余高度
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final points = records
        .map(
          (record) => FlSpot(
            record.recordedAt.millisecondsSinceEpoch.toDouble(),
            valueOf(record),
          ),
        )
        .toList();
    final automaticYMin = points.map((point) => point.y).reduce(_min);
    final automaticYMax = points.map((point) => point.y).reduce(_max);
    final yPadding = (automaticYMax - automaticYMin).abs() * 0.1;
    final minimumY = automaticYMin - (yPadding == 0 ? 1 : yPadding);
    final maximumY = automaticYMax + (yPadding == 0 ? 1 : yPadding);
    final minimumX = points.first.x;
    final maximumX = points.last.x;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${formatValue(minimumY)} ~ ${formatValue(maximumY)}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _chartSlot(
              fillHeight,
              LineChart(
                LineChartData(
                  minX: minimumX,
                  maxX: maximumX <= minimumX ? minimumX + 1 : maximumX,
                  minY: minimumY,
                  maxY: maximumY <= minimumY ? minimumY + 1 : maximumY,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (touchedSpot) =>
                          scheme.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map(
                            (spot) => LineTooltipItem(
                              '${_formatDate(DateTime.fromMillisecondsSinceEpoch(spot.x.round()))}\n'
                              '${formatValue(spot.y)}',
                              Theme.of(context).textTheme.bodySmall!,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: false,
                      color: scheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0.5),
                            scheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 60,
                        interval: null,
                        getTitlesWidget: (value, meta) => Text(
                          formatValue(value),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;

/// 图表槽位
Widget _chartSlot(bool fillHeight, Widget chart) =>
    fillHeight ? Expanded(child: chart) : SizedBox(height: 240, child: chart);

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

String _formatAppBarDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}/${two(value.month)}/${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = <Widget>[CurrentUser()];
    return AppBarInfo(children: segments);
  }
}
