import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/last_online_cache.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_hell_mode_rank.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_rank.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/icon/crystal.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/guild/guild_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/date.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/animated_widget/animated_text_switcher.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/history_date_actions.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/season_indicator.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/rank_board_card.dart';
import 'package:material_ui/material_ui.dart';

/// 公会页
class GuildPage extends ConsumerStatefulWidget {
  const GuildPage({
    super.key,
    this.guildName,
    this.userHeader = true,
    this.initialDate,
  });

  final String? guildName;
  final bool userHeader;

  /// 初始历史日期；null 表示当前赛季
  final DateTime? initialDate;

  @override
  ConsumerState<GuildPage> createState() => _GuildPageState();
}

/// 公会成员详情页
class GuildDetailPage extends StatefulWidget {
  const GuildDetailPage({super.key, required this.guildName, this.initialDate});

  final String guildName;

  /// 初始历史日期；null 表示当前赛季
  final DateTime? initialDate;

  @override
  State<GuildDetailPage> createState() => _GuildDetailPageState();
}

class _GuildDetailPageState extends State<GuildDetailPage> {
  late DateTime? _date = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final date = _date;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.guildName),
            if (date != null)
              Text(
                formatHistoryDate(date),
                style: const TextStyle(fontSize: 12.0),
              ),
          ],
        ),
        actions: [
          HistoryDateActions(
            date: date,
            onChanged: (value) => setState(() => _date = value),
          ),
        ],
      ),
      body: GuildPage(
        key: ValueKey(date),
        guildName: widget.guildName,
        userHeader: false,
        initialDate: date,
      ),
    );
  }
}

class _GuildPageState extends ConsumerState<GuildPage>
    with TickerProviderStateMixin {
  late final AnimationController _cardController;
  late final CurvedAnimation _cardAnimation;
  bool _showCard = true;

  bool _firstLoading = true;
  bool _loading = true;
  String? _error;

  bool _emptyGuild = false;
  bool _emptyGuildIsDefaultUser = false;

  int? _guildRank;
  int? _guildGapPrev;
  String? _guildPrevName;
  int? _guildGapNext;
  String? _guildNextName;
  List<GuildMember> _members = const [];

  /// 历史模式所选日期；null 表示当前赛季
  DateTime? _historyDate;

  /// 历史数据返回的赛季
  final ValueNotifier<SeasonRange?> _historySeasonNotifier =
      ValueNotifier<SeasonRange?>(null);

  /// 丢弃过期请求的结果（快速切换日期时）
  int _loadToken = 0;

  Map<String, int> _playerRankByName = {};
  Map<String, int> _hellRankByName = {};
  Map<String, String> _lastOnlineByLower = {};
  final Set<String> _lastOnlineAttempted = {};

  double _scoreColumnWidth = 0;
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
    _historyDate = widget.initialDate;
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOutCubic,
    );
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      reloadForCurrentUser();
    });
    _load();
  }

  /// 手势滑动
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          _setCardVisible(false);
        case ScrollDirection.forward:
          _setCardVisible(true);
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  /// 鼠标滚轮/触控板滚动
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && event.scrollDelta.dy != 0.0) {
      _setCardVisible(event.scrollDelta.dy < 0.0);
    }
  }

  void _setCardVisible(bool visible) {
    if (_showCard == visible) return;
    setState(() => _showCard = visible);
    if (visible) {
      _cardController.forward();
    } else {
      _cardController.reverse();
    }
  }

  @override
  void dispose() {
    _historySeasonNotifier.dispose();
    _cardController.dispose();
    _cardAnimation.dispose();
    super.dispose();
  }

  /// 切换历史日期（null 回到当前赛季）
  void _onHistoryChanged(DateTime? date) {
    setState(() {
      _historyDate = date;
      _members = const [];
      _selectedMember = null;
      _playerRankByName = {};
      _hellRankByName = {};
      _guildRank = null;
      _guildGapPrev = null;
      _guildPrevName = null;
      _guildGapNext = null;
      _guildNextName = null;
      _historySeasonNotifier.value = null;
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
    final date = _historyDate;
    final token = ++_loadToken;
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
      date == null
          ? RankingCache.guildDetail(guild, force: hasContent || force)
          : RankingCache.guildDetailAt(guild, date, force: force),
      date == null
          ? RankingCache.guildRanking(force: force)
          : RankingCache.guildRankingAt(date, force: force),
      date == null
          ? RankingCache.playerRanking(force: force)
          : RankingCache.playerRankingAt(date, force: force),
      date == null
          ? RankingCache.hellRanking(force: force)
          : RankingCache.hellRankingAt(date, force: force),
    ).wait;

    if (!mounted || token != _loadToken) return;
    final l10n = AppLocalizations.of(context);
    // 历史模式没有"上次在线"
    final lastOnlineEnabled =
        date == null &&
        Stores.appSettingsStore.autoLastOnlineEnabledNotifier.value;

    String? refreshFailure;
    var membersLoaded = false;
    setState(() {
      if (!lastOnlineEnabled) {
        _loading = false;
      }
      _firstLoading = false;

      _playerRankByName = {};
      if (players is SeasonQueryResult<RankInfo>) {
        for (final p in players.items) {
          _playerRankByName[p.name.toLowerCase()] = p.rank;
        }
      }
      _hellRankByName = {};
      if (hell is SeasonQueryResult<RankInfo>) {
        for (final h in hell.items) {
          _hellRankByName[h.name.toLowerCase()] = h.rank;
        }
      }

      if (detail is SeasonQueryResult<GuildMember>) {
        final members = List<GuildMember>.from(detail.items);
        members.sort((a, b) => b.score.compareTo(a.score));
        _members = members;
        _error = null;
        if (date != null) {
          _historySeasonNotifier.value = detail.season;
        }
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
      if (guilds is SeasonQueryResult<RankInfo>) {
        for (final g in guilds.items) {
          if (g.name.toLowerCase() == guild.toLowerCase()) {
            _guildRank = g.rank;
            // 上一名/下一名分差（解析榜单时已算好）
            _guildGapPrev = g.gapPrev;
            _guildPrevName = g.prevName;
            _guildGapNext = g.gapNext;
            _guildNextName = g.nextName;
            break;
          }
        }
      }
    });

    // 历史数据不写入当前用户的总分统计
    if (membersLoaded && widget.guildName == null && date == null) {
      ref.read(guildTotalScoreProvider.notifier).publishFromMembers(_members);
    }

    // 本地副本
    final failure = refreshFailure;
    if (failure != null) {
      final text = l10n.snackRefreshFailed(failure);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }

    // 成员列表加载成功且开关开启才发起各成员"上次在线"查询
    final loadLastOnline = membersLoaded && lastOnlineEnabled;
    if (loadLastOnline) {
      await Future.wait([
        for (final m in _members)
          if (force || _lastOnlineAttempted.add(m.name.toLowerCase()))
            LastOnlineCache.fetch(m.name, force: force).then<void>((value) {
              if (!mounted || token != _loadToken || value == null) return;
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
    if (mounted && token == _loadToken) {
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
    // 历史模式只刷新历史数据，不同步当前用户
    if (_historyDate == null) {
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
    final date = _historyDate;

    final appBarInfo = AppBarInfo(
      children: <Widget>[
        AppBarItem.currentUser(),
        AppBarItem.currentUserGuild(),
        if (date != null)
          Text(formatHistoryDate(date), style: const TextStyle(fontSize: 12.0)),
        SeasonIndicator(
          notifier: date == null
              ? RankingCache.guildSeasonNotifier
              : _historySeasonNotifier,
        ),
      ],
    );

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
          final wide = constraints.maxWidth >= Breakpoints.sideBySide;
          final list = _buildMemberList(wide: wide);
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
    // 作为公会榜详情页嵌入外层 Scaffold 时，不带用户页外壳
    if (!widget.userHeader) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.tabGuild), appBarInfo],
        ),
        actions: [
          if (isDesktop)
            IconButton(
              onPressed: _refresh,
              tooltip: l10n.tooltipFetchData,
              icon: !_loading
                  ? Icon(Icons.cloud_sync)
                  : SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
            ),
          HistoryDateActions(date: date, onChanged: _onHistoryChanged),
        ],
      ),
      body: SafeArea(top: false, child: body),
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

  void _openMember(GuildMember member) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.isWideContent) {
      setState(() => _selectedMember = member.name);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerDetailPage(playerName: member.name),
      ),
    );
  }

  /// 右侧详情面板
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

  /// 成员列表，按赛季波数从大到小展示，当前用户高亮
  Widget _buildMemberList({required bool wide}) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currentUser = ref.read(currentUsernameProvider);
    final totalScore = _members.fold<int>(0, (sum, m) => sum + m.score);
    final String guild = widget.guildName ?? ref.read(currentUserGuildProvider);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: NotificationListener<UserScrollNotification>(
          onNotification: _onScrollNotification,
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: UIs.padding,
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final lowerName = member.name.toLowerCase();
                    final isSelf = lowerName == currentUser.toLowerCase();
                    final seasonRank = _playerRankByName[lowerName];
                    final hellRank = _hellRankByName[lowerName];
                    final reward =
                        getRedCrystalFromPlayerRank(seasonRank ?? 0) +
                        getRedCrystalFromHellModeRank(hellRank ?? 0);
                    final lastOnline = _lastOnlineByLower[lowerName];
                    return CardTile(
                      selected: wide && member.name == _selectedMember,
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
                      title: Wrap(
                        spacing: 4.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontWeight: isSelf ? FontWeight.bold : null,
                              color: isSelf ? scheme.primary : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (reward != 0)
                            PillChip(
                              text: '$reward',
                              leading: CrystalIcon(
                                size: 12.0,
                                color: scheme.primary,
                              ),
                            ),
                          if (seasonRank != null)
                            PillChip(
                              text: '#$seasonRank',
                              leading: Icon(Icons.eco),
                            ),
                          if (hellRank != null)
                            PillChip(
                              text: '#$hellRank',
                              leading: Icon(Icons.all_inclusive),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: _timeColumnWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: AnimatedTextSwitcher(
                                alignment: .centerRight,
                                child:
                                    (lastOnline == null || lastOnline.isEmpty)
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
                            child: AnimatedTextSwitcher(
                              alignment: .centerRight,
                              child: Text(
                                member.score.format(),
                                key: ValueKey(member.score),
                                textAlign: TextAlign.right,
                                style: _scoreStyle.copyWith(
                                  color: isSelf ? scheme.primary : null,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                      child: RankBoardCard(
                        icon: Icons.flag_circle,
                        title: l10n.guildTotalScore,
                        previous: _guildRank != null && _guildGapPrev != null
                            ? RankBoardRow(
                                rank: _guildRank! - 1,
                                name: _guildPrevName ?? '',
                                gapText: '+${_guildGapPrev!.format()}',
                                gapColor: Colors.red,
                              )
                            : null,
                        current: RankBoardRow(
                          rank: _guildRank,
                          name: guild,
                          value: totalScore.format(),
                          highlight: true,
                        ),
                        next: _guildRank != null && _guildGapNext != null
                            ? RankBoardRow(
                                rank: _guildRank! + 1,
                                name: _guildNextName ?? '',
                                gapText: '-${_guildGapNext!.format()}',
                                gapColor: Colors.green,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
