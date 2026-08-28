import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/last_online_cache.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/season_indicator.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 公会页：展示指定公会（[guildName] 为 null 时取当前用户所在公会）的成员信息，
/// 进入时读取缓存（无缓存则立即抓取），按赛季波数（score）从大到小排列；
/// 头部信息条显示公会排名（前 300 内）。成员行可点击进入玩家详情页。
/// 手动刷新（下拉/重试）不会顶掉已有内容，失败仅提示并保留旧数据。
class GuildPage extends StatefulWidget {
  const GuildPage({super.key, this.guildName, this.userHeader = true});

  /// 要展示的公会名；为 null 时使用当前用户设置的公会（首页公会 tab 场景）
  final String? guildName;

  /// 是否自带用户页外壳（AppBar 用户名头部 + 赛季进度）。
  /// 作为公会榜详情页嵌入其他 Scaffold 时传 false，由外层提供 AppBar。
  final bool userHeader;

  @override
  State<GuildPage> createState() => _GuildPageState();
}

/// 公会成员详情页（带 AppBar 的完整路由壳），供工具页公会榜点击进入；
/// 内部复用 [GuildPage] 的加载与展示逻辑（不自带用户页外壳）。
class GuildDetailPage extends StatelessWidget {
  const GuildDetailPage({super.key, required this.guildName});

  final String guildName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guildName),
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GuildPage(guildName: guildName, userHeader: false),
    );
  }
}

class _GuildPageState extends State<GuildPage> {
  /// 首屏加载中（仅当界面尚无任何内容时显示全屏转圈）
  bool _firstLoading = true;
  String? _error;

  /// 公会未配置的引导错误：按钮跳转「用户管理」而非重试
  bool _emptyGuild = false;

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

  /// 成员「上次在线」展示串索引：玩家名(小写) →
  /// null = 未知/加载中；'' = 封禁/无数据（显示空白）；其余为相对时间文本。
  /// 每次成员加载成功后整体重建（清理已退出公会的成员）
  Map<String, String> _lastOnlineByLower = {};

  /// 分数列宽（像素）：取全部成员 score 展示串的最大宽度固定列宽，
  /// 使各行 score 与"上次在线"分别纵向对齐
  double _scoreColumnWidth = 0;

  /// "上次在线"时间列宽（像素）：固定宽度使各行时间右对齐紧贴分数列，
  /// 联网返回时布局不漂移；开关关闭时为 0（不占位）
  double _timeColumnWidth = 0;

  /// 分数列测量/展示样式
  static const TextStyle _scoreStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
  );

  /// "上次在线"时间列测量/展示样式
  static const TextStyle _timeStyle = TextStyle(fontSize: 12.0);

  /// 测量单行文本宽度（TextPainter，逻辑像素）。
  /// 合并当前默认样式和文字缩放，确保与实际 Text 渲染一致。
  double _textWidth(String text, TextStyle style) {
    return (TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout())
        .width
        .ceilToDouble();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 加载公会数据：缓存命中直接展示；[force]（下拉全量同步）时忽略缓存
  /// 强制重新抓取。已有内容时刷新不清空界面，失败仅 SnackBar 提示并保留旧数据。
  Future<void> _load({bool force = false}) async {
    final guild = (widget.guildName ?? Stores.infoStore.getCurrentUserGuild())
        .trim();
    final hasContent = _members.isNotEmpty;
    setState(() {
      _firstLoading = !hasContent;
      _error = null;
      _emptyGuild = false;
    });

    if (guild.isEmpty) {
      setState(() {
        _firstLoading = false;
        if (!hasContent) {
          _error = _emptyGuildMessage();
          _emptyGuild = true;
        }
      });
      return;
    }

    // 并行：公会成员详情 + 公会榜（头部排名）+ 玩家赛季榜/无尽榜（成员排名）
    final (detail, guilds, players, hell) = await (
      RankingCache.guildDetail(guild, force: hasContent || force),
      RankingCache.guildRanking(force: force),
      RankingCache.playerRanking(force: force),
      RankingCache.hellRanking(force: force),
    ).wait;

    if (!mounted) return;

    String? refreshFailure;
    // 成员详情是否加载成功：成功才发起各成员"上次在线"查询
    var membersLoaded = false;
    setState(() {
      _firstLoading = false;

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
        // 固定列宽：score 列取全部成员展示串的最大文本宽度；"上次在线"列
        // 固定宽度（时间右对齐紧贴分数列），联网返回时布局不漂移。
        // 开关关闭时不查询不展示，时间列收拢为 0
        final lastOnlineEnabled =
            Stores.appSettingsStore.autoLastOnlineEnabledNotifier.value;
        _scoreColumnWidth = members.fold<double>(0, (max, m) {
          final w = _textWidth('9,999,999', _scoreStyle);
          return w > max ? w : max;
        });
        // 覆盖 formatLastOnline 的单位格式，避免 min 比 Nd 更宽而被截断。
        _timeColumnWidth = lastOnlineEnabled
            ? [
                '999min',
                '1000d',
              ].map((text) => _textWidth(text, _timeStyle)).reduce(
                (max, width) => width > max ? width : max,
              )
            : 0;
        // 同步回填各成员"上次在线"（缓存命中首帧即展示，不重放入场动画）；
        // 重建映射顺带清理已退出公会成员的旧条目；未缓存成员留空待异步拉取
        _lastOnlineByLower = {};
        if (lastOnlineEnabled) {
          for (final m in members) {
            final v = LastOnlineCache.cached(m.name);
            if (v != null) _lastOnlineByLower[m.name.toLowerCase()] = v;
          }
        }
        membersLoaded = true;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刷新失败：$refreshFailure')));
    }

    // 成员列表加载成功且开关开启才发起各成员"上次在线"查询：
    // 缓存命中零请求零动画；联网返回的新值触发逐行线性展开；
    // 失败返回 null 保留现有展示
    if (membersLoaded &&
        Stores.appSettingsStore.autoLastOnlineEnabledNotifier.value) {
      for (final m in _members) {
        LastOnlineCache.fetch(m.name, force: force).then((value) {
          if (!mounted || value == null) return;
          final key = m.name.toLowerCase();
          // 相同值跳过：避免无谓重建与动画重放
          if (_lastOnlineByLower[key] == value) return;
          final valueWidth = _textWidth(value, _timeStyle);
          setState(() {
            _lastOnlineByLower[key] = value;
            if (valueWidth > _timeColumnWidth) {
              _timeColumnWidth = valueWidth;
            }
          });
        });
      }
    }
  }

  /// 下拉刷新：与「阵容」页同步按钮一致的全量同步——
  /// 拉取个人赛季数据写入 store，再强制刷新公会成员与三类榜单（胶囊）。
  /// 个人查询失败仅提示不中断；榜单/成员失败保留旧缓存与旧数据。
  Future<void> _refresh() async {
    final guild = (widget.guildName ?? Stores.infoStore.getCurrentUserGuild())
        .trim();
    final result = await Stores.infoStore.syncCurrentUser();
    if (!mounted) return;
    if (result is QueryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步失败：${_errorMessage(guild, result)}')),
      );
    }
    // 个人查询成败与否都强制刷新公会成员与三榜单（失败保留旧缓存与胶囊）
    await _load(force: true);
  }

  String _errorMessage(String guild, QueryError error) {
    return switch (error) {
      NameNotFound() => '未找到公会「$guild」的信息',
      TimeoutError() => '查询超时，请稍后重试',
      NetworkError(:final message) => message,
    };
  }

  /// 公会为空时的提示：默认用户引导创建账号，普通用户引导填写公会
  String _emptyGuildMessage() {
    if (Stores.infoStore.getCurrentUserId() == 0) {
      return '当前为默认用户，仅用于体验基础功能。\n'
          '请到「设置」页的「用户管理」创建自己的账号，并填写公会名。';
    }
    return '当前用户未设置公会，请先到「用户管理」中填写公会名';
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_firstLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = _buildError();
    } else if (_members.isEmpty) {
      body = const Center(child: Text('该公会暂无成员'));
    } else {
      body = _buildMemberList();
    }
    // 作为公会榜详情页嵌入外层 Scaffold 时，不带用户页外壳
    if (!widget.userHeader) {
      return body;
    }
    return UserPageScaffold(
      title: '公会',
      // AppBar action 区：公会赛季进度（点击查看详情）
      actions: [SeasonIndicator(notifier: RankingCache.guildSeasonNotifier)],
      body: body,
    );
  }

  /// 查询失败提示 + 操作按钮（公会未配置时跳转用户管理，网络类错误重试）
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
            // 公会未配置：跳转「用户管理」填写；网络类错误：重试
            if (_emptyGuild)
              FilledButton.icon(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SelectUserPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.group),
                label: const Text('前往用户管理'),
              )
            else
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
    // 公会成员赛季波数总和（成员行右侧展示的就是各自 score）
    final totalScore = _members.fold<int>(0, (sum, m) => sum + m.score);
    const chipTextStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
    );
    // 公会榜排名胶囊与其前置间距成对收集；间距只插在胶囊之间，
    // 第一个胶囊前不追加 SizedBox（紧跟行首对齐左缘）
    final chips = <(Widget, double)>[
      if (_guildGapPrev != null)
        (
          PillChip(
            backgroundColor: Colors.red,
            foreground: Colors.white,
            icon: Icons.arrow_upward,
            text: Text(_guildGapPrev!.format(), style: chipTextStyle),
          ),
          8.0,
        ),
      if (_guildRank != null)
        (
          PillChip(
            text: Text('#$_guildRank', style: chipTextStyle),
            icon: Icons.flag_circle,
          ),
          4.0,
        ),
      if (_guildGapNext != null)
        (
          PillChip(
            backgroundColor: Colors.green,
            foreground: Colors.white,
            icon: Icons.arrow_downward,
            text: Text(_guildGapNext!.format(), style: chipTextStyle),
          ),
          4.0,
        ),
    ];
    return Column(
      children: [
        // 公会名 + 公会排名（前 300 内）+ 成员数
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
          child: Row(
            children: [
              // Icon(Icons.groups, size: 16.0, color: scheme.primary),
              // const SizedBox(width: 6.0),
              // Text(
              //   '公会：$_guildName',
              //   style: Theme.of(context).textTheme.bodySmall,
              // ),
              // 公会榜排名（前 300 内才显示），前后为与上一名/下一名的分数差距
              for (var i = 0; i < chips.length; i++) ...[
                chips[i].$1,
                // 间距取下一个胶囊的原始前置间距：只插在胶囊之间
                if (i < chips.length - 1) SizedBox(width: chips[i + 1].$2),
              ],
              const Spacer(),
              Text(
                '${_members.length} 人 · ${totalScore.format()}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
        const Divider(height: 1.0),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final lowerName = member.name.toLowerCase();
                final isSelf = lowerName == currentUser.toLowerCase();
                final seasonRank = _playerRankByName[lowerName];
                final hellRank = _hellRankByName[lowerName];
                final lastOnline = _lastOnlineByLower[lowerName];
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
                                icon: Icons.all_inclusive,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 上次在线固定列：文本右对齐紧贴分数列；
                      // 联网返回后在列内线性展开（右缘锚定向左生长），
                      // 首帧已有数据（缓存命中）时 AnimatedSize 不播放
                      SizedBox(
                        width: _timeColumnWidth,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.linear,
                            alignment: Alignment.centerRight,
                            child: (lastOnline == null || lastOnline.isEmpty)
                                ? const SizedBox(width: 0)
                                : TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                        lastOnline,
                                        style: _timeStyle.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                    ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      SizedBox(
                        width: _scoreColumnWidth,
                        child: Text(
                          member.score.format(),
                          textAlign: TextAlign.right,
                          style: _scoreStyle.copyWith(
                            color: isSelf ? scheme.primary : null,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
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
