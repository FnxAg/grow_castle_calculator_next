import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:measure_size/render_object.dart';

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
  final ValueNotifier<double> paddingHeight = ValueNotifier<double>(0.0);
  final ValueNotifier<double> summaryOffset = ValueNotifier<double>(0.0);

  late final AnimationController _snapController;
  double _snapStart = 0.0;
  double _snapEnd = 0.0;

  /// 第三方 API 的每赛季每小时波速快照（null 表示未加载/失败，区块不展示）
  List<SeasonWphGroup>? _wphHistory;

  /// 玩家赛季榜排名；不在榜单或榜单请求失败时为 null
  int? _playerRank;

  /// 无尽榜分数；不在榜单或榜单请求失败时为 null
  int? _hellScore;

  /// 无尽榜排名；不在榜单或榜单请求失败时为 null
  int? _hellRank;

  @override
  void initState() {
    super.initState();

    _snapController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          summaryOffset.value =
              _snapStart + (_snapEnd - _snapStart) * _snapController.value;
        });

    _load();
  }

  @override
  void didUpdateWidget(covariant PlayerDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 主从面板复用同一实例切换玩家,，重置展示状态并重新拉取
    if (oldWidget.playerName != widget.playerName) {
      paddingHeight.value = 0;
      summaryOffset.value = 0;
      _wphHistory = null;
      _result = null;
      _load();
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    paddingHeight.dispose();
    summaryOffset.dispose();
    super.dispose();
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      final height = paddingHeight.value;
      if (delta != null && delta != 0.0 && height > 0.0) {
        _snapController.stop();
        summaryOffset.value = (summaryOffset.value + delta)
            .clamp(0.0, height)
            .toDouble();
      }
    } else if (notification is ScrollEndNotification) {
      _snapSummary();
    }

    return false;
  }

  void _snapSummary() {
    final height = paddingHeight.value;
    if (height <= 0.0) return;

    _snapStart = summaryOffset.value;
    _snapEnd = summaryOffset.value >= height / 2.0 ? height : 0.0;
    _snapController
      ..reset()
      ..forward();
  }

  /// 并行查询
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
    // 此处已在 await 之后，initState 的同步段不能查 Localizations
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
      if (players is SeasonQueryResult<PlayerRankInfo>) {
        for (final player in players.items) {
          if (player.name.toLowerCase() == lowerName) {
            _playerRank = player.rank;
            break;
          }
        }
      }
      if (hell is SeasonQueryResult<HellRankInfo>) {
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
    final lastOnline = PlayerApiService.formatLastOnline(
      r.queryDate,
      DateTime.now(),
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: paddingHeight,
                builder: (context, value, child) {
                  return ValueListenableBuilder<double>(
                    valueListenable: summaryOffset,
                    builder: (context, offset, child) {
                      return ListView(
                        padding: EdgeInsets.only(
                          left: 16.0,
                          // top: isDesktop ? value : (value - offset).clamp(0.0, value),
                          top: value,
                          right: 16.0,
                          bottom: 8.0,
                        ),
                        children: <Widget>[
                          if (_wphHistory != null &&
                              _wphHistory!.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12.0,
                                bottom: 4.0,
                              ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  bottom: 4.0,
                                ),
                                child: _wphGrid(group.wphs),
                              ),
                            ],
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: summaryOffset,
              builder: (context, offset, child) {
                final height = paddingHeight.value;
                final opacity = height <= 0.0
                    ? 1.0
                    : (1.0 - offset / height).clamp(0.0, 1.0);
                const chipTextStyle = TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                );
                return Positioned(
                  top: -offset,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: opacity == 0.0,
                    child: Opacity(
                      opacity: opacity,
                      child: MeasureSize(
                        onChange: (value) {
                          paddingHeight.value = value.height;
                          if (summaryOffset.value > value.height) {
                            summaryOffset.value = value.height;
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SummaryCard(
                            children: <Widget>[
                              SummaryRow(
                                leadingIcon: Icons.emoji_events,
                                title: Text(l10n.totalWave),
                                trailing: SummaryRowValueText(
                                  text: r.wave.format(),
                                ),
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
                                    SummaryRowValueText(
                                      text: r.seasonalScore.format(),
                                    ),
                                  ],
                                ),
                              ),
                              if (_hellScore != null)
                                SummaryRow(
                                  leadingIcon: Icons.all_inclusive,
                                  title: Text(l10n.endlessScore),
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
                                      SummaryRowValueText(
                                        text: _hellScore!.format(),
                                      ),
                                    ],
                                  ),
                                ),
                              SummaryRow(
                                leadingIcon: Icons.schedule,
                                title: Text(l10n.lastOnline),
                                trailing: SummaryRowValueText(
                                  text: '$lastOnline ago',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _wphGrid(List<int?> wphs) {
    final scheme = Theme.of(context).colorScheme;
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
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            rows[r][i]?.toString() ?? '—',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
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
