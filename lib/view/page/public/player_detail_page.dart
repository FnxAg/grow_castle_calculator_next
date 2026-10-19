import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/calc/wave_speed.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';

/// 玩家详情页
class PlayerDetailPage extends ConsumerStatefulWidget {
  const PlayerDetailPage({
    super.key,
    required this.playerName,
    this.embedded = false,
    this.onClose,
  });

  final String playerName;

  /// 嵌入主从两栏右侧面板
  final bool embedded;

  /// 嵌入模式头部关闭按钮回调（清除列表页的选中态）
  final VoidCallback? onClose;

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  PlayerQueryResult? _result;

  final ScrollController _scrollController = ScrollController();
  bool _showCard = true;

  late final AnimationController _cardController;
  late final CurvedAnimation _cardAnimation;

  List<SeasonWphGroup>? _wphHistory;
  int? _playerRank;
  int? _hellScore;
  int? _hellRank;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    );

    _scrollController.addListener(_handleScroll);

    _load();
  }

  void _handleScroll() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _showCard) {
      _showCard = false;
      _cardController.reverse();
    } else if (direction == ScrollDirection.forward && !_showCard) {
      _showCard = true;
      _cardController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PlayerDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerName != widget.playerName) {
      _wphHistory = null;
      _result = null;
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _cardAnimation.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final thirdPartyEnabled =
        Stores.appSettingsStore.thirdPartyApiEnabledNotifier.value;
    final (result, history, players, hell) = thirdPartyEnabled
        ? await (
            PlayerApiService.query(widget.playerName),
            PlayerApiService.queryPlayerWphHistory(
              widget.playerName,
              Stores.appSettingsStore.apiUrlNotifier.value,
              username: ref.read(currentUsernameProvider),
            ),
            RankingCache.playerRanking(),
            RankingCache.hellRanking(),
          ).wait
        : await (
            PlayerApiService.query(widget.playerName),
            Future<Object?>.value(null),
            RankingCache.playerRanking(),
            RankingCache.hellRanking(),
          ).wait;

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = false;
      _playerRank = null;
      _hellScore = null;
      _hellRank = null;
      if (result is PlayerQueryResult) {
        _result = result;
        if (history is List<SeasonWphGroup>) {
          _wphHistory = history;
        }
      } else if (result is QueryError) {
        _error = _errorMessage(l10n, result);
      }
      final lowerName = widget.playerName.toLowerCase();
      if (players is SeasonQueryResult<RankInfo>) {
        for (final player in players.items) {
          if (player.name.toLowerCase() == lowerName) {
            _playerRank = player.rank;
            break;
          }
        }
      }
      if (hell is SeasonQueryResult<RankInfo>) {
        for (final player in hell.items) {
          if (player.name.toLowerCase() == lowerName) {
            _hellScore = player.score;
            _hellRank = player.rank;
            break;
          }
        }
      }
    });
  }

  String _errorMessage(AppLocalizations l10n, QueryError error) {
    return switch (error) {
      NameNotFound() => l10n.errorSeasonDataNotFound(widget.playerName),
      TimeoutError() => l10n.errorQueryTimeout,
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.playerName),
          bottom: _loading
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(3.0),
                  child: LinearProgressIndicator(minHeight: 3.0),
                )
              : null,
        ),
        body: body,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.playerName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: AppLocalizations.of(context).tooltipCloseDetail,
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 3.0),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _result == null) return const SizedBox.shrink();
    if (_error != null) {
      return _buildError();
    }
    final r = _result!;
    if (r.wave == 0 && r.queryDate.isEmpty) {
      return _buildBanned();
    }
    return _buildResult(r);
  }

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
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).actionRetry),
            ),
          ],
        ),
      ),
    );
  }

  /// 已封禁提示
  Widget _buildBanned() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 36.0, color: scheme.error),
          const SizedBox(height: 12.0),
          Text(
            AppLocalizations.of(context).errorPlayerBanned(widget.playerName),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(PlayerQueryResult r) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final wph = ref.watch(theoreticalWphProvider);
    final isCurrentUser =
        widget.playerName.toLowerCase() ==
        ref.watch(currentUsernameProvider).toLowerCase();
    final lastOnline = PlayerApiService.formatLastOnline(
      r.queryDate,
      DateTime.now(),
    );
    const chipTextStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                if (_wphHistory != null && _wphHistory!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      l10n.labelWphHistory,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  for (final group in _wphHistory!) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        l10n.labelSeason(group.season),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: _wphGrid(
                        group.wphs,
                        isCurrentUser ? wph : _inferPassiveWph(group.wphs),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_showCard,
              child: SizeTransition(
                sizeFactor: _cardAnimation,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SummaryCard(
                    children: <Widget>[
                      SummaryRow(
                        leadingIcon: Icons.emoji_events,
                        title: Text(l10n.totalWave),
                        trailing: SummaryRowValueText(text: r.wave.format()),
                      ),
                      SummaryRow(
                        leadingIcon: Icons.eco,
                        title: Text(l10n.seasonWave),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_playerRank != null) ...[
                              PillChip(
                                text: Text(
                                  '#$_playerRank',
                                  style: chipTextStyle,
                                ),
                                icon: Icons.eco,
                              ),
                              const SizedBox(width: 8.0),
                            ],
                            SummaryRowValueText(text: r.seasonalScore.format()),
                          ],
                        ),
                      ),
                      if (_hellScore != null)
                        SummaryRow(
                          leadingIcon: Icons.all_inclusive,
                          title: Text(l10n.hellModeScore),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_hellRank != null) ...[
                                PillChip(
                                  text: Text(
                                    '#$_hellRank',
                                    style: chipTextStyle,
                                  ),
                                  icon: Icons.all_inclusive,
                                ),
                                const SizedBox(width: 8.0),
                              ],
                              SummaryRowValueText(text: _hellScore!.format()),
                            ],
                          ),
                        ),
                      SummaryRow(
                        leadingIcon: Icons.schedule,
                        title: Text(l10n.lastOnline),
                        trailing: SummaryRowValueText(text: '$lastOnline ago'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wphGrid(List<int?> wphs, int wph) {
    final schema = Theme.of(context).colorScheme;
    final slowWPH = wph * 0.95;
    final passiveWPH = wph * 1.05;
    final skipWhiteWPH = wph * 1.5;
    final nullColor = Colors.grey;
    final downColor = Colors.red;
    final slowColor = Colors.cyan;
    final passiveColor = Colors.blue;
    final skipWhiteColor = Colors.green;
    final skipOrangeColor = Colors.orange;
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCell = 48.0;
        const spacing = 6.0;
        // 每行格子数
        final perRow = ((constraints.maxWidth + spacing) / (minCell + spacing))
            .floor();
        final rows = <List<int?>>[];
        for (var i = 0; i < wphs.length; i += perRow) {
          final end = i + perRow < wphs.length ? i + perRow : wphs.length;
          rows.add(wphs.sublist(i, end));
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: r == rows.length - 1 ? 0 : spacing,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      Expanded(
                        child: Container(
                          height: 28.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: schema.primaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            rows[r][i]?.toString() ?? '—',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: switch (rows[r][i]) {
                                null => nullColor,
                                final value when value < 0 => downColor,
                                final value when value == 0 => downColor,
                                final value when value <= slowWPH => slowColor,
                                final value when value <= passiveWPH =>
                                  passiveColor,
                                final value when value <= skipWhiteWPH =>
                                  skipWhiteColor,
                                _ => skipOrangeColor,
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

final _maxTheoreticalWph = getWph(
  devilHornSkip: 6,
  isGoldAutoBattle: false,
  gameSpeed: gameSpeedRatio.length - 1,
  chronoBonus: chronoBonusRatio.length - 1,
  equipHorn: true,
  equipGoldenHorn: true,
);

int _inferPassiveWph(List<int?> wphs) {
  final upperBound = (_maxTheoreticalWph * 1.03).ceil();
  final validValues = wphs
      .where((value) => value != null && value >= 0 && value <= upperBound)
      .cast<int>()
      .toList();
  if (validValues.isEmpty || validValues.every((value) => value == 0)) {
    return 0;
  }

  // A zero snapshot must not become the baseline when positive observations
  // exist; it represents an inactive or incomplete measurement instead.
  final values = <int>[];
  final segments = <List<int>>[];
  var segment = <int>[];
  for (final value in wphs) {
    if (value == null || value <= 0 || value > upperBound) {
      if (segment.isNotEmpty) segments.add(segment);
      segment = <int>[];
      continue;
    }
    values.add(value);
    segment.add(value);
  }
  if (segment.isNotEmpty) segments.add(segment);

  var bestSegment = <int>[];
  for (final candidate in segments) {
    final stable = _findStableSegment(candidate, upperBound);
    if (stable.length > bestSegment.length ||
        (stable.length == bestSegment.length &&
            _median(stable) < _median(bestSegment))) {
      bestSegment = stable;
    }
  }
  final passive = _median(bestSegment.isEmpty ? values : bestSegment);
  return passive.round().clamp(0, upperBound);
}

List<int> _findStableSegment(List<int> values, int upperBound) {
  var bestStart = 0;
  var bestLength = 0;
  var bestMedian = double.infinity;
  for (var start = 0; start < values.length; start++) {
    var minimum = values[start];
    var maximum = values[start];
    var end = start;
    while (end + 1 < values.length) {
      final next = values[end + 1];
      final nextMinimum = minimum < next ? minimum : next;
      final nextMaximum = maximum > next ? maximum : next;
      final tolerance = (nextMaximum * 0.03).ceil().clamp(2, upperBound);
      if (nextMaximum - nextMinimum > tolerance) break;
      minimum = nextMinimum;
      maximum = nextMaximum;
      end++;
    }

    final length = end - start + 1;
    final median = _median(values.sublist(start, end + 1));
    if (length > bestLength || (length == bestLength && median < bestMedian)) {
      bestStart = start;
      bestLength = length;
      bestMedian = median;
    }
  }

  return values.sublist(bestStart, bestStart + bestLength);
}

double _median(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle].toDouble();
  return (sorted[middle - 1] + sorted[middle]) / 2;
}
