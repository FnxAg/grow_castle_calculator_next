import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user_guild.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/last_online.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_listtile.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_summary_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/loading_indicator_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容经济计算页
class FormationCalcPage extends ConsumerStatefulWidget {
  const FormationCalcPage({super.key});

  @override
  ConsumerState<FormationCalcPage> createState() => _FormationCalcPageState();
}

class _FormationCalcPageState extends ConsumerState<FormationCalcPage> {
  static final Set<String> _autoQueriedUsers = {};

  /// 最近一次查询到的排名快照
  static (
    int userId,
    int? playerRank,
    int? playerGapPrev,
    int? playerGapNext,
    int? hellRank,
    int? guildRank,
  )?
  _rankCache;

  final Map<int, FocusNode> _numberFocusNodes = {};
  final Map<int, FocusNode> _textFocusNodes = {};
  final Map<int, TextEditingController> _numberControllers = {};
  final Map<int, TextEditingController> _textControllers = {};
  static bool _viewMode = false;

  FocusNode _focusNodeFor(int id, Map<int, FocusNode> cache) {
    return cache.putIfAbsent(id, () => FocusNode());
  }

  TextEditingController _numberControllerFor(int id) {
    return _numberControllers.putIfAbsent(id, () {
      final c = TextEditingController(
        text: ref.read(currentUserProvider).numberValues[id] ?? '',
      );
      c.addListener(() => ref.users.setNumberValue(id, c.text));
      return c;
    });
  }

  TextEditingController _textControllerFor(int id) {
    return _textControllers.putIfAbsent(id, () {
      final c = TextEditingController(
        text: ref.read(currentUserProvider).textValues[id] ?? '',
      );
      c.addListener(() => ref.users.setTextValue(id, c.text));
      return c;
    });
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      setState(reloadForCurrentUser);
    });
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _discardCardCaches();
    super.dispose();
  }

  /// 丢弃按卡片 id 缓存的控制器与焦点
  void _discardCardCaches() {
    for (final node in _numberFocusNodes.values) {
      node.dispose();
    }
    for (final node in _textFocusNodes.values) {
      node.dispose();
    }
    for (final c in _numberControllers.values) {
      c.dispose();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _numberFocusNodes.clear();
    _textFocusNodes.clear();
    _numberControllers.clear();
    _textControllers.clear();
  }

  void _removeCard(int id) {
    _numberFocusNodes.remove(id)?.dispose();
    _textFocusNodes.remove(id)?.dispose();
    _numberControllers.remove(id)?.dispose();
    _textControllers.remove(id)?.dispose();
    ref.users.removeCard(id);
  }

  static const Duration _queryCooldown = Duration(seconds: 5);
  DateTime? _lastQueryAt;
  bool _querying = false;
  bool _loadingRanks = false;

  int? _playerRank;
  int? _hellRank;
  int? _guildRank;
  int? _playerGapPrev;
  int? _playerGapNext;

  /// 切换用户：先丢弃上一个用户的缓存，再按新用户重新初始化本页
  void reloadForCurrentUser() {
    _discardCardCaches();
    setState(() {
      // 排名与波数都属于上一个用户，先清空再由 _loadCurrentUser 重新查
      _playerRank = null;
      _playerGapPrev = null;
      _playerGapNext = null;
      _hellRank = null;
      _guildRank = null;
      _lastQueryAt = null;
    });
    _loadCurrentUser();
  }

  /// 按当前用户初始化页面状态，挂载时、以及切换用户后调用
  void _loadCurrentUser() {
    final userId = ref.read(currentUserIdProvider);
    if (userId != 0) {
      final cache = _rankCache;
      final username = ref.read(currentUsernameProvider);
      if (cache != null && cache.$1 == userId) {
        _playerRank = cache.$2;
        _playerGapPrev = cache.$3;
        _playerGapNext = cache.$4;
        _hellRank = cache.$5;
        _guildRank = cache.$6;
      }
      // 从榜单 TTL 缓存重新推导排名
      _loadRanks();
      // 应用启动时静默查询当前用户波数
      if (_autoQueriedUsers.add(username)) {
        _performQuery(silent: true);
      }
    }
  }

  /// 获取排名
  Future<void> _loadRanks({bool force = false}) async {
    final userId = ref.read(currentUserIdProvider);
    final currentUser = ref.read(currentUsernameProvider);
    final lower = currentUser.toLowerCase();
    final guild = ref.read(currentUserProvider).guild;
    final guildLower = guild.toLowerCase();
    setState(() => _loadingRanks = true);
    final (players, hell, guilds) = await (
      RankingCache.playerRanking(force: force),
      RankingCache.hellRanking(force: force),
      guild.isEmpty
          ? Future<Object?>.value(null)
          : RankingCache.guildRanking(force: force),
    ).wait;
    if (guild.isNotEmpty) {
      RankingCache.guildDetail(guild, force: force);
    }
    if (!mounted) return;
    setState(() {
      _loadingRanks = false;
      _playerRank = null;
      _playerGapPrev = null;
      _playerGapNext = null;
      if (players is SeasonQueryResult<PlayerRankInfo>) {
        final found = _locatePlayer(players.items, lower);
        _playerRank = found.rank;
        _playerGapPrev = found.gapPrev;
        _playerGapNext = found.gapNext;
      }
      _hellRank = null;
      if (hell is SeasonQueryResult<HellRankInfo>) {
        for (final h in hell.items) {
          if (h.name.toLowerCase() == lower) {
            _hellRank = h.rank;
            break;
          }
        }
      }
      _guildRank = null;
      if (guilds is SeasonQueryResult<GuildInfo>) {
        for (final g in guilds.items) {
          if (g.name.toLowerCase() == guildLower) {
            _guildRank = g.rank;
            break;
          }
        }
      }
      _rankCache = (
        userId,
        _playerRank,
        _playerGapPrev,
        _playerGapNext,
        _hellRank,
        _guildRank,
      );
    });
  }

  /// 在个人赛季榜中定位玩家
  ({int? rank, int? gapPrev, int? gapNext}) _locatePlayer(
    List<PlayerRankInfo> items,
    String lowerName,
  ) {
    for (var i = 0; i < items.length; i++) {
      final p = items[i];
      if (p.name.toLowerCase() == lowerName) {
        return (
          rank: p.rank,
          // 上一名差值
          gapPrev: i > 0 ? items[i - 1].score - p.score : null,
          // 下一名差值
          gapNext: i < items.length - 1 ? p.score - items[i + 1].score : null,
        );
      }
    }
    return (rank: null, gapPrev: null, gapNext: null);
  }

  /// 联网查询
  Future<void> _queryOnline() async {
    final now = DateTime.now();
    final last = _lastQueryAt;
    if (last != null && now.difference(last) < _queryCooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).snackQueryTooFrequent),
        ),
      );
      return;
    }
    // 先记录时间再发起请求
    _lastQueryAt = now;
    await _performQuery();
  }

  /// 执行查询
  Future<void> _performQuery({bool silent = false}) async {
    setState(() => _querying = true);

    final name = ref.read(currentUsernameProvider);
    final result = await ref.read(usersProvider.notifier).syncCurrentUser();

    if (!mounted) return;

    if (result is PlayerQueryResult) {
      if (result.wave == 0 && result.queryDate.isEmpty) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).snackUserBanned(name)),
            ),
          );
        }
        return;
      }
      await _loadRanks(force: !silent);
      if (!mounted) return;
      if (!silent) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.snackQuerySuccess(
                name,
                result.wave.format(),
                result.seasonalScore.format(),
              ),
            ),
          ),
        );
      }
    } else if (result is QueryError) {
      if (!silent) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.snackQueryFailed(_queryErrorMessage(l10n, name, result)),
            ),
          ),
        );
      }
    }
    setState(() => _querying = false);
  }

  String _queryErrorMessage(
    AppLocalizations l10n,
    String name,
    QueryError error,
  ) {
    return switch (error) {
      NameNotFound() => l10n.errorSeasonDataNotFound(name),
      TimeoutError() => l10n.errorQueryTimeout,
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWideScreen;
    final l10n = AppLocalizations.of(context);
    final cardIds = ref.watch(currentUserCardIdsProvider);
    final List<Widget> actions = <Widget>[
      if (isDesktop && ref.watch(currentUserIdProvider) != 0)
        IconButton(
          icon: _querying
              ? const SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Icon(Icons.cloud_sync),
          tooltip: l10n.tooltipFetchData,
          onPressed: _queryOnline,
        ),
      IconButton(
        icon: Icon(_viewMode ? Icons.edit : Icons.visibility),
        tooltip: _viewMode ? l10n.tooltipInputMode : l10n.tooltipViewMode,
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _viewMode = !_viewMode);
        },
      ),
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: l10n.tooltipAddEntry,
        onPressed: () => ref.users.addNewCard(),
      ),
    ];
    final Widget formationExpanded = Expanded(
      flex: isWide ? 6 : 1,
      child: cardIds.isEmpty
          ? Center(
              child: Text(
                l10n.emptyFormationHint,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ReorderableListView.builder(
              key: const PageStorageKey('formation_card_list'),
              itemCount: cardIds.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final double elevation = 4.0 * animation.value;
                    return Material(
                      elevation: elevation,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(8.0),
                      child: IgnorePointer(child: child),
                    );
                  },
                  child: child,
                );
              },
              onReorderItem: (oldIndex, newIndex) {
                FocusManager.instance.primaryFocus?.unfocus();
                ref.users.reorderCard(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final id = cardIds[index];
                return FormationCardTile(
                  key: ValueKey(id),
                  id: id,
                  index: index,
                  textController: _textControllerFor(id),
                  numberController: _numberControllerFor(id),
                  textFocusNode: _focusNodeFor(id, _textFocusNodes),
                  numberFocusNode: _focusNodeFor(id, _numberFocusNodes),
                  viewMode: _viewMode,
                  onRemove: _removeCard,
                );
              },
              buildDefaultDragHandles: false,
              scrollDirection: .vertical,
            ),
    );
    final Widget formationSummaryBar = FormationSummaryBar(
      querying: _querying,
      playerRank: _playerRank,
      playerGapPrev: _playerGapPrev,
      playerGapNext: _playerGapNext,
      hellRank: _hellRank,
      guildRank: _guildRank,
      onQuery: _queryOnline,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.tabFormation), _AppBarInfo()],
        ),
        bottom: LoadingIndicatorAppBar(
          bottom: null,
          isLoading: _querying || _loadingRanks,
        ),
        actions: actions,
      ),
      body: isWide
          ? Row(
              children: [
                formationExpanded,
                Expanded(flex: 4, child: formationSummaryBar),
              ],
            )
          : Column(children: [formationExpanded, formationSummaryBar]),
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
