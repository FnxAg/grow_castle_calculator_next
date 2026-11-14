import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/guild_rank.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_hell_mode_rank.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_rank.dart';
import 'package:grow_castle_calculator_next/icon/box.dart';
import 'package:grow_castle_calculator_next/icon/crystal.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/guild/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/models.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/ranking_chart_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/season_indicator.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
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
  String? _error;
  List<RankRow> _rows = const [];

  bool _viewWPHMode = false;

  Map<String, int> _crossRanks = {};

  String? _selectedName;

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
    final l10n = AppLocalizations.of(context);

    String? refreshFailure;
    setState(() {
      _firstLoading = false;
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

    final appBarInfo = AppBarInfo(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rankingKindLabel(l10n, widget.kind)),
            SeasonIndicator(
              notifier: switch (widget.kind) {
                RankingKind.player => RankingCache.playerSeasonNotifier,
                RankingKind.guild => RankingCache.guildSeasonNotifier,
                RankingKind.hell => RankingCache.hellSeasonNotifier,
              },
            ),
          ],
        ),
      ],
    );

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
      if (isDesktop) ...[
        IconButton(
          icon: const Icon(Icons.cloud_sync),
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
    ];

    return Scaffold(
      appBar: AppBar(title: appBarInfo, actions: appBarActions),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            widget.kind != RankingKind.guild &&
            constraints.maxWidth >= Breakpoints.sideBySide;
        final list = _buildList(wide: wide);
        if (!wide) return list;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: list),
            const SizedBox(width: 12),
            SizedBox(
              width: Breakpoints.detailPaneWidthFor(constraints.maxWidth),
              child: _buildDetailPane(),
            ),
          ],
        );
      },
    );
  }

  void _openRow(RankRow row) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.kind != RankingKind.guild && context.isWideContent) {
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
    final english = context.isCompactUnitEnglish;
    final traditional = context.isTraditionalChineseLocale;
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
            RankingKind.player =>
              row.score /
                  RankingCache.playerSeasonProgress()! /
                  RankingCache.playerSeasonDuration()!,
            RankingKind.guild =>
              row.score /
                  RankingCache.guildSeasonProgress()! /
                  RankingCache.guildSeasonDuration()!,
            RankingKind.hell => row.score,
          }.toDouble();
          final wphGap = switch (widget.kind) {
            RankingKind.player =>
              row.gapPrev != null
                  ? row.gapPrev! /
                        RankingCache.playerSeasonProgress()! /
                        RankingCache.playerSeasonDuration()!
                  : null,
            RankingKind.guild =>
              row.gapPrev != null
                  ? row.gapPrev! /
                        RankingCache.guildSeasonProgress()! /
                        RankingCache.guildSeasonDuration()!
                  : null,
            RankingKind.hell => row.gapPrev,
          }?.toDouble();

          return CardTile(
            selected: wide && row.name == _selectedName,
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
