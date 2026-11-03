import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/guild_rank.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_hell_mode_rank.dart';
import 'package:grow_castle_calculator_next/core/src/reward_from_leaderboard/player_rank.dart';
import 'package:grow_castle_calculator_next/icon/box.dart';
import 'package:grow_castle_calculator_next/icon/crystal.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/guild/guild_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/divider.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/build_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/loading_indicator_app_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/subtitle_pill_wrap.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

enum AnimSource {
  playerPrev,
  playerSelf,
  playerNext,
  guildPrev,
  guildSelf,
  guildNext,
  hellPrev,
  hellSelf,
  hellNext,
  rewardCard,
}

/// 首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  static final Set<String> _autoQueriedUsers = {};

  late final Map<AnimSource, AnimationController> _animCtrls;
  late final Map<AnimSource, CurvedAnimation> _anims;

  static const Duration _queryCooldown = Duration(seconds: 5);
  DateTime? _lastQueryAt;
  bool _querying = false;
  bool _loadingRanks = false;

  int? _playerRank;
  int? _hellRank;
  int? _guildRank;
  int? _playerGapPrev;
  String? _playerPrevName;
  int? _playerGapNext;
  String? _playerNextName;
  int? _hellGapPrev;
  String? _hellPrevName;
  int? _hellGapNext;
  String? _hellNextName;
  int? _guildGapPrev;
  String? _guildPrevName;
  int? _guildGapNext;
  String? _guildNextName;
  int? _hellScore;
  int _redCrystalFromPlayerRank = 0;
  int _redCrystalFromHellModeRank = 0;
  int _crystalReward = 0;
  int _boxReward = 0;

  @override
  void initState() {
    super.initState();
    _animCtrls = {
      for (final source in AnimSource.values)
        source: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
          value: 0,
        ),
    };
    _anims = {
      for (final source in AnimSource.values)
        source: CurvedAnimation(
          parent: _animCtrls[source]!,
          curve: Curves.easeInOutCubic,
        ),
    };
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      _loadCurrentUser();
    });
    _loadCurrentUser();
  }

  @override
  void dispose() {
    for (final animation in _anims.values) {
      animation.dispose();
    }
    for (final controller in _animCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 按当前用户初始化页面状态，挂载时、以及切换用户后调用
  void _loadCurrentUser() {
    final userId = ref.read(currentUserIdProvider);
    final username = ref.read(currentUsernameProvider);
    final guild = ref.read(currentUserProvider).guild;
    // 榜单大多已在内存里，先同步算出新用户的数据，避免卡片收起再展开
    if (userId == 0 || !_applyCachedRanks(username, guild)) {
      _clearRanks();
    }
    _syncAnimations(animate: false);
    if (userId == 0) {
      // 默认用户不查榜单，清理可能残留的加载态
      _loadingRanks = false;
      return;
    }
    // 从榜单 TTL 缓存重新推导排名
    _loadRanks();
    // 应用启动时静默查询当前用户波数
    if (_autoQueriedUsers.add(username)) {
      _performQuery(silent: true);
    }
  }

  /// 用内存中的榜单同步计算排名；数据不全时返回 false
  bool _applyCachedRanks(String username, String guild) {
    final players = RankingCache.cachedPlayerRanking;
    final hell = RankingCache.cachedHellRanking;
    final guilds = RankingCache.cachedGuildRanking;
    if (players == null ||
        hell == null ||
        (guild.isNotEmpty && guilds == null)) {
      return false;
    }
    _applyRanks(username, guild, players, hell, guilds);
    return true;
  }

  /// 按榜单结果更新排名、名次差与奖励
  void _applyRanks(
    String username,
    String guild,
    Object? players,
    Object? hell,
    Object? guilds,
  ) {
    final lower = username.toLowerCase();
    final guildLower = guild.toLowerCase();
    _playerRank = null;
    _playerGapPrev = null;
    _playerPrevName = null;
    _playerGapNext = null;
    _playerNextName = null;
    if (players is SeasonQueryResult<RankInfo>) {
      final found = _findRank(players.items, lower);
      _playerRank = found?.rank;
      _playerGapPrev = found?.gapPrev;
      _playerPrevName = found?.prevName;
      _playerGapNext = found?.gapNext;
      _playerNextName = found?.nextName;
    }
    _hellRank = null;
    _hellGapPrev = null;
    _hellPrevName = null;
    _hellGapNext = null;
    _hellNextName = null;
    _hellScore = null;
    if (hell is SeasonQueryResult<RankInfo>) {
      final found = _findRank(hell.items, lower);
      _hellRank = found?.rank;
      _hellGapPrev = found?.gapPrev;
      _hellPrevName = found?.prevName;
      _hellGapNext = found?.gapNext;
      _hellNextName = found?.nextName;
      _hellScore = found?.score;
    }
    _guildRank = null;
    _guildGapPrev = null;
    _guildPrevName = null;
    _guildGapNext = null;
    _guildNextName = null;
    if (guilds is SeasonQueryResult<RankInfo>) {
      final found = _findRank(guilds.items, guildLower);
      _guildRank = found?.rank;
      _guildGapPrev = found?.gapPrev;
      _guildPrevName = found?.prevName;
      _guildGapNext = found?.gapNext;
      _guildNextName = found?.nextName;
    }
    _redCrystalFromPlayerRank = getRedCrystalFromPlayerRank(_playerRank ?? 0);
    _redCrystalFromHellModeRank = getRedCrystalFromHellModeRank(_hellRank ?? 0);
    _crystalReward = _redCrystalFromPlayerRank + _redCrystalFromHellModeRank;
    _boxReward = getItemBoxFromGuildRank(_guildRank ?? 0);
  }

  /// 清空排名，避免展示上一个用户的数据
  void _clearRanks() {
    _playerRank = null;
    _playerGapPrev = null;
    _playerPrevName = null;
    _playerGapNext = null;
    _playerNextName = null;
    _hellRank = null;
    _hellGapPrev = null;
    _hellPrevName = null;
    _hellGapNext = null;
    _hellNextName = null;
    _guildRank = null;
    _guildGapPrev = null;
    _guildPrevName = null;
    _guildGapNext = null;
    _guildNextName = null;
    _hellScore = null;
    _crystalReward = 0;
    _boxReward = 0;
    _syncAnimations(animate: false);
  }

  /// 各排名内容独立跟随是否可见；[animate] 为 false 时直接到位
  void _syncAnimations({required bool animate}) {
    final visible = <AnimSource, bool>{
      AnimSource.playerPrev: _playerGapPrev != null,
      AnimSource.playerSelf: _playerRank != null,
      AnimSource.playerNext: _playerGapNext != null,
      AnimSource.guildPrev: _guildGapPrev != null,
      AnimSource.guildSelf: _guildRank != null,
      AnimSource.guildNext: _guildGapNext != null,
      AnimSource.hellPrev: _hellGapPrev != null,
      AnimSource.hellSelf: _hellRank != null,
      AnimSource.hellNext: _hellGapNext != null,
      AnimSource.rewardCard: _crystalReward > 0 || _boxReward > 0,
    };
    for (final entry in visible.entries) {
      final controller = _animCtrls[entry.key]!;
      final target = entry.value ? 1.0 : 0.0;
      if (!animate) {
        controller.value = target;
      } else if (entry.value) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  /// 获取排名
  Future<void> _loadRanks({bool force = false}) async {
    final userId = ref.read(currentUserIdProvider);
    final username = ref.read(currentUsernameProvider);
    final guild = ref.read(currentUserProvider).guild;
    // 榜单已缓存时只是后台刷新，不显示进度条，避免切换时 AppBar 高度跳动
    final cached =
        RankingCache.cachedPlayerRanking != null &&
        RankingCache.cachedHellRanking != null &&
        (guild.isEmpty || RankingCache.cachedGuildRanking != null);
    if ((force || !cached) && !_loadingRanks) {
      setState(() => _loadingRanks = true);
    }
    final (players, hell, guilds) = await (
      RankingCache.playerRanking(force: force),
      RankingCache.hellRanking(force: force),
      guild.isEmpty
          ? Future<Object?>.value(null)
          : RankingCache.guildRanking(force: force),
    ).wait;
    if (guild.isNotEmpty) {
      // 公会详情不参与排名展示，但成员总分要回填给首页的公会卡
      RankingCache.guildDetail(guild, force: force).then((detail) {
        if (!mounted) return;
        if (ref.read(currentUserIdProvider) != userId) return;
        if (detail is SeasonQueryResult<GuildMember>) {
          ref
              .read(guildTotalScoreProvider.notifier)
              .publishFromMembers(detail.items);
        }
      });
    }
    if (!mounted) return;
    // 加载期间已切到其他用户，结果作废
    if (ref.read(currentUserIdProvider) != userId) return;
    setState(() {
      _loadingRanks = false;
      _applyRanks(username, guild, players, hell, guilds);
    });
    _syncAnimations(animate: true);
  }

  /// 在榜单中按名字（不区分大小写）取当前用户/公会的那一条
  RankInfo? _findRank(List<RankInfo> items, String lowerName) {
    for (final item in items) {
      if (item.name.toLowerCase() == lowerName) return item;
    }
    return null;
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
    _lastQueryAt = now;
    await _performQuery();
  }

  /// 执行查询
  Future<void> _performQuery({bool silent = false}) async {
    if (!silent) setState(() => _querying = true);
    try {
      final name = ref.read(currentUsernameProvider);
      final result = await ref.read(usersProvider.notifier).syncCurrentUser();

      if (!mounted) return;
      // 查询期间已切换用户，结果与当前页面无关
      if (ref.read(currentUsernameProvider) != name) return;

      if (result is PlayerQueryResult) {
        if (result.wave == 0 && result.queryDate.isEmpty) {
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).snackUserBanned(name),
                ),
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
    } finally {
      if (!silent && mounted) setState(() => _querying = false);
    }
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    final isDefaultUser = ref.watch(currentUserIdProvider) == 0;
    final username = ref.read(currentUsernameProvider);
    final guild = ref.read(currentUserGuildProvider);
    final wave = ref.watch(currentUserWaveProvider);
    final seasonWave = ref.watch(currentUserSeasonWaveProvider);
    final totalGold = ref.watch(currentUserTotalGoldProvider);
    final gp = ref.watch(currentUserGpProvider);
    final gpCn = ref.watch(currentUserGpCnProvider);
    final dailyIncome = ref.watch(dailyIncomeProvider).total;
    final gabBonus = ref.watch(currentUserGabBonusProvider);
    final infiniteColony = ref.watch(currentUserInfiniteColonyProvider);
    final guildTotalScore = ref.watch(guildTotalScoreProvider);

    final crystalIcon = CrystalIcon(
      size: PillChip.leadingIconSize,
      color: scheme.primary,
    );
    final boxIcon = BoxIcon(
      size: PillChip.leadingIconSize,
      color: scheme.primary,
    );

    // 总波数
    final totalWaveCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          title: Text(l10n.totalWave),
          leading: Icon(Icons.emoji_events),
          trailing: SummaryRow.text(wave.format()),
        ),
      ],
    );
    // 赛季波数
    final seasonWaveCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          title: Text(l10n.seasonWave),
          leading: Icon(Icons.eco),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizeTransition(
                sizeFactor: _anims[AnimSource.playerPrev]!,
                child: _playerGapPrev != null
                    ? SubtitlePillWrap(
                        children: [
                          PillChip(
                            text: dividerText([
                              '#${_playerRank! - 1}',
                              _playerPrevName ?? '',
                            ]),
                          ),
                          PillChip(
                            backgroundColor: Colors.red,
                            foreground: Colors.white,
                            text: '+${_playerGapPrev!.format()}',
                          ),
                        ],
                      )
                    : null,
              ),
              SubtitlePillWrap(
                children: [
                  SizeTransition(
                    sizeFactor: _anims[AnimSource.playerSelf]!,
                    child: _playerRank != null
                        ? PillChip(
                            text: dividerText(['#$_playerRank', username]),
                          )
                        : null,
                  ),
                  SummaryRow.text(seasonWave.format()),
                ],
              ),
              SizeTransition(
                sizeFactor: _anims[AnimSource.playerNext]!,
                child: _playerGapNext != null
                    ? SubtitlePillWrap(
                        children: [
                          PillChip(
                            text: dividerText([
                              '#${_playerRank! + 1}',
                              _playerNextName ?? '',
                            ]),
                          ),
                          PillChip(
                            backgroundColor: Colors.green,
                            foreground: Colors.white,
                            text: '-${_playerGapNext!.format()}',
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
    // 经济
    final economyCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          leading: Icon(Icons.monetization_on),
          title: Text(l10n.totalGold),
          trailing: SummaryRow.text(
            totalGold.formatCompact(
              fractionDigits: 2,
              english: english,
              traditional: traditional,
            ),
          ),
        ),
        SummaryRow(
          leading: Icon(Icons.star),
          title: Row(mainAxisSize: MainAxisSize.min, children: [Text(l10n.gp)]),
          trailing: SummaryRow.text(gp.format(fractionDigits: 3)),
        ),
        SummaryRow(
          leading: Icon(Icons.star),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(l10n.gpCN)],
          ),
          trailing: SummaryRow.text(gpCn.format(fractionDigits: 3)),
        ),
        SummaryRow(
          leading: Icon(Icons.auto_graph),
          title: Text(l10n.income),
          trailing: Row(
            children: [
              PillChip(text: '${gabBonus.toStringAsFixed(2)}%'),
              const SizedBox(width: 8.0),
              SummaryRow.text(
                dailyIncome.formatCompact(
                  fractionDigits: 2,
                  english: english,
                  traditional: traditional,
                ),
              ),
            ],
          ),
        ),
        SummaryRow(
          leading: Icon(Icons.flag),
          title: Text(l10n.infiniteColony),
          trailing: Row(
            children: [
              PillChip(text: (infiniteColony * 1000 / wave).toStringAsFixed(2)),
              const SizedBox(width: 8.0),
              SummaryRow.text('Lv.${infiniteColony.format()}'),
            ],
          ),
        ),
      ],
    );
    // 公会
    final guildCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          leading: Icon(Icons.flag_circle),
          title: Text(l10n.guildTotalScore),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizeTransition(
                sizeFactor: _anims[AnimSource.guildPrev]!,
                child: _guildGapPrev != null
                    ? SubtitlePillWrap(
                        children: [
                          PillChip(
                            text: dividerText([
                              '#${_guildRank! - 1}',
                              _guildPrevName ?? '',
                            ]),
                          ),
                          PillChip(
                            backgroundColor: Colors.red,
                            foreground: Colors.white,
                            text: '+${_guildGapPrev!.format()}',
                          ),
                        ],
                      )
                    : null,
              ),
              SubtitlePillWrap(
                children: [
                  SizeTransition(
                    sizeFactor: _anims[AnimSource.guildSelf]!,
                    child: _guildRank != null
                        ? PillChip(text: dividerText(['#$_guildRank', guild]))
                        : null,
                  ),
                  SummaryRow.text(guildTotalScore?.format() ?? '—'),
                ],
              ),
              SizeTransition(
                sizeFactor: _anims[AnimSource.guildNext]!,
                child: _guildGapNext != null
                    ? SubtitlePillWrap(
                        children: [
                          PillChip(
                            text: dividerText([
                              '#${_guildRank! + 1}',
                              _guildNextName ?? '',
                            ]),
                          ),
                          PillChip(
                            backgroundColor: Colors.green,
                            foreground: Colors.white,
                            text: '-${_guildGapNext!.format()}',
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
    // 无尽
    final hellCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          leading: Icon(Icons.all_inclusive),
          title: Text(l10n.hellModeScore),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizeTransition(
                sizeFactor: _anims[AnimSource.hellPrev]!,
                child: _hellGapPrev != null
                    ? SubtitlePillWrap(
                        children: [
                          PillChip(
                            text: dividerText([
                              '#${_hellRank! - 1}',
                              _hellPrevName ?? '',
                            ]),
                          ),
                          PillChip(
                            backgroundColor: Colors.red,
                            foreground: Colors.white,
                            text:
                                '+${_hellGapPrev!.formatCompact(english: english, traditional: traditional)}',
                          ),
                        ],
                      )
                    : null,
              ),
              SubtitlePillWrap(
                children: [
                  SizeTransition(
                    sizeFactor: _anims[AnimSource.hellSelf]!,
                    child: _hellRank != null
                        ? PillChip(text: dividerText(['#$_hellRank', username]))
                        : null,
                  ),
                  SummaryRow.text(
                    _hellScore?.formatCompact(
                          english: english,
                          traditional: traditional,
                        ) ??
                        '—',
                  ),
                ],
              ),
              SizeTransition(
                sizeFactor: _anims[AnimSource.hellNext]!,
                child: _hellGapNext != null
                    ? SubtitlePillWrap(
                        children: [
                          PillChip(
                            text: dividerText([
                              '#${_hellRank! + 1}',
                              _hellNextName ?? '',
                            ]),
                          ),
                          PillChip(
                            backgroundColor: Colors.green,
                            foreground: Colors.white,
                            text:
                                '-${_hellGapNext!.formatCompact(english: english, traditional: traditional)}',
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
    // 奖励
    final rewardCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          leading: BoxIcon(
            size: SummaryRow.leadingIconSize,
            color: scheme.primary,
          ),
          title: Text(l10n.reward),
          trailing: SubtitlePillWrap(
            children: [
              if (_boxReward > 0)
                PillChip(text: '$_boxReward', leading: boxIcon),
              if (_crystalReward > 0)
                Tooltip(
                  message: [
                    (_redCrystalFromPlayerRank > 0
                        ? 'Season Rank +$_redCrystalFromPlayerRank'
                        : ''),
                    (_redCrystalFromHellModeRank > 0
                        ? 'Hell Mode Rank +$_redCrystalFromHellModeRank'
                        : ''),
                  ].where((e) => e.isNotEmpty).join('\n'),
                  child: PillChip(
                    text: '$_crystalReward',
                    leading: crystalIcon,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    // 快捷入口
    final quickAccess = <Widget>[
      SectionHeader(l10n.sectionQuickAccess),
      if (!isDefaultUser)
        ListTile(
          leading: const Icon(Icons.view_compact),
          title: Text(l10n.tabCheckCurrentUserWph),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlayerDetailPage(
                  playerName: ref.read(currentUsernameProvider),
                ),
              ),
            );
          },
        ),
      ListTile(
        leading: const Icon(Icons.castle),
        title: Text(l10n.tabFormation),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BuildCalcPage()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.group),
        title: Text(l10n.settingsUserManagement),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SelectUserPage()),
          );
        },
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(l10n.tabHome), _AppBarInfo()],
        ),
        bottom: LoadingIndicatorAppBar(
          bottom: null,
          isLoading: _querying || _loadingRanks,
        ),
        actions: [
          if (!isDefaultUser)
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
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const padding = EdgeInsets.all(16.0);
          // 窄屏
          if (constraints.maxWidth < Breakpoints.sideBySide) {
            return ListView(
              children: [
                Padding(
                  padding: padding,
                  child: Column(
                    children: [
                      totalWaveCard,
                      seasonWaveCard,
                      economyCard,
                      guildCard,
                      hellCard,
                      SizeTransition(
                        sizeFactor: _anims[AnimSource.rewardCard]!,
                        alignment: .bottomCenter,
                        child: rewardCard,
                      ),
                    ],
                  ),
                ),
                ...quickAccess,
              ],
            );
          }
          // 宽屏
          return ListView(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: padding,
                          child: Column(
                            children: [
                              totalWaveCard,
                              seasonWaveCard,
                              economyCard,
                              guildCard,
                              hellCard,
                              SizeTransition(
                                sizeFactor: _anims[AnimSource.rewardCard]!,
                                alignment: .bottomCenter,
                                child: rewardCard,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [...quickAccess],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = <Widget>[
      AppBarItem.currentUser(),
      AppBarItem.currentUserLastOnline(),
      AppBarItem.currentUserGuild(),
    ];
    return AppBarInfo(children: segments);
  }
}
