import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/core/src/reward/reward.dart';
import 'package:grow_castle_calculator_next/icon/box.dart';
import 'package:grow_castle_calculator_next/icon/crystal.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/utils/date.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/navigation/app_navigator.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/models.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/history_date_actions.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/season_indicator.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

/// 榜单页
class RankingPage extends StatefulWidget {
  const RankingPage({super.key, required this.kind});

  final RankingKind kind;

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  static const List<int> _milestoneRanks = [1, 3, 5, 10, 50, 100, 200, 300];

  bool _firstLoading = true;
  bool _loading = false;
  bool get _isLoading => _firstLoading || _loading;
  String? _error;
  List<RankRow> _rows = const [];

  bool _viewWPHMode = false;

  Map<String, int> _crossRanks = {};

  /// 历史模式所选日期；null 表示当前赛季
  DateTime? _historyDate;

  /// 历史榜单返回的赛季
  final ValueNotifier<SeasonRange?> _historySeasonNotifier =
      ValueNotifier<SeasonRange?>(null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _historySeasonNotifier.dispose();
    super.dispose();
  }

  /// 当前展示榜单的赛季来源
  ValueListenable<SeasonRange?> get _activeSeasonNotifier =>
      _historyDate == null
      ? switch (widget.kind) {
          RankingKind.player => RankingCache.playerSeasonNotifier,
          RankingKind.guild => RankingCache.guildSeasonNotifier,
          RankingKind.hell => RankingCache.hellSeasonNotifier,
        }
      : _historySeasonNotifier;

  /// 丢弃过期请求的结果（快速切换日期时）
  int _loadToken = 0;

  Future<void> _load({bool force = false}) async {
    final token = ++_loadToken;
    final hasContent = _rows.isNotEmpty;
    setState(() {
      _firstLoading = !hasContent;
      _loading = true;
      _error = null;
    });

    final date = _historyDate;
    final (result, cross) = await (
      switch (widget.kind) {
        RankingKind.player =>
          date == null
              ? RankingCache.playerRanking(force: force)
              : RankingCache.playerRankingAt(date, force: force),
        RankingKind.guild =>
          date == null
              ? RankingCache.guildRanking(force: force)
              : RankingCache.guildRankingAt(date, force: force),
        RankingKind.hell =>
          date == null
              ? RankingCache.hellRanking(force: force)
              : RankingCache.hellRankingAt(date, force: force),
      },
      switch (widget.kind) {
        RankingKind.player =>
          date == null
              ? RankingCache.hellRanking(force: force)
              : RankingCache.hellRankingAt(date, force: force),
        RankingKind.hell =>
          date == null
              ? RankingCache.playerRanking(force: force)
              : RankingCache.playerRankingAt(date, force: force),
        RankingKind.guild => Future<Object?>.value(null),
      },
    ).wait;

    if (!mounted || token != _loadToken) return;
    final l10n = AppLocalizations.of(context);

    String? refreshFailure;
    setState(() {
      _firstLoading = false;
      _loading = false;
      _error = null;

      final rows = switch (widget.kind) {
        RankingKind.player when result is SeasonQueryResult<RankInfo> =>
          result.items
              .map(
                (e) => RankRow(
                  rank: e.rank,
                  name: e.name,
                  score: e.score,
                  gapPrev: e.gapPrev,
                  gapNext: e.gapNext,
                ),
              )
              .toList(),
        RankingKind.guild when result is SeasonQueryResult<RankInfo> =>
          result.items
              .map(
                (e) => RankRow(
                  rank: e.rank,
                  name: e.name,
                  score: e.score,
                  gapPrev: e.gapPrev,
                  gapNext: e.gapNext,
                ),
              )
              .toList(),
        RankingKind.hell when result is SeasonQueryResult<RankInfo> =>
          result.items
              .map(
                (e) => RankRow(
                  rank: e.rank,
                  name: e.name,
                  score: e.score,
                  gapPrev: e.gapPrev,
                  gapNext: e.gapNext,
                ),
              )
              .toList(),
        _ => const <RankRow>[],
      };

      if (result is! QueryError) {
        // 成功获取
        _rows = rows;
        if (date != null && result is SeasonQueryResult<RankInfo>) {
          _historySeasonNotifier.value = result.season;
        }
      } else if (hasContent) {
        // 已有内容
        refreshFailure = _errorMessage(l10n, result);
      } else {
        _error = _errorMessage(l10n, result);
      }

      // 交叉榜单索引
      final crossRanks = switch (widget.kind) {
        RankingKind.player when cross is SeasonQueryResult<RankInfo> => {
          for (final e in cross.items) e.name.toLowerCase(): e.rank,
        },
        RankingKind.hell when cross is SeasonQueryResult<RankInfo> => {
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
      EmptyData() => l10n.emptyHistoryData,
      TimeoutError() => l10n.errorQueryTimeout,
      NetworkError(:final message) => message,
    };
  }

  /// 切换历史日期（null 回到当前赛季）
  void _onHistoryChanged(DateTime? date) {
    setState(() {
      _historyDate = date;
      _rows = const [];
      _crossRanks = {};
      _historySeasonNotifier.value = null;
    });
    _load();
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _milestoneRanks.length,
              itemBuilder: (context, index) {
                final rank = _milestoneRanks[index];
                final row = _rows.cast<RankRow?>().firstWhere(
                  (item) => item?.rank == rank,
                  orElse: () => null,
                );
                return CardTile(
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

    final date = _historyDate;

    final floatingActionButton = FloatingActionButton.extended(
      onPressed: () => setState(() => _viewWPHMode = !_viewWPHMode),
      label: AnimatedTextSwitcher(
        child: Text(
          !_viewWPHMode ? l10n.labelScore : l10n.labelSeasonWPH,
          key: ValueKey<bool>(_viewWPHMode),
        ),
      ),
      icon: Icon(Icons.swap_vert),
    );

    final List<Widget> appBarActions = <Widget>[
      if (isDesktop && date == null) ...[
        IconButton(
          icon: _isLoading
              ? const SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Icon(Icons.cloud_sync),
          tooltip: l10n.tooltipFetchData,
          onPressed: () => _load(force: true),
        ),
        ?switch (widget.kind) {
          RankingKind.player || RankingKind.guild => IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: !_viewWPHMode ? l10n.labelScore : l10n.labelSeasonWPH,
            onPressed: () => setState(() => _viewWPHMode = !_viewWPHMode),
          ),
          RankingKind.hell => null,
        },
      ],
      IconButton(
        icon: const Icon(Icons.show_chart),
        tooltip: l10n.tooltipViewScoreTrend,
        onPressed: () =>
            context.openRankingChart(widget.kind, date: date),
      ),
      IconButton(
        icon: const Icon(Icons.format_list_numbered),
        tooltip: l10n.tooltipViewMilestoneRanks,
        onPressed: _rows.isEmpty ? null : _showMilestoneRanks,
      ),
      HistoryDateActions(date: date, onChanged: _onHistoryChanged),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rankingKindLabel(l10n, widget.kind)),
            AppBarInfo(
              children: [
                if (date != null) AppBarItem.text(formatHistoryDate(date)),
                SeasonIndicator(notifier: _activeSeasonNotifier),
              ],
            ),
          ],
        ),
        actions: appBarActions,
      ),
      body: SafeArea(top: false, child: _buildBody()),
      floatingActionButton: switch (widget.kind) {
        RankingKind.player ||
        RankingKind.guild => !isDesktop ? floatingActionButton : null,
        RankingKind.hell => null,
      },
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
    return _buildList();
  }

  void _openRow(RankRow row) {
    FocusManager.instance.primaryFocus?.unfocus();
    switch (widget.kind) {
      case RankingKind.guild:
        context.openGuildDetail(row.name, date: _historyDate);
      case RankingKind.player:
      case RankingKind.hell:
        context.openPlayerDetail(row.name);
    }
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
  Widget _buildList() {
    final scheme = Theme.of(context).colorScheme;
    final english = context.isCompactUnitEnglish;
    final traditional = context.isTraditionalChineseLocale;
    final season = _activeSeasonNotifier.value;
    // 赛季信息缺失时退回分数显示
    final progress = RankingCache.seasonProgress(season) ?? 1.0;
    final duration = RankingCache.seasonDuration(season) ?? 1;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView.builder(
        padding: UIs.padding.copyWith(
          bottom: 72.0 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];
          final crossRank = widget.kind.crossIcon == null
              ? null
              : _crossRanks[row.name.toLowerCase()];
          final reward = switch (widget.kind) {
            RankingKind.player => getRedCrystalFromPlayerRank(row.rank),
            RankingKind.hell => getRedCrystalFromHellModeRank(row.rank),
            RankingKind.guild => getItemBoxFromGuildRank(row.rank),
          };
          final rewardIcon = switch (widget.kind) {
            RankingKind.player ||
            RankingKind.hell => CrystalIcon(size: 12.0, color: scheme.primary),
            RankingKind.guild => BoxIcon(size: 12.0, color: scheme.primary),
          };
          final wph = switch (widget.kind) {
            RankingKind.player => row.score / progress / duration,
            RankingKind.guild => row.score / progress / duration,
            RankingKind.hell => row.score,
          }.toDouble();
          final wphGap = switch (widget.kind) {
            RankingKind.player =>
              row.gapPrev != null ? row.gapPrev! / progress / duration : null,
            RankingKind.guild =>
              row.gapPrev != null ? row.gapPrev! / progress / duration : null,
            RankingKind.hell => row.gapPrev,
          }?.toDouble();

          return CardTile(
            onTap: () => _openRow(row),
            leading: CircleAvatar(
              radius: 14.0,
              backgroundColor: scheme.surfaceContainerHighest,
              child: Text(
                '${row.rank}',
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
            title: Wrap(
              spacing: 4.0,
              runSpacing: 1.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(row.name, overflow: TextOverflow.ellipsis),
                if (reward != 0) PillChip(text: '$reward', leading: rewardIcon),
                if (crossRank != null)
                  PillChip(
                    text: '#$crossRank',
                    leading: Icon(widget.kind.crossIcon!),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (row.gapPrev != null) ...[
                  PillChip(
                    text: switch (widget.kind) {
                      RankingKind.hell => row.gapPrev!.formatCompact(
                        english: english,
                        traditional: traditional,
                      ),
                      RankingKind.player =>
                        !_viewWPHMode
                            ? row.gapPrev!.format()
                            : wphGap!.format(),
                      RankingKind.guild =>
                        !_viewWPHMode
                            ? row.gapPrev!.format()
                            : wphGap!.format(),
                    },
                    leading: Icon(Icons.arrow_upward_outlined),
                  ),
                  const SizedBox(width: 4.0),
                ],
                AnimatedTextSwitcher(
                  child: Text(
                    switch (widget.kind) {
                      RankingKind.hell => row.score.formatCompact(
                        english: english,
                        traditional: traditional,
                      ),
                      RankingKind.player =>
                        !_viewWPHMode ? row.score.format() : wph.format(),
                      RankingKind.guild =>
                        !_viewWPHMode ? row.score.format() : wph.format(),
                    },
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                    key: ValueKey<bool>(_viewWPHMode),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
