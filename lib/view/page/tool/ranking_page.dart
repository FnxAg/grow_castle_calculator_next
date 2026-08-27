import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/view/page/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/season_indicator.dart';

/// 工具 tab 下的三类排行榜
enum RankingKind {
  player(title: '个人排行榜', icon: Icons.eco, crossIcon: Icons.all_inclusive),
  guild(title: '公会排行榜', icon: Icons.flag_circle, crossIcon: null),
  hell(title: '无尽排行榜', icon: Icons.all_inclusive, crossIcon: Icons.eco);

  const RankingKind({
    required this.title,
    required this.icon,
    this.crossIcon,
  });

  final String title;
  final IconData icon;

  /// 行内显示的另一榜排名胶囊图标（个人榜↔无尽榜互显；公会榜无交叉数据）
  final IconData? crossIcon;
}

/// 通用榜单页（个人/公会/无尽）：与当前用户无关。
///
/// 进入时读取 [RankingCache]（命中缓存直接展示，未命中则抓取并缓存）；
/// 刷新仅由用户下拉触发（force 强制重新请求）；刷新失败保留旧数据，
/// 仅 SnackBar 提示。行首展示该榜自身的排名，行内叠加另一榜的排名胶囊
/// （个人榜显示无尽排名，无尽榜显示赛季排名），与公会页成员行的胶囊同构。
class RankingPage extends StatefulWidget {
  const RankingPage({super.key, required this.kind});

  final RankingKind kind;

  @override
  State<RankingPage> createState() => _RankingPageState();
}

/// 归一化后的榜单行（三个榜单模型字段一致：rank/name/score）
class _RankRow {
  const _RankRow({
    required this.rank,
    required this.name,
    required this.score,
  });

  final int rank;
  final String name;
  final int score;
}

class _RankingPageState extends State<RankingPage> {
  static const List<int> _milestoneRanks = [1, 3, 5, 10, 50, 100, 200, 300];

  /// 首屏加载中（仅当界面尚无任何内容时显示全屏转圈）
  bool _firstLoading = true;
  String? _error;
  List<_RankRow> _rows = const [];

  /// 交叉榜单索引：名称(小写) → 另一榜排名，行内胶囊查询用
  Map<String, int> _crossRanks = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 加载榜单：进入时读取缓存；[force]（下拉刷新/重试）忽略缓存重新抓取。
  /// 已有内容时刷新不清空界面，失败仅 SnackBar 提示并保留旧数据。
  Future<void> _load({bool force = false}) async {
    final hasContent = _rows.isNotEmpty;
    setState(() {
      _firstLoading = !hasContent;
      _error = null;
    });

    // 并行：主榜单 + 交叉榜单（个人榜↔无尽榜互查排名，公会榜无交叉数据）
    final (result, cross) = await (
      switch (widget.kind) {
        RankingKind.player => RankingCache.playerRanking(force: force),
        RankingKind.guild => RankingCache.guildRanking(force: force),
        RankingKind.hell => RankingCache.hellRanking(force: force),
      },
      switch (widget.kind) {
        RankingKind.player => RankingCache.hellRanking(force: force),
        RankingKind.hell => RankingCache.playerRanking(force: force),
        // 公会榜没有交叉数据
        RankingKind.guild => Future<Object?>.value(null),
      },
    ).wait;

    if (!mounted) return;

    String? refreshFailure;
    setState(() {
      _firstLoading = false;
      _error = null;

      final rows = switch (widget.kind) {
        RankingKind.player when result is SeasonQueryResult<PlayerRankInfo> => result.items
            .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
            .toList(),
        RankingKind.guild when result is SeasonQueryResult<GuildInfo> => result.items
            .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
            .toList(),
        RankingKind.hell when result is SeasonQueryResult<HellRankInfo> => result.items
            .map((e) => _RankRow(rank: e.rank, name: e.name, score: e.score))
            .toList(),
        _ => const <_RankRow>[],
      };

      if (result is! QueryError) {
        // 成功（含空榜单）：覆盖展示
        _rows = rows;
      } else if (hasContent) {
        // 已有内容：保留旧数据，仅提示刷新失败
        refreshFailure = _errorMessage(result);
      } else {
        _error = _errorMessage(result);
      }

      // 交叉榜单索引（另一榜排名，行内胶囊）：成功才覆盖，失败保留旧索引
      final crossRanks = switch (widget.kind) {
        RankingKind.player when cross is SeasonQueryResult<HellRankInfo> =>
          {for (final e in cross.items) e.name.toLowerCase(): e.rank},
        RankingKind.hell when cross is SeasonQueryResult<PlayerRankInfo> =>
          {for (final e in cross.items) e.name.toLowerCase(): e.rank},
        _ => null,
      };
      if (crossRanks != null) {
        _crossRanks = crossRanks;
      }
    });

    if (refreshFailure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失败：$refreshFailure')),
      );
    }
  }

  String _errorMessage(QueryError error) {
    return switch (error) {
      NameNotFound() => '暂无榜单数据',
      TimeoutError() => '查询超时，请稍后重试',
      NetworkError(:final message) => message,
    };
  }

  void _showMilestoneRanks() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${widget.kind.title}重点排名'),
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
                  title: Text(row?.name ?? '暂无数据'),
                  subtitle: row == null ? null : Text(row.score.format()),
                  enabled: row != null,
                  onTap: row == null
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => switch (widget.kind) {
                                RankingKind.guild =>
                                  GuildDetailPage(guildName: row.name),
                                RankingKind.player || RankingKind.hell =>
                                  PlayerDetailPage(playerName: row.name),
                              },
                            ),
                          );
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.title),
        // action 区：赛季进度胶囊
        actions: [
          SeasonIndicator(
            notifier: switch (widget.kind) {
              RankingKind.player => RankingCache.playerSeasonNotifier,
              RankingKind.guild => RankingCache.guildSeasonNotifier,
              RankingKind.hell => RankingCache.hellSeasonNotifier,
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            tooltip: '查看重点排名',
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
      return const Center(child: Text('暂无数据'));
    }
    return _buildList();
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
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 榜单列表：排名/名称/分数，下拉刷新强制重新请求
  Widget _buildList() {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];
          // 另一榜排名胶囊（个人榜→无尽，无尽榜→赛季；公会榜无交叉）
          final crossRank = widget.kind.crossIcon == null
              ? null
              : _crossRanks[row.name.toLowerCase()];
          return ListTile(
            // 点击行：公会榜进入公会成员详情，玩家榜进入玩家详情
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => switch (widget.kind) {
                    RankingKind.guild => GuildDetailPage(guildName: row.name),
                    RankingKind.player || RankingKind.hell =>
                      PlayerDetailPage(playerName: row.name),
                  },
                ),
              );
            },
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
