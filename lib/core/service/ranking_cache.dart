import 'package:flutter/foundation.dart';

import 'api.dart';

/// 排行榜/公会数据缓存
class RankingCache {
  RankingCache._();

  static const Duration ttl = Duration(minutes: 15);

  static final ValueNotifier<SeasonRange?> playerSeasonNotifier =
      ValueNotifier<SeasonRange?>(null);
  static final ValueNotifier<SeasonRange?> guildSeasonNotifier =
      ValueNotifier<SeasonRange?>(null);
  static final ValueNotifier<SeasonRange?> hellSeasonNotifier =
      ValueNotifier<SeasonRange?>(null);

  static final Map<String, SeasonQueryResult<GuildMember>> _guildDetails = {};

  static Future<Object /* SeasonQueryResult<GuildMember> | QueryError */> guildDetail(
    String guildName, {
    bool force = false,
  }) async {
    final cached = _guildDetails[guildName];
    if (!force && cached != null) return cached;
    final inflight = _inflight['guild:$guildName'];
    if (inflight != null) return inflight;
    final future = PlayerApiService.queryGuildDetail(guildName);
    _inflight['guild:$guildName'] = future;
    try {
      final result = await future;
      if (result is SeasonQueryResult<GuildMember>) {
        _guildDetails[guildName] = result;
        guildSeasonNotifier.value = result.season;
      }
      return result;
    } finally {
      _inflight.remove('guild:$guildName');
    }
  }

  /// 同步读取内存中的榜单（可能已过期），未加载时为 null
  static SeasonQueryResult<RankInfo>? get cachedPlayerRanking => _players;
  static SeasonQueryResult<RankInfo>? get cachedHellRanking => _hell;
  static SeasonQueryResult<RankInfo>? get cachedGuildRanking => _guilds;

  static SeasonQueryResult<RankInfo>? _guilds;
  static DateTime? _guildsAt;
  static SeasonQueryResult<RankInfo>? _players;
  static DateTime? _playersAt;
  static SeasonQueryResult<RankInfo>? _hell;
  static DateTime? _hellAt;

  static Future<Object> guildRanking({bool force = false}) => _cachedList<RankInfo>(
        'guilds',
        () => _guilds,
        (v) {
          _guilds = v;
          guildSeasonNotifier.value = v.season;
        },
        () => _guildsAt,
        (t) => _guildsAt = t,
        PlayerApiService.queryGuildRanking,
        force: force,
      );

  static Future<Object> playerRanking({bool force = false}) => _cachedList<RankInfo>(
        'players',
        () => _players,
        (v) {
          _players = v;
          playerSeasonNotifier.value = v.season;
        },
        () => _playersAt,
        (t) => _playersAt = t,
        PlayerApiService.queryPlayerRanking,
        force: force,
      );

  static Future<Object> hellRanking({bool force = false}) => _cachedList<RankInfo>(
        'hell',
        () => _hell,
        (v) {
          _hell = v;
          hellSeasonNotifier.value = v.season;
        },
        () => _hellAt,
        (t) => _hellAt = t,
        PlayerApiService.queryHellRanking,
        force: force,
      );

  /// 正在进行的抓取
  static final Map<String, Future<Object>> _inflight = {};

  static Future<Object /* SeasonQueryResult<T> | QueryError */> _cachedList<T>(
    String key,
    SeasonQueryResult<T>? Function() read,
    void Function(SeasonQueryResult<T> value) write,
    DateTime? Function() readAt,
    void Function(DateTime time) writeAt,
    Future<Object> Function() fetch, {
    bool force = false,
  }) async {
    final cached = read();
    // 命中缓存且未强制刷新
    if (cached != null && !force) {
      final at = readAt();
      if (at == null || DateTime.now().difference(at) > ttl) {
        // TTL 过期
        final inflight = _inflight[key];
        if (inflight == null) {
          final future = fetch();
          _inflight[key] = future;
          future.then((result) {
            if (result is SeasonQueryResult<T>) {
              write(result);
              writeAt(DateTime.now());
            }
          }, onError: (_) {}).whenComplete(() => _inflight.remove(key));
        }
      }
      return cached;
    }
    final inflight = _inflight[key];
    if (inflight != null) return inflight;
    final future = fetch();
    _inflight[key] = future;
    try {
      final result = await future;
      if (result is SeasonQueryResult<T>) {
        write(result);
        writeAt(DateTime.now());
      }
      return result;
    } finally {
      _inflight.remove(key);
    }
  }
}
