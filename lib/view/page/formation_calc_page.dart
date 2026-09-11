import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user_guild.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/last_online.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_listtile.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_summary_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/loading_indicator_app_bar.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容经济计算页
class FormationCalcPage extends StatefulWidget {
  const FormationCalcPage({super.key});

  @override
  State<FormationCalcPage> createState() => _FormationCalcPageState();
}

class _FormationCalcPageState extends State<FormationCalcPage> {
  /// 本次会话中已自动查询过的用户名。
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
  final ValueNotifier<int> _formationDataVersion = ValueNotifier(0);
  static bool _viewMode = false;

  FocusNode _focusNodeFor(int id, Map<int, FocusNode> cache) {
    return cache.putIfAbsent(id, () => FocusNode());
  }

  TextEditingController _numberControllerFor(int id) {
    return _numberControllers.putIfAbsent(id, () {
      final c = TextEditingController(
        text: Stores.infoStore.getNumberValue(id),
      );
      c.addListener(() {
        Stores.infoStore.setNumberValue(id, c.text);
        _formationDataVersion.value++;
      });
      return c;
    });
  }

  TextEditingController _textControllerFor(int id) {
    return _textControllers.putIfAbsent(id, () {
      final c = TextEditingController(text: Stores.infoStore.getTextValue(id));
      c.addListener(() {
        Stores.infoStore.setTextValue(id, c.text);
        _formationDataVersion.value++;
      });
      return c;
    });
  }

  @override
  void dispose() {
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
    _formationDataVersion.dispose();
    super.dispose();
  }

  void _removeCard(int id) {
    _numberFocusNodes.remove(id)?.dispose();
    _textFocusNodes.remove(id)?.dispose();
    _numberControllers.remove(id)?.dispose();
    _textControllers.remove(id)?.dispose();
    Stores.infoStore.removeCard(id);
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

  @override
  void initState() {
    super.initState();
    if (Stores.infoStore.getCurrentUserId() != 0) {
      final cache = _rankCache;
      final username = Stores.infoStore.getCurrentUsername();
      if (cache != null && cache.$1 == Stores.infoStore.getCurrentUserId()) {
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

  /// 一次性获取当前用户所需的三类排名（个人赛季 / 无尽 / 所属公会），
  /// 大小写不敏感匹配；TTL 缓存命中零请求，未命中/过期则在此并行抓取；
  /// [force] 为 true（手动同步）时忽略缓存强制重新抓取，失败保留旧缓存。
  /// 挂载时调用用于恢复页面重建后丢失的胶囊；查询成功后调用刷新为最新数据。
  Future<void> _loadRanks({bool force = false}) async {
    final userId = Stores.infoStore.getCurrentUserId();
    final currentUser = Stores.infoStore.getCurrentUsername();
    final lower = currentUser.toLowerCase();
    final guild = Stores.infoStore.getCurrentUserGuild();
    final guildLower = guild.toLowerCase();
    setState(() => _loadingRanks = true);
    final (players, hell, guilds) = await (
      RankingCache.playerRanking(force: force),
      RankingCache.hellRanking(force: force),
      guild.isEmpty
          ? Future<Object?>.value(null)
          : RankingCache.guildRanking(force: force),
    ).wait;
    // 顺带预热当前用户所属公会的成员列表（成功后缓存，无 TTL、手动刷新才
    // 更新）：抽屉「公会」页首次进入直接命中缓存，避免成员首拉的转圈等待；
    // 不 await，不影响胶囊更新的时机。
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

  /// 在个人赛季榜中定位玩家：返回（排名, 与上一名分数差, 与下一名分数差）；
  /// 不在榜内时三项均为 null
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

  /// 联网查询当前用户的波数与赛季波数，成功写入 store，失败弹 SnackBar。
  /// 冷却检查仅对用户手动点击生效；启动自动查询走 [_performQuery] 不经过这里。
  Future<void> _queryOnline() async {
    final now = DateTime.now();
    final last = _lastQueryAt;
    if (last != null && now.difference(last) < _queryCooldown) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('查询过于频繁，请稍后后再试')));
      return;
    }
    // 先记录时间再发起请求：查询进行中也同样受冷却保护
    _lastQueryAt = now;
    await _performQuery();
  }

  /// 执行查询并写入 store。
  ///
  /// [silent] 为 true 时（启动自动查询）不弹任何 SnackBar，失败静默忽略，
  /// 界面由 store 的 notifier 自动更新；手动路径的冷却与提示由 [_queryOnline] 负责。
  Future<void> _performQuery({bool silent = false}) async {
    setState(() => _querying = true);

    final name = Stores.infoStore.getCurrentUsername();
    final result = await Stores.infoStore.syncCurrentUser();

    if (!mounted) return;

    if (result is PlayerQueryResult) {
      if (result.wave == 0 && result.queryDate.isEmpty) {
        if (!silent) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('用户「$name」已被封禁')));
        }
        return;
      }
      await _loadRanks(force: !silent);
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '数据获取成功：用户「$name」, 波数 ${result.wave.format()}, 赛季波数 ${result.seasonalScore.format()}',
            ),
          ),
        );
      }
    } else if (result is QueryError) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('查询失败：${_queryErrorMessage(name, result)}')),
        );
      }
    }
    setState(() => _querying = false);
  }

  String _queryErrorMessage(String name, QueryError error) {
    return switch (error) {
      NameNotFound() => '未找到「$name」的赛季数据',
      TimeoutError() => '查询超时，请稍后重试',
      NetworkError(:final message) => message,
    };
  }

  // @override
  // Widget build(BuildContext context) {
  //   return UserPageScaffold(
  //     title: '阵容',
  //     isLoading: _querying || _loadingRanks,
  //     appBarActions: [
  //       IconButton(
  //         icon: Icon(_viewMode ? Icons.edit : Icons.visibility),
  //         tooltip: _viewMode ? '输入模式' : '查看模式',
  //         onPressed: () {
  //           FocusManager.instance.primaryFocus?.unfocus();
  //           setState(() => _viewMode = !_viewMode);
  //         },
  //       ),
  //       IconButton(
  //         icon: const Icon(Icons.add),
  //         tooltip: '新增条目',
  //         onPressed: () => Stores.infoStore.addNewCard(),
  //       ),
  //     ],
  //     body: Column(
  //       children: [
  //         Expanded(
  //           child: ValueListenableBuilder<int>(
  //             valueListenable: Stores.infoStore.cardIdsNotifier,
  //             builder: (context, _, _) {
  //               final cardIds = Stores.infoStore.getCardIds();
  //               if (cardIds.isEmpty) {
  //                 return const Center(
  //                   child: Text(
  //                     '暂无条目，点击右上角 + 添加',
  //                     style: TextStyle(color: Colors.grey),
  //                   ),
  //                 );
  //               }
  //               return ReorderableListView.builder(
  //                 // 矮窗口兜底切换子树结构时，靠它把滚动位置存回 PageStorage
  //                 key: const PageStorageKey('formation_card_list'),
  //                 itemCount: cardIds.length,
  //                 proxyDecorator: (child, index, animation) {
  //                   return AnimatedBuilder(
  //                     animation: animation,
  //                     builder: (context, child) {
  //                       final double elevation = 4.0 * animation.value;
  //                       return Material(
  //                         elevation: elevation,
  //                         shadowColor: Colors.black26,
  //                         borderRadius: BorderRadius.circular(8.0),
  //                         child: IgnorePointer(child: child),
  //                       );
  //                     },
  //                     child: child,
  //                   );
  //                 },
  //                 onReorderItem: (oldIndex, newIndex) {
  //                   FocusManager.instance.primaryFocus?.unfocus();
  //                   Stores.infoStore.reorderCard(oldIndex, newIndex);
  //                 },
  //                 itemBuilder: (context, index) {
  //                   final id = cardIds[index];
  //                   return FormationCardTile(
  //                     key: ValueKey(id),
  //                     id: id,
  //                     index: index,
  //                     textController: _textControllerFor(id),
  //                     numberController: _numberControllerFor(id),
  //                     textFocusNode: _focusNodeFor(id, _textFocusNodes),
  //                     numberFocusNode: _focusNodeFor(id, _numberFocusNodes),
  //                     viewMode: _viewMode,
  //                     dataVersion: _formationDataVersion,
  //                     onRemove: _removeCard,
  //                   );
  //                 },
  //                 buildDefaultDragHandles: false,
  //                 scrollDirection: .vertical,
  //               );
  //             },
  //           ),
  //         ),
  //         FormationSummaryBar(
  //           querying: _querying,
  //           playerRank: _playerRank,
  //           playerGapPrev: _playerGapPrev,
  //           playerGapNext: _playerGapNext,
  //           hellRank: _hellRank,
  //           guildRank: _guildRank,
  //           onQuery: _queryOnline,
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Stores.infoStore.currentUserNotifier,
        Stores.infoStore.dataVersionNotifier,
      ]),
      builder: (context, _) {
        final isWide = context.isWideScreen;
        List<Widget> actions = <Widget>[
          if (isDesktop && Stores.infoStore.getCurrentUserId() != 0)
            IconButton(
              icon: _querying
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.cloud_sync),
              tooltip: '拉取数据',
              onPressed: _queryOnline,
            ),
          IconButton(
            icon: Icon(_viewMode ? Icons.edit : Icons.visibility),
            tooltip: _viewMode ? '输入模式' : '查看模式',
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _viewMode = !_viewMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增条目',
            onPressed: () => Stores.infoStore.addNewCard(),
          ),
        ];
        Widget formationExpanded = Expanded(
          flex: isWide ? 6 : 1,
          child: ValueListenableBuilder<int>(
            valueListenable: Stores.infoStore.cardIdsNotifier,
            builder: (context, _, _) {
              final cardIds = Stores.infoStore.getCardIds();
              if (cardIds.isEmpty) {
                return const Center(
                  child: Text(
                    '暂无条目，点击右上角 + 添加',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return ReorderableListView.builder(
                // 矮窗口兜底切换子树结构时，靠它把滚动位置存回 PageStorage
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
                  Stores.infoStore.reorderCard(oldIndex, newIndex);
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
                    dataVersion: _formationDataVersion,
                    onRemove: _removeCard,
                  );
                },
                buildDefaultDragHandles: false,
                scrollDirection: .vertical,
              );
            },
          ),
        );
        Widget formationSummaryBar = FormationSummaryBar(
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
              children: [Text('阵容'), _AppBarInfo()],
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
      },
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Stores.infoStore.lastOnlineNotifier,
        Stores.infoStore.guildNotifier,
      ]),
      builder: (context, _) {
        final List<Widget> segments = <Widget>[
          CurrentUser(),
          LastOnline(),
          CurrentUserGuild(),
        ];
        return AppBarInfo(children: segments);
      },
    );
  }
}
