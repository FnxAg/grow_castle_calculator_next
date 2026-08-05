import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';

/// 公会页：展示指定公会（[guildName] 为 null 时取当前用户所在公会）的成员信息，
/// 进入时读取缓存（无缓存则立即抓取），按赛季波数（score）从大到小排列；
/// 头部信息条显示公会排名（前 300 内）。成员行可点击进入玩家详情页。
/// 手动刷新（下拉/重试）不会顶掉已有内容，失败仅提示并保留旧数据。
class GuildPage extends StatefulWidget {
  const GuildPage({super.key, this.guildName});

  /// 要展示的公会名；为 null 时使用当前用户设置的公会（drawer 场景）
  final String? guildName;

  @override
  State<GuildPage> createState() => _GuildPageState();
}

/// 公会成员详情页（带 AppBar 的完整路由壳），供工具页公会榜点击进入；
/// 内部复用 [GuildPage] 的加载与展示逻辑。
class GuildDetailPage extends StatelessWidget {
  const GuildDetailPage({super.key, required this.guildName});

  final String guildName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guildName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GuildPage(guildName: guildName),
    );
  }
}

class _GuildPageState extends State<GuildPage> {
  /// 首屏加载中（仅当界面尚无任何内容时显示全屏转圈）
  bool _firstLoading = true;
  String? _error;
  String? _guildName;

  /// 公会榜单排名；不在前 300 内为 null（不显示）
  int? _guildRank;

  /// 公会榜中与上一名/下一名的分数差距；首名/末名时对应侧为 null
  int? _guildGapPrev;
  int? _guildGapNext;
  List<GuildMember> _members = const [];
  /// 玩家赛季榜索引：玩家名(小写) → 排名
  Map<String, int> _playerRankByName = {};
  /// 无尽榜索引：玩家名(小写) → 排名
  Map<String, int> _hellRankByName = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 加载公会数据：缓存命中直接展示（手动刷新时 force 重新抓取）。
  /// 已有内容时刷新不清空界面，失败仅 SnackBar 提示并保留旧数据。
  Future<void> _load() async {
    final guild = (widget.guildName ?? Stores.infoStore.getCurrentUserGuild())
        .trim();
    final hasContent = _members.isNotEmpty;
    setState(() {
      _firstLoading = !hasContent;
      _error = null;
    });

    if (guild.isEmpty) {
      setState(() {
        _firstLoading = false;
        if (!hasContent) {
          _error = '当前用户未设置公会，请先到「用户管理」中填写公会名';
        }
      });
      return;
    }

    // 并行：公会成员详情 + 公会榜（头部排名）+ 玩家赛季榜/无尽榜（成员排名）
    final (detail, guilds, players, hell) = await (
      RankingCache.guildDetail(guild, force: hasContent),
      RankingCache.guildRanking(),
      RankingCache.playerRanking(),
      RankingCache.hellRanking(),
    ).wait;

    if (!mounted) return;

    String? refreshFailure;
    setState(() {
      _firstLoading = false;
      _guildName = guild;

      // 玩家赛季榜 / 无尽榜索引，供成员行查询各自排名
      _playerRankByName = {};
      if (players is SeasonQueryResult<PlayerRankInfo>) {
        for (final p in players.items) {
          _playerRankByName[p.name.toLowerCase()] = p.rank;
        }
      }
      _hellRankByName = {};
      if (hell is SeasonQueryResult<HellRankInfo>) {
        for (final h in hell.items) {
          _hellRankByName[h.name.toLowerCase()] = h.rank;
        }
      }

      if (detail is SeasonQueryResult<GuildMember>) {
        final members = List<GuildMember>.from(detail.items);
        // 按赛季波数（score）从大到小排列
        members.sort((a, b) => b.score.compareTo(a.score));
        _members = members;
        _error = null;
      } else if (detail is QueryError) {
        if (hasContent) {
          // 已有内容：保留旧数据，仅提示刷新失败
          refreshFailure = _errorMessage(guild, detail);
        } else {
          _error = _errorMessage(guild, detail);
        }
      }

      // 在公会榜单中查找当前公会排名（前 300 内才显示），并记录与前后的差距
      _guildRank = null;
      _guildGapPrev = null;
      _guildGapNext = null;
      if (guilds is SeasonQueryResult<GuildInfo>) {
        final items = guilds.items;
        for (var i = 0; i < items.length; i++) {
          final g = items[i];
          if (g.name.toLowerCase() == guild.toLowerCase()) {
            _guildRank = g.rank;
            // 上一名（排名靠前、分数更高）：还需多少分追上
            if (i > 0) _guildGapPrev = items[i - 1].score - g.score;
            // 下一名（排名靠后、分数更低）：领先多少分；末名无下一名
            if (i < items.length - 1) {
              _guildGapNext = g.score - items[i + 1].score;
            }
            break;
          }
        }
      }
    });

    if (refreshFailure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失败：$refreshFailure')),
      );
    }
  }

  String _errorMessage(String guild, QueryError error) {
    return switch (error) {
      NameNotFound() => '未找到公会「$guild」的信息',
      TimeoutError() => '查询超时，请稍后重试',
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_firstLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    if (_members.isEmpty) {
      return const Center(child: Text('该公会暂无成员'));
    }
    return _buildMemberList();
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
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 成员列表：按赛季波数从大到小展示，当前用户高亮
  Widget _buildMemberList() {
    final scheme = Theme.of(context).colorScheme;
    final currentUser = Stores.infoStore.getCurrentUsername();
    return Column(
      children: [
        // 公会名 + 公会排名（前 300 内）+ 成员数
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
          child: Row(
            children: [
              Icon(Icons.groups, size: 16.0, color: scheme.primary),
              const SizedBox(width: 6.0),
              Text(
                '公会：$_guildName',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // 公会榜排名（前 300 内才显示），前后为与上一名/下一名的分数差距
              if (_guildGapPrev != null) ...[
                const SizedBox(width: 8.0),
                PillChip(
                  backgroundColor: Colors.red,
                  foreground: Colors.white,
                  icon: Icons.arrow_upward,
                  text: Text(
                    _guildGapPrev!.format(),
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_guildRank != null) ...[
                const SizedBox(width: 4.0),
                PillChip(
                  text: Text(
                    '#$_guildRank',
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icons.emoji_events,
                ),
              ],
              if (_guildGapNext != null) ...[
                const SizedBox(width: 4.0),
                PillChip(
                  backgroundColor: Colors.green,
                  foreground: Colors.white,
                  icon: Icons.arrow_downward,
                  text: Text(
                    _guildGapNext!.format(),
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${_members.length} 人',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const Divider(height: 1.0),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final lowerName = member.name.toLowerCase();
                final isSelf = lowerName == currentUser.toLowerCase();
                final seasonRank = _playerRankByName[lowerName];
                final hellRank = _hellRankByName[lowerName];
                return ListTile(
                  // 点击成员进入玩家详情页
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PlayerDetailPage(playerName: member.name),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    radius: 14.0,
                    backgroundColor: isSelf
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: isSelf ? scheme.onPrimaryContainer : null,
                      ),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontWeight: isSelf ? FontWeight.bold : null,
                          color: isSelf ? scheme.primary : null,
                        ),
                      ),
                      // 个人赛季榜 / 无尽榜排名胶囊（均未上榜则不显示）
                      if (seasonRank != null || hellRank != null) ...[
                        const SizedBox(height: 2.0),
                        Wrap(
                          spacing: 4.0,
                          runSpacing: 2.0,
                          children: [
                            if (seasonRank != null)
                              PillChip(
                                text: Text(
                                  '#$seasonRank',
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                icon: Icons.eco,
                              ),
                            if (hellRank != null)
                              PillChip(
                                text: Text(
                                  '#$hellRank',
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // 无尽模式：∞ 无限符号
                                icon: Icons.all_inclusive,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    member.score.format(),
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: isSelf ? scheme.primary : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
