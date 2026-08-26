import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_card_tile.dart';
import 'package:grow_castle_calculator_next/view/widget/formation_summary_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 阵容经济计算页：卡片列表（名称/等级输入）与底部汇总条。
///
/// 作为首页 tab 自带 UserPageScaffold 外壳；输入框控制器与焦点按卡片 id 缓存在
/// State 中，切换用户时 UserPageScaffold 通过更换 key 重建本页，控制器随之释放。
class FormationCalcPage extends StatefulWidget {
  const FormationCalcPage({super.key});

  @override
  State<FormationCalcPage> createState() => _FormationCalcPageState();
}

class _FormationCalcPageState extends State<FormationCalcPage> {
  /// 本次会话中已自动查询过的用户名。
  ///
  /// 页面会被销毁重建（底部 tab 切换），initState 随之重跑；
  /// 用会话级标记保证同一用户每次会话只自动查询一次，避免往返导航
  /// 反复请求。切换用户（KeyedSubtree 换 key 重建）时新用户名不在集合中，
  /// 仍会为新用户触发自动查询。
  static final Set<String> _autoQueriedUsers = {};

  /// 最近一次查询到的排名快照（会话级，按用户 id 缓存——用户名可重命名，
  /// 不能作为身份标识）。
  ///
  /// 页面销毁重建（底部 tab 切换）后 initState 同步恢复，保证重建后首帧
  /// 即有排名——否则先空白、排名异步到达后再出现，会重新触发排名行的
  /// 入场动画（AnimatedSize 高度展开 + 淡入上移）。
  static (int userId, int? playerRank, int? playerGapPrev,
      int? playerGapNext, int? hellRank, int? guildRank)? _rankCache;

  final Map<int, FocusNode> _numberFocusNodes = {};
  final Map<int, FocusNode> _textFocusNodes = {};
  final Map<int, TextEditingController> _numberControllers = {};
  final Map<int, TextEditingController> _textControllers = {};

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
      });
      return c;
    });
  }

  TextEditingController _textControllerFor(int id) {
    return _textControllers.putIfAbsent(id, () {
      final c = TextEditingController(text: Stores.infoStore.getTextValue(id));
      c.addListener(() {
        Stores.infoStore.setTextValue(id, c.text);
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
    super.dispose();
  }

  void _removeCard(int id) {
    _numberFocusNodes.remove(id)?.dispose();
    _textFocusNodes.remove(id)?.dispose();
    _numberControllers.remove(id)?.dispose();
    _textControllers.remove(id)?.dispose();
    // 列表重建由 store 的 cardIdsNotifier 驱动
    Stores.infoStore.removeCard(id);
  }

  /// 5 秒冷却，避免用户连续点击联网查询按钮导致多次请求
  static const Duration _queryCooldown = Duration(seconds: 5);
  DateTime? _lastQueryAt;
  bool _querying = false;

  /// 玩家赛季榜排名（前 300 内才显示，不在榜单则隐藏）
  int? _playerRank;

  /// 无尽榜排名（前 300 内才显示，不在榜单则隐藏）
  int? _hellRank;

  /// 当前用户所属公会在公会榜上的排名（前 300 内才显示）
  int? _guildRank;

  /// 个人赛季榜中与上一名/下一名的分数差距；首名/末名时对应侧为 null
  int? _playerGapPrev;
  int? _playerGapNext;

  @override
  void initState() {
    super.initState();
    // 未配置用户（userId == 0）不加载，与底部联网查询按钮的显示条件一致
    if (Stores.infoStore.getCurrentUserId() != 0) {
      // 页面销毁重建（底部 tab / 抽屉切换）后同步恢复上次排名：首帧即展示，
      // 避免"先空白后出现"再次触发排名行入场动画；随后 _loadRanks 从
      // TTL 缓存重新推导（缓存命中零请求，过期则按缓存语义后台静默刷新）。
      final cache = _rankCache;
      final username = Stores.infoStore.getCurrentUsername();
      if (cache != null && cache.$1 == Stores.infoStore.getCurrentUserId()) {
        _playerRank = cache.$2;
        _playerGapPrev = cache.$3;
        _playerGapNext = cache.$4;
        _hellRank = cache.$5;
        _guildRank = cache.$6;
      }
      // 从榜单 TTL 缓存重新推导排名胶囊：页面被销毁重建（底部 tab /
      // 抽屉切换）后胶囊状态丢失，这里恢复——缓存命中零请求，
      // 过期则按缓存语义后台静默刷新，不会随页面重建反复请求。
      _loadRanks();
      // 启动时静默查询当前用户波数：打开应用最先想看到的就是自己的最新数据，
      // 查询成功后的预取逻辑顺带刷新榜单与排名展示，无需单独 prewarm。
      // 会话级去重：页面因 tab/抽屉切换被销毁重建时不再重复自动查询。
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
    // 查询起始时记录用户 id：快照按数据归属的 id 缓存，
    // 即使 await 期间切换用户也不会错配
    final userId = Stores.infoStore.getCurrentUserId();
    final currentUser = Stores.infoStore.getCurrentUsername();
    final lower = currentUser.toLowerCase();
    final guild = Stores.infoStore.getCurrentUserGuild();
    final guildLower = guild.toLowerCase();
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
      // 快照本次查询结果：页面销毁重建后由 initState 同步恢复，
      // 保证重建首帧即有排名、不重放入场动画
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
          // 上一名（排名靠前、分数更高）：还需多少分追上
          gapPrev: i > 0 ? items[i - 1].score - p.score : null,
          // 下一名（排名靠后、分数更低）：领先多少分；末名无下一名
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('查询过于频繁，请稍后后再试')));
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
    // 拉取个人赛季数据并写入 store（含封禁标记与上次在线）
    final result = await Stores.infoStore.syncCurrentUser();

    if (!mounted) return;
    setState(() => _querying = false);

    if (result is PlayerQueryResult) {
      // 封禁检测：仅标记「已封禁」（AppBar 副标题展示），不写入波数
      if (result.wave == 0 && result.queryDate.isEmpty) {
        if (!silent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('用户「$name」已被封禁')));
        }
        return;
      }
      // 查询后刷新排名展示：手动同步强制重新拉取三类榜单（TTL 缓存仅对
      // 静默自动查询生效），失败保留旧缓存与胶囊，成功则胶囊立即更新
      _loadRanks(force: !silent);
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
  }

  String _queryErrorMessage(String name, QueryError error) {
    return switch (error) {
      NameNotFound() => '未找到「$name」的赛季数据',
      TimeoutError() => '查询超时，请稍后重试',
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return UserPageScaffold(
      title: '阵容',
      // 新增条目按钮：列表重建由 store 的 cardIdsNotifier 驱动
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '新增条目',
          onPressed: () => Stores.infoStore.addNewCard(),
        ),
      ],
      body: Column(
        children: [
          // 卡片列表监听 store 的结构变化（新增/删除/排序），自动重建
          Expanded(
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
                    // 拖拽前先清除焦点，避免 TextField 的 FocusNode
                    // 在 widget 临时脱离树时产生不一致状态导致崩溃
                    FocusManager.instance.primaryFocus?.unfocus();
                    Stores.infoStore.reorderCard(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final id = cardIds[index];
                    return FormationCardTile(
                      // ReorderableListView 要求每个列表项（直接子项）有唯一 key
                      key: ValueKey(id),
                      id: id,
                      index: index,
                      textController: _textControllerFor(id),
                      numberController: _numberControllerFor(id),
                      textFocusNode: _focusNodeFor(id, _textFocusNodes),
                      numberFocusNode: _focusNodeFor(id, _numberFocusNodes),
                      onRemove: _removeCard,
                    );
                  },
                  buildDefaultDragHandles: false,
                  scrollDirection: .vertical,
                );
              },
            ),
          ),
          FormationSummaryBar(
            querying: _querying,
            playerRank: _playerRank,
            playerGapPrev: _playerGapPrev,
            playerGapNext: _playerGapNext,
            hellRank: _hellRank,
            guildRank: _guildRank,
            onQuery: _queryOnline,
          ),
        ],
      ),
    );
  }
}
