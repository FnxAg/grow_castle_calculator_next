import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/last_online_cache.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user_guild.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/last_online.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/loading_indicator_app_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/season_indicator.dart';
import 'package:material_ui/material_ui.dart';

/// 公会页
class GuildPage extends ConsumerStatefulWidget {
  const GuildPage({super.key, this.guildName, this.userHeader = true});

  final String? guildName;

  final bool userHeader;

  @override
  ConsumerState<GuildPage> createState() => _GuildPageState();
}

/// 公会成员详情页
class GuildDetailPage extends StatelessWidget {
  const GuildDetailPage({super.key, required this.guildName});

  final String guildName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(guildName)),
      body: GuildPage(guildName: guildName, userHeader: false),
    );
  }
}

class _GuildPageState extends ConsumerState<GuildPage> {
  bool _firstLoading = true;
  bool _loading = true;
  String? _error;

  /// 公会未配置的引导错误
  bool _emptyGuild = false;

  bool _emptyGuildIsDefaultUser = false;

  /// 公会榜单排名
  int? _guildRank;

  /// 公会榜中与上一名/下一名的分数差距
  int? _guildGapPrev;
  int? _guildGapNext;
  List<GuildMember> _members = const [];

  /// 玩家赛季榜索引
  Map<String, int> _playerRankByName = {};

  /// 无尽榜索引
  Map<String, int> _hellRankByName = {};

  /// 成员「上次在线」展示串索引
  Map<String, String> _lastOnlineByLower = {};

  /// 已尝试查询过「上次在线」的玩家
  final Set<String> _lastOnlineAttempted = {};

  /// 分数列宽（像素）
  double _scoreColumnWidth = 0;

  /// "上次在线"时间列宽
  double _timeColumnWidth = 0;

  /// 分数列测量/展示样式
  static const TextStyle _scoreStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
  );

  /// "上次在线"时间列测量/展示样式
  static const TextStyle _timeStyle = TextStyle(fontSize: 12.0);

  /// 测量单行文本宽度
  double _textWidth(String text, TextStyle style) {
    return (TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout()).width.ceilToDouble();
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      reloadForCurrentUser();
    });
    _load();
  }

  /// 切换用户
  void reloadForCurrentUser() {
    setState(() {
      _members = const [];
      _selectedMember = null;
    });
    _load();
  }

  /// 加载公会数据
  Future<void> _load({bool force = false}) async {
    final String rawGuild =
        widget.guildName ?? ref.read(currentUserGuildProvider);
    final guild = rawGuild.trim();
    final hasContent = _members.isNotEmpty;
    setState(() {
      _loading = true;
      _firstLoading = !hasContent;
      _error = null;
      _emptyGuild = false;
    });
    if (guild.isEmpty) {
      setState(() {
        _loading = false;
        _firstLoading = false;
        if (!hasContent) {
          _emptyGuild = true;
          _emptyGuildIsDefaultUser = ref.read(currentUserIdProvider) == 0;
        }
      });
      return;
    }

    final (detail, guilds, players, hell) = await (
      RankingCache.guildDetail(guild, force: hasContent || force),
      RankingCache.guildRanking(force: force),
      RankingCache.playerRanking(force: force),
      RankingCache.hellRanking(force: force),
    ).wait;

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    String? refreshFailure;
    var membersLoaded = false;
    setState(() {
      if (!Stores.appSettingsStore.autoLastOnlineEnabledNotifier.value) {
        _loading = false;
      }
      _firstLoading = false;

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
        members.sort((a, b) => b.score.compareTo(a.score));
        _members = members;
        _error = null;
        final lastOnlineEnabled =
            Stores.appSettingsStore.autoLastOnlineEnabledNotifier.value;
        _scoreColumnWidth = members.fold<double>(0, (max, m) {
          final w = _textWidth('9,999,999', _scoreStyle);
          return w > max ? w : max;
        });
        _timeColumnWidth = lastOnlineEnabled
            ? ['999min', '1000d']
                  .map((text) => _textWidth(text, _timeStyle))
                  .reduce((max, width) => width > max ? width : max)
            : 0;
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
          refreshFailure = _errorMessage(l10n, guild, detail);
        } else {
          _error = _errorMessage(l10n, guild, detail);
        }
      }

      _guildRank = null;
      _guildGapPrev = null;
      _guildGapNext = null;
      if (guilds is SeasonQueryResult<GuildInfo>) {
        final items = guilds.items;
        for (var i = 0; i < items.length; i++) {
          final g = items[i];
          if (g.name.toLowerCase() == guild.toLowerCase()) {
            _guildRank = g.rank;
            // 上一名
            if (i > 0) _guildGapPrev = items[i - 1].score - g.score;
            // 下一名
            if (i < items.length - 1) {
              _guildGapNext = g.score - items[i + 1].score;
            }
            break;
          }
        }
      }
    });

    // 本地副本
    final failure = refreshFailure;
    if (failure != null) {
      final text = l10n.snackRefreshFailed(failure);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }

    // 成员列表加载成功且开关开启才发起各成员"上次在线"查询
    final loadLastOnline =
        membersLoaded &&
        Stores.appSettingsStore.autoLastOnlineEnabledNotifier.value;
    if (loadLastOnline) {
      await Future.wait([
        for (final m in _members)
          if (force || _lastOnlineAttempted.add(m.name.toLowerCase()))
            LastOnlineCache.fetch(m.name, force: force).then<void>((value) {
              if (!mounted || value == null) return;
              final key = m.name.toLowerCase();
              final valueWidth = _textWidth(value, _timeStyle);
              setState(() {
                _lastOnlineByLower[key] = value;
                if (valueWidth > _timeColumnWidth) {
                  _timeColumnWidth = valueWidth;
                }
              });
            }, onError: (_, _) {}),
      ]);
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// 下拉刷新
  Future<void> _refresh() async {
    final String rawGuild =
        widget.guildName ?? ref.read(currentUserGuildProvider);
    final guild = rawGuild.trim();
    final result = await ref.read(usersProvider.notifier).syncCurrentUser();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (result is QueryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.snackSyncFailed(_errorMessage(l10n, guild, result)),
          ),
        ),
      );
    }
    // 强制刷新公会成员与三榜单
    await _load(force: true);
  }

  String _errorMessage(AppLocalizations l10n, String guild, QueryError error) {
    return switch (error) {
      NameNotFound() => l10n.errorGuildNotFound(guild),
      TimeoutError() => l10n.errorQueryTimeout,
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget body;
    if (_firstLoading) {
      body = const Center(child: CircularProgressIndicator());
      // 公会未配置
    } else if (_error != null || _emptyGuild) {
      body = _buildError();
    } else if (_members.isEmpty) {
      body = Center(child: Text(l10n.emptyGuildMembers));
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          _lastBodyWidth = constraints.maxWidth;
          final wide = _lastBodyWidth >= Breakpoints.masterDetailMinWidth;
          final list = _buildMemberList(wide: wide);
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
    // 作为公会榜详情页嵌入外层 Scaffold 时，不带用户页外壳
    if (!widget.userHeader) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.tabGuild), _AppBarInfo()],
        ),
        bottom: LoadingIndicatorAppBar(bottom: null, isLoading: _loading),
        actions: [
          isDesktop
              ? IconButton(
                  onPressed: _refresh,
                  tooltip: l10n.tooltipFetchData,
                  icon: !_loading
                      ? Icon(Icons.cloud_sync)
                      : SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                )
              : SizedBox.shrink(),
          SeasonIndicator(notifier: RankingCache.guildSeasonNotifier),
        ],
      ),
      body: body,
    );
  }

  /// 查询失败提示 + 操作按钮，公会未配置时跳转用户管理，网络类错误重试
  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final message = _emptyGuild
        ? (_emptyGuildIsDefaultUser
              ? l10n.emptyGuildDefaultUserHint
              : l10n.emptyGuildHint)
        : _error!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36.0, color: scheme.error),
            const SizedBox(height: 12.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16.0),
            // 公会未配置
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
                label: Text(l10n.actionGoToUserManagement),
              )
            else
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
          ],
        ),
      ),
    );
  }

  /// 主从两栏下选中的成员名
  String? _selectedMember;

  /// 最近一次布局的 body 可用宽度（LayoutBuilder 回填，供点击回调判断两栏）
  double _lastBodyWidth = 0;

  /// 打开成员详情：宽屏选中并在右侧面板展示，窄屏 push 全屏
  void _openMember(GuildMember member) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_lastBodyWidth >= Breakpoints.masterDetailMinWidth) {
      setState(() => _selectedMember = member.name);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerDetailPage(playerName: member.name),
      ),
    );
  }

  /// 右侧详情面板：未选中时占位提示，选中后嵌入玩家详情
  Widget _buildDetailPane() {
    final name = _selectedMember;
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
                AppLocalizations.of(context).emptySelectMemberHint,
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
      onClose: () => setState(() => _selectedMember = null),
    );
  }

  /// 成员列表，按赛季波数从大到小展示，当前用户高亮；
  Widget _buildMemberList({required bool wide}) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currentUser = ref.read(currentUsernameProvider);
    final totalScore = _members.fold<int>(0, (sum, m) => sum + m.score);
    const chipTextStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
    );
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
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 24.0, 8.0),
          child: Row(
            children: [
              // 公会榜排名，前后为与上一名/下一名的分数差距
              for (var i = 0; i < chips.length; i++) ...[
                chips[i].$1,
                if (i < chips.length - 1) SizedBox(width: chips[i + 1].$2),
              ],
              const Spacer(),
              Text(
                l10n.guildMemberCountAndScore(
                  _members.length,
                  totalScore.format(),
                ),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.primary),
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
                  selected: wide && member.name == _selectedMember,
                  // 点击成员进入玩家详情页，宽屏下改为右侧面板展示
                  onTap: () => _openMember(member),
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
                      // 个人赛季榜 / 无尽榜排名胶囊
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
                      SizedBox(
                        width: _timeColumnWidth,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: (lastOnline == null || lastOnline.isEmpty)
                                ? const SizedBox(width: 0)
                                : Text(
                                    lastOnline,
                                    key: ValueKey(lastOnline),
                                    style: _timeStyle.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
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

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = <Widget>[
      CurrentUser(),
      LastOnline(),
      CurrentUserGuild(),
    ];
    return AppBarInfo(children: segments);
  }
}
