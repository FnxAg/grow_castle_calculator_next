import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/guild/guild_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/page/function/formation_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user_guild.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/last_online.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/loading_indicator_app_bar.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/rank_pill_row.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// 首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static final Set<String> _autoQueriedUsers = {};

  /// 最近一次查询到的排名快照
  static (
    int userId,
    int? playerRank,
    int? playerGapPrev,
    int? playerGapNext,
    int? hellRank,
    int? hellGapPrev,
    int? hellGapNext,
    int? guildRank,
    int? guildGapPrev,
    int? guildGapNext,
    int? hellScore,
    int? guildScore,
  )?
  _rankCache;

  static const Duration _queryCooldown = Duration(seconds: 5);
  DateTime? _lastQueryAt;
  bool _querying = false;
  bool _loadingRanks = false;

  int? _playerRank;
  int? _hellRank;
  int? _guildRank;
  int? _playerGapPrev;
  int? _playerGapNext;
  int? _hellGapPrev;
  int? _hellGapNext;
  int? _guildGapPrev;
  int? _guildGapNext;
  int? _hellScore;
  int? _guildScore;

  @override
  void initState() {
    super.initState();
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      reloadForCurrentUser();
    });
    _loadCurrentUser();
  }

  /// 切换用户
  void reloadForCurrentUser() {
    setState(() {
      _playerRank = null;
      _playerGapPrev = null;
      _playerGapNext = null;
      _hellRank = null;
      _hellGapPrev = null;
      _hellGapNext = null;
      _guildRank = null;
      _guildGapPrev = null;
      _guildGapNext = null;
      _hellScore = null;
      _guildScore = null;
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
        _hellGapPrev = cache.$6;
        _hellGapNext = cache.$7;
        _guildRank = cache.$8;
        _guildGapPrev = cache.$9;
        _guildGapNext = cache.$10;
        _hellScore = cache.$11;
        _guildScore = cache.$12;
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
      // 公会详情不参与排名展示，但成员总分要回填给首页的公会卡
      RankingCache.guildDetail(guild, force: force).then((detail) {
        if (!mounted) return;
        if (detail is SeasonQueryResult<GuildMember>) {
          ref
              .read(guildTotalScoreProvider.notifier)
              .publishFromMembers(detail.items);
        }
      });
    }
    if (!mounted) return;
    setState(() {
      _loadingRanks = false;
      _playerRank = null;
      _playerGapPrev = null;
      _playerGapNext = null;
      if (players is SeasonQueryResult<RankInfo>) {
        final found = _findRank(players.items, lower);
        _playerRank = found?.rank;
        _playerGapPrev = found?.gapPrev;
        _playerGapNext = found?.gapNext;
      }
      _hellRank = null;
      _hellGapPrev = null;
      _hellGapNext = null;
      _hellScore = null;
      if (hell is SeasonQueryResult<RankInfo>) {
        final found = _findRank(hell.items, lower);
        _hellRank = found?.rank;
        _hellGapPrev = found?.gapPrev;
        _hellGapNext = found?.gapNext;
        _hellScore = found?.score;
      }
      _guildRank = null;
      _guildGapPrev = null;
      _guildGapNext = null;
      _guildScore = null;
      if (guilds is SeasonQueryResult<RankInfo>) {
        final found = _findRank(guilds.items, guildLower);
        _guildRank = found?.rank;
        _guildGapPrev = found?.gapPrev;
        _guildGapNext = found?.gapNext;
        _guildScore = found?.score;
      }
      _rankCache = (
        userId,
        _playerRank,
        _playerGapPrev,
        _playerGapNext,
        _hellRank,
        _hellGapPrev,
        _hellGapNext,
        _guildRank,
        _guildGapPrev,
        _guildGapNext,
        _hellScore,
        _guildScore,
      );
    });
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
    final l10n = AppLocalizations.of(context);
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    final isDefaultUser = ref.watch(currentUserIdProvider) == 0;
    final wave = ref.watch(currentUserWaveProvider);
    final seasonWave = ref.watch(currentUserSeasonWaveProvider);
    final totalGold = ref.watch(currentUserTotalGoldProvider);
    final gp = ref.watch(currentUserGpProvider);
    final gpCn = ref.watch(currentUserGpCnProvider);
    final dailyIncome = ref.watch(dailyIncomeProvider).total;
    final gabBonus = ref.watch(currentUserGabBonusProvider);
    final infiniteColony = ref.watch(currentUserInfiniteColonyProvider);
    final guildTotalScore = ref.watch(guildTotalScoreProvider);
    const chipTextStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
    );
    // 波数
    final waveCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          title: Text(l10n.totalWave),
          leadingIcon: Icons.emoji_events,
          trailing: SummaryRowValueText(text: wave.format()),
        ),
        SummaryRow(
          title: Text(l10n.seasonWave),
          leadingIcon: Icons.eco,
          trailing: SummaryRowValueText(text: seasonWave.format()),
        ),
        if (_playerRank != null ||
            _playerGapPrev != null ||
            _playerGapNext != null)
          RankPillRow(
            rank: _playerRank,
            gapPrev: _playerGapPrev,
            gapNext: _playerGapNext,
          ),
      ],
    );
    // 经济
    final economyCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          leadingIcon: Icons.monetization_on,
          title: Text(l10n.totalGold),
          trailing: SummaryRowValueText(
            text: totalGold.formatCompact(
              fractionDigits: 2,
              english: english,
              traditional: traditional,
            ),
          ),
        ),
        SummaryRow(
          leadingIcon: Icons.star,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(l10n.goldPower)],
          ),
          trailing: SummaryRowValueText(
            text:
                '${gp.format(fractionDigits: 3)}'
                ' · '
                '${gpCn.format(fractionDigits: 3)}',
          ),
        ),
        SummaryRow(
          leadingIcon: Icons.auto_graph,
          title: Text(l10n.income),
          trailing: Row(
            children: [
              PillChip(
                text: Text(
                  '${gabBonus.toStringAsFixed(2)}%',
                  style: chipTextStyle,
                ),
              ),
              const SizedBox(width: 8.0),
              SummaryRowValueText(
                text: dailyIncome.formatCompact(
                  fractionDigits: 2,
                  english: english,
                  traditional: traditional,
                ),
              ),
            ],
          ),
        ),
        SummaryRow(
          leadingIcon: Icons.flag,
          title: Text(l10n.infiniteColony),
          trailing: Row(
            children: [
              PillChip(
                text: Text(
                  (infiniteColony * 1000 / wave).toStringAsFixed(2),
                  style: chipTextStyle,
                ),
              ),
              const SizedBox(width: 8.0),
              SummaryRowValueText(text: 'Lv.${infiniteColony.format()}'),
            ],
          ),
        ),
      ],
    );
    // 公会
    final guildCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          leadingIcon: Icons.flag_circle,
          title: Text(l10n.guildTotalScore),
          trailing: SummaryRowValueText(text: guildTotalScore?.format() ?? '—'),
        ),
        if (_guildRank != null ||
            _guildGapPrev != null ||
            _guildGapNext != null)
          RankPillRow(
            rank: _guildRank,
            gapPrev: _guildGapPrev,
            gapNext: _guildGapNext,
          ),
      ],
    );
    // 无尽
    final hellCard = SummaryCard(
      children: <Widget>[
        SummaryRow(
          leadingIcon: Icons.all_inclusive,
          title: Text(l10n.hellModeScore),
          trailing: SummaryRowValueText(text: _hellScore?.format() ?? '—'),
        ),
        if (_hellRank != null || _hellGapPrev != null || _hellGapNext != null)
          RankPillRow(
            rank: _hellRank,
            gapPrev: _hellGapPrev,
            gapNext: _hellGapNext,
          ),
      ],
    );
    // 快捷入口
    final quickAccess = <Widget>[
      SectionHeader(l10n.sectionQuickAccess),
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
            MaterialPageRoute(builder: (context) => const FormationCalcPage()),
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
                    children: [waveCard, economyCard, guildCard, hellCard],
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
                              waveCard,
                              economyCard,
                              guildCard,
                              hellCard,
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
      CurrentUser(),
      LastOnline(),
      CurrentUserGuild(),
    ];
    return AppBarInfo(children: segments);
  }
}
