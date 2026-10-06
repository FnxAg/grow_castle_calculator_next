import 'package:fl_chart/fl_chart.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/season_indicator.dart';
import 'package:material_ui/material_ui.dart';

/// 工具 tab 下的三类排行榜
enum RankingKind {
  player(icon: Icons.eco, crossIcon: Icons.all_inclusive),
  guild(icon: Icons.flag_circle, crossIcon: null),
  hell(icon: Icons.all_inclusive, crossIcon: Icons.eco);

  const RankingKind({required this.icon, this.crossIcon});

  final IconData icon;

  final IconData? crossIcon;
}

/// [RankingKind] 的本地化名称：枚举是 const，取不到 l10n，故按 kind 解析。
/// 榜单列表以外的页面（工具页入口、趋势页标题、名次弹窗）也走这里。
String rankingKindLabel(AppLocalizations l10n, RankingKind kind) =>
    switch (kind) {
      RankingKind.player => l10n.rankingKindPlayer,
      RankingKind.guild => l10n.rankingKindGuild,
      RankingKind.hell => l10n.rankingKindHell,
    };

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
  List<_RankRow> _rows = const [];

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
    // 取 l10n 必须在 await 之后：initState 里同步取 Localizations 会断言失败
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = false;
      if (result is QueryError) {
        _error = _errorMessage(l10n, result);
        return;
      }
      _rows = switch (widget.kind) {
        RankingKind.player when result is SeasonQueryResult<PlayerRankInfo> =>
          result.items
              .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        RankingKind.guild when result is SeasonQueryResult<GuildInfo> =>
          result.items
              .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        RankingKind.hell when result is SeasonQueryResult<HellRankInfo> =>
          result.items
              .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        _ => const <_RankRow>[],
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
      body: _buildBody(),
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
        if (constraints.maxWidth < Breakpoints.expanded) {
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

  LineChartData _chartData(List<_RankRow> rows, int minScore, int maxScore) {
    final scheme = Theme.of(context).colorScheme;
    final english = !context.isChineseLocale;
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
            reservedSize: 42.0,
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

  /// 轴标签：中文用 万/亿/万亿，英文用 K/M/B（[english] 由调用点按语言传入）。
  /// 万以下的数值保留原来的取整 + 千位分隔符写法。
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

/// 榜单页
class RankingPage extends StatefulWidget {
  const RankingPage({super.key, required this.kind});

  final RankingKind kind;

  @override
  State<RankingPage> createState() => _RankingPageState();
}

/// 归一化后的榜单行
class _RankRow {
  const _RankRow({required this.rank, required this.name, required this.score});

  final int rank;
  final String name;
  final int score;
}

class _RankingPageState extends State<RankingPage> {
  static const List<int> _milestoneRanks = [1, 3, 5, 10, 50, 100, 200, 300];

  bool _firstLoading = true;
  String? _error;
  List<_RankRow> _rows = const [];

  Map<String, int> _crossRanks = {};

  String? _selectedName;

  double _lastBodyWidth = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final hasContent = _rows.isNotEmpty;
    setState(() {
      _firstLoading = !hasContent;
      _error = null;
    });

    final (result, cross) = await (
      switch (widget.kind) {
        RankingKind.player => RankingCache.playerRanking(force: force),
        RankingKind.guild => RankingCache.guildRanking(force: force),
        RankingKind.hell => RankingCache.hellRanking(force: force),
      },
      switch (widget.kind) {
        RankingKind.player => RankingCache.hellRanking(force: force),
        RankingKind.hell => RankingCache.playerRanking(force: force),
        RankingKind.guild => Future<Object?>.value(null),
      },
    ).wait;

    if (!mounted) return;
    // 取 l10n 必须在 await 之后：initState 里同步取 Localizations 会断言失败
    final l10n = AppLocalizations.of(context);

    String? refreshFailure;
    setState(() {
      _firstLoading = false;
      _error = null;

      final rows = switch (widget.kind) {
        RankingKind.player when result is SeasonQueryResult<PlayerRankInfo> =>
          result.items
              .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        RankingKind.guild when result is SeasonQueryResult<GuildInfo> =>
          result.items
              .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        RankingKind.hell when result is SeasonQueryResult<HellRankInfo> =>
          result.items
              .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
              .toList(),
        _ => const <_RankRow>[],
      };

      if (result is! QueryError) {
        // 成功获取
        _rows = rows;
      } else if (hasContent) {
        // 已有内容
        refreshFailure = _errorMessage(l10n, result);
      } else {
        _error = _errorMessage(l10n, result);
      }

      // 交叉榜单索引
      final crossRanks = switch (widget.kind) {
        RankingKind.player when cross is SeasonQueryResult<HellRankInfo> => {
          for (final e in cross.items) e.name.toLowerCase(): e.rank,
        },
        RankingKind.hell when cross is SeasonQueryResult<PlayerRankInfo> => {
          for (final e in cross.items) e.name.toLowerCase(): e.rank,
        },
        _ => null,
      };
      if (crossRanks != null) {
        _crossRanks = crossRanks;
      }
    });

    if (refreshFailure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackRefreshFailed(refreshFailure!))),
      );
    }
  }

  String _errorMessage(AppLocalizations l10n, QueryError error) {
    return switch (error) {
      NameNotFound() => l10n.emptyRankingData,
      TimeoutError() => l10n.errorQueryTimeout,
      NetworkError(:final message) => message,
    };
  }

  void _showMilestoneRanks() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.dialogRankMilestones(rankingKindLabel(l10n, widget.kind)),
          ),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _milestoneRanks.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final rank = _milestoneRanks[index];
                final row = _rows.cast<_RankRow?>().firstWhere(
                  (item) => item?.rank == rank,
                  orElse: () => null,
                );
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('$rank', style: const TextStyle(fontSize: 11)),
                  ),
                  title: Text(row?.name ?? l10n.emptyData),
                  subtitle: row == null ? null : Text(row.score.format()),
                  enabled: row != null,
                  onTap: row == null
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          _openRow(row);
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionClose),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(rankingKindLabel(l10n, widget.kind)),
        actions: [
          SeasonIndicator(
            notifier: switch (widget.kind) {
              RankingKind.player => RankingCache.playerSeasonNotifier,
              RankingKind.guild => RankingCache.guildSeasonNotifier,
              RankingKind.hell => RankingCache.hellSeasonNotifier,
            },
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: l10n.tooltipViewScoreTrend,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RankingChartPage(kind: widget.kind),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            tooltip: l10n.tooltipViewMilestoneRanks,
            onPressed: _rows.isEmpty ? null : _showMilestoneRanks,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_firstLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    if (_rows.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).emptyData));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastBodyWidth = constraints.maxWidth;
        final wide =
            widget.kind != RankingKind.guild &&
            _lastBodyWidth >= Breakpoints.masterDetailMinWidth;
        final list = _buildList(wide: wide);
        if (!wide) return list;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: list),
            const SizedBox(width: 12),
            SizedBox(
              width: Breakpoints.detailPaneWidth,
              child: _buildDetailPane(),
            ),
          ],
        );
      },
    );
  }

  void _openRow(_RankRow row) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.kind != RankingKind.guild &&
        _lastBodyWidth >= Breakpoints.masterDetailMinWidth) {
      setState(() => _selectedName = row.name);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => switch (widget.kind) {
          RankingKind.guild => GuildDetailPage(guildName: row.name),
          RankingKind.player ||
          RankingKind.hell => PlayerDetailPage(playerName: row.name),
        },
      ),
    );
  }

  /// 右侧详情面板
  Widget _buildDetailPane() {
    final name = _selectedName;
    if (name == null) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 36,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).hintSelectPlayerDetail,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return PlayerDetailPage(
      embedded: true,
      playerName: name,
      onClose: () => setState(() => _selectedName = null),
    );
  }

  /// 查询失败提示 + 重试
  Widget _buildError() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36.0, color: scheme.error),
            const SizedBox(height: 12.0),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16.0),
            FilledButton.icon(
              onPressed: () => _load(force: true),
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).actionRetry),
            ),
          ],
        ),
      ),
    );
  }

  /// 榜单列表
  Widget _buildList({required bool wide}) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];
          final crossRank = widget.kind.crossIcon == null
              ? null
              : _crossRanks[row.name.toLowerCase()];
          return ListTile(
            selected: wide && row.name == _selectedName,
            // 点击进入详情页或右侧面板
            onTap: () => _openRow(row),
            leading: CircleAvatar(
              radius: 14.0,
              backgroundColor: scheme.surfaceContainerHighest,
              child: Text(
                '${row.rank}',
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name, style: const TextStyle(fontSize: 14.0)),
                if (crossRank != null) ...[
                  const SizedBox(height: 2.0),
                  PillChip(
                    text: Text(
                      '#$crossRank',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: widget.kind.crossIcon!,
                  ),
                ],
              ],
            ),
            trailing: Text(
              row.score.format(),
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}
