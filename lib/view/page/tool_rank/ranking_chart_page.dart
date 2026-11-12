import 'package:fl_chart/fl_chart.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/models.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// 排行榜分数趋势图
class RankingChartPage extends StatefulWidget {
  const RankingChartPage({super.key, required this.kind});

  final RankingKind kind;

  @override
  State<RankingChartPage> createState() => _RankingChartPageState();
}

class _RankingChartPageState extends State<RankingChartPage> {
  int _selectedRange = 50;
  bool _loading = true;
  String? _error;
  List<RankRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await switch (widget.kind) {
      RankingKind.player => RankingCache.playerRanking(),
      RankingKind.guild => RankingCache.guildRanking(),
      RankingKind.hell => RankingCache.hellRanking(),
    };
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = false;
      if (result is QueryError) {
        _error = _errorMessage(l10n, result);
        return;
      }
      _rows = switch (widget.kind) {
        RankingKind.player when result is SeasonQueryResult<RankInfo> =>
          result.items
              .map((e) => RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        RankingKind.guild when result is SeasonQueryResult<RankInfo> =>
          result.items
              .map((e) => RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        RankingKind.hell when result is SeasonQueryResult<RankInfo> =>
          result.items
              .map((e) => RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        _ => const <RankRow>[],
      };
    });
  }

  String _errorMessage(AppLocalizations l10n, QueryError error) {
    return switch (error) {
      NameNotFound() => l10n.emptyRankingData,
      TimeoutError() => l10n.errorQueryTimeout,
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.labelRankingTrend(rankingKindLabel(l10n, widget.kind)),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text(_error!),
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).emptyData));
    }

    final visibleRows = _rows.take(_selectedRange).toList();
    final maxScore = visibleRows.fold<int>(
      0,
      (max, row) => row.score > max ? row.score : max,
    );
    final minScore = visibleRows.fold<int>(
      maxScore,
      (min, row) => row.score < min ? row.score : min,
    );

    final l10n = AppLocalizations.of(context);
    final rangeSelector = SegmentedButton<int>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: 50, label: Text(l10n.labelTopCount(50))),
        ButtonSegment(value: 100, label: Text(l10n.labelTopCount(100))),
        ButtonSegment(value: 300, label: Text(l10n.labelTopCount(300))),
      ],
      selected: {_selectedRange},
      onSelectionChanged: (selection) => setState(() {
        _selectedRange = selection.first;
      }),
    );
    final summary = Text(
      l10n.labelRankSummary(
        visibleRows.length,
        maxScore.format(),
        minScore.format(),
      ),
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    final chart = LineChart(_chartData(visibleRows, minScore, maxScore));

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.sideBySide) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            children: [
              rangeSelector,
              const SizedBox(height: 20.0),
              SizedBox(height: 320.0, child: chart),
              const SizedBox(height: 16.0),
              summary,
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rangeSelector,
              const SizedBox(height: 20.0),
              Expanded(child: chart),
              const SizedBox(height: 16.0),
              summary,
            ],
          ),
        );
      },
    );
  }

  LineChartData _chartData(List<RankRow> rows, int minScore, int maxScore) {
    final scheme = Theme.of(context).colorScheme;
    final english = context.isCompactUnitEnglish;
    final traditional = context.isTraditionalChineseLocale;
    final scoreRange = (maxScore - minScore).abs();
    final chartMinY = (minScore - scoreRange * 0.08).clamp(0, double.infinity);
    final chartMaxY = maxScore + (scoreRange == 0 ? 1 : scoreRange * 0.08);
    final labelInterval = rows.length <= 50 ? 10.0 : 50.0;
    return LineChartData(
      minX: 1.0,
      maxX: rows.length.toDouble(),
      minY: chartMinY.toDouble(),
      maxY: chartMaxY.toDouble(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: scoreRange == 0 ? 1 : scoreRange / 4,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48.0,
            getTitlesWidget: (value, meta) {
              if (value <= chartMinY || value >= chartMaxY) {
                return const SizedBox.shrink();
              }
              return Text(
                _formatAxisValue(
                  value,
                  english: english,
                  traditional: traditional,
                ),
                style: const TextStyle(fontSize: 10.0),
                textAlign: .right,
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: labelInterval,
            getTitlesWidget: (value, meta) => Text(
              '#${value.round()}',
              style: const TextStyle(fontSize: 10.0),
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideVertically: true,
          fitInsideHorizontally: true,
          getTooltipItems: (spots) => spots.map((spot) {
            final row = rows[spot.x.round() - 1];
            return LineTooltipItem(
              '${row.name}\n#${row.rank}  ${row.score.format()}',
              TextStyle(color: scheme.onInverseSurface),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (final row in rows)
              FlSpot(row.rank.toDouble(), row.score.toDouble()),
          ],
          isCurved: false,
          color: scheme.primary,
          barWidth: 2.5,
          dotData: FlDotData(show: rows.length <= 50),
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
    );
  }

  /// 轴标签
  String _formatAxisValue(
    double value, {
    required bool english,
    required bool traditional,
  }) {
    if (widget.kind != RankingKind.hell) return value.round().format();
    if (value.abs() < 10000) return value.round().format();
    return value.formatCompact(
      fractionDigits: 1,
      english: english,
      traditional: traditional,
    );
  }
}
