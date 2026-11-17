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

  /// 赛季已经过的百分比（历史赛季按已结束计）
  static double? seasonProgress(SeasonRange? season) {
    final start = season?.start;
    final end = season?.end;
    if (start == null || end == null) return null;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return null;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// 赛季时间（小时）
  static int? seasonDuration(SeasonRange? season) {
    final start = season?.start;
    final end = season?.end;
    if (start == null || end == null) return null;
    return end.difference(start).inHours;
  }

  static final Map<String, SeasonQueryResult<GuildMember>> _guildDetails = {};

  static Future<Object /* SeasonQueryResult<GuildMember> | QueryError */>
  guildDetail(String guildName, {bool force = false}) async {
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

  static Future<Object> guildRanking({bool force = false}) =>
      _cachedList<RankInfo>(
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

  static Future<Object> playerRanking({bool force = false}) =>
      _cachedList<RankInfo>(
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

  static Future<Object> hellRanking({bool force = false}) =>
      _cachedList<RankInfo>(
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

  /// 历史赛季数据（按日期缓存），不覆盖当前赛季缓存与赛季通知
  static final Map<String, Object> _history = {};
  static final Map<String, DateTime> _historyAt = {};
  static final Map<String, Future<Object>> _historyInflight = {};

  static Future<Object> playerRankingAt(DateTime date, {bool force = false}) =>
      _cachedHistory<RankInfo>(
        'players:${_dayKey(date)}',
        () => PlayerApiService.queryPlayerRanking(seasonDate: date),
        force: force,
      );

  static Future<Object> guildRankingAt(DateTime date, {bool force = false}) =>
      _cachedHistory<RankInfo>(
        'guilds:${_dayKey(date)}',
        () => PlayerApiService.queryGuildRanking(seasonDate: date),
        force: force,
      );

  static Future<Object> hellRankingAt(DateTime date, {bool force = false}) =>
      _cachedHistory<RankInfo>(
        'hell:${_dayKey(date)}',
        () => PlayerApiService.queryHellRanking(seasonDate: date),
        force: force,
      );

  static Future<Object> guildDetailAt(
    String guildName,
    DateTime date, {
    bool force = false,
  }) => _cachedHistory<GuildMember>(
    'guild:${_dayKey(date)}:${guildName.toLowerCase()}',
    () => PlayerApiService.queryGuildDetail(guildName, seasonDate: date),
    force: force,
  );

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  static Future<Object> _cachedHistory<T>(
    String key,
    Future<Object> Function() fetch, {
    bool force = false,
  }) async {
    final cached = _history[key];
    if (cached is SeasonQueryResult<T> && !force) {
      final at = _historyAt[key];
      if (at == null || DateTime.now().difference(at) > ttl) {
        _refreshHistory<T>(key, fetch);
      }
      return cached;
    }
    final inflight = _historyInflight[key];
    if (inflight != null) return inflight;
    final future = fetch();
    _historyInflight[key] = future;
    try {
      final result = await future;
      _storeHistory<T>(key, result);
      return result;
    } finally {
      _historyInflight.remove(key);
    }
  }

  static void _refreshHistory<T>(String key, Future<Object> Function() fetch) {
    if (_historyInflight.containsKey(key)) return;
    final future = fetch();
    _historyInflight[key] = future;
    future
        .then((result) => _storeHistory<T>(key, result), onError: (_) {})
        .whenComplete(() => _historyInflight.remove(key));
  }

  static void _storeHistory<T>(String key, Object result) {
    if (result is SeasonQueryResult<T>) {
      _history[key] = result;
      _historyAt[key] = DateTime.now();
    }
  }

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
          future
              .then((result) {
                if (result is SeasonQueryResult<T>) {
                  write(result);
                  writeAt(DateTime.now());
                }
              }, onError: (_) {})
              .whenComplete(() => _inflight.remove(key));
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
