import 'api.dart';

/// 排行榜/公会数据的会话级缓存。
///
/// - 公会成员详情：命中缓存直接返回，**不自动刷新**（由用户手动刷新；
///   手动刷新失败时保留旧缓存）；
/// - 三个公开榜单（玩家赛季 / 无尽 / 公会前 300）：首次访问抓取并缓存，
///   TTL（[ttl]）过期后先返回旧数据、同时后台静默刷新——榜单是共享数据、
///   变化慢，不值得让用户等待，也避免高频请求；用户手动刷新（force）时
///   忽略缓存强制重新抓取，失败保留旧缓存。
class RankingCache {
  RankingCache._();

  /// 公开榜单缓存有效期
  static const Duration ttl = Duration(minutes: 15);

  // ── 公会成员详情（无 TTL，手动刷新）──────────────────────────────

  static final Map<String, List<GuildMember>> _guildDetails = {};

  /// 获取公会成员列表：命中缓存直接返回；[force] 为 true（用户手动刷新）
  /// 时忽略缓存重新请求，成功后覆盖缓存，失败保留旧缓存。
  static Future<Object /* List<GuildMember> | QueryError */> guildDetail(
    String guildName, {
    bool force = false,
  }) async {
    final cached = _guildDetails[guildName];
    if (!force && cached != null) return cached;
    final result = await PlayerApiService.queryGuildDetail(guildName);
    if (result is List<GuildMember>) {
      _guildDetails[guildName] = List<GuildMember>.from(result);
    }
    return result;
  }

  // ── 公开榜单（TTL 过期自动刷新）───────────────────────────────────

  static List<GuildInfo>? _guilds;
  static DateTime? _guildsAt;
  static List<PlayerRankInfo>? _players;
  static DateTime? _playersAt;
  static List<HellRankInfo>? _hell;
  static DateTime? _hellAt;

  /// 公会前 300 榜单（返回 [GuildInfo] 列表或 [QueryError]）；
  /// [force] 为 true（用户手动刷新）时忽略缓存重新请求，失败保留旧缓存。
  static Future<Object> guildRanking({bool force = false}) => _cachedList<GuildInfo>(
        'guilds',
        () => _guilds,
        (v) => _guilds = v,
        () => _guildsAt,
        (t) => _guildsAt = t,
        PlayerApiService.queryGuildRanking,
        force: force,
      );

  /// 玩家赛季波前 300 榜单；
  /// [force] 为 true（用户手动刷新）时忽略缓存重新请求，失败保留旧缓存。
  static Future<Object> playerRanking({bool force = false}) => _cachedList<PlayerRankInfo>(
        'players',
        () => _players,
        (v) => _players = v,
        () => _playersAt,
        (t) => _playersAt = t,
        PlayerApiService.queryPlayerRanking,
        force: force,
      );

  /// 玩家无尽模式前 300 榜单；
  /// [force] 为 true（用户手动刷新）时忽略缓存重新请求，失败保留旧缓存。
  static Future<Object> hellRanking({bool force = false}) => _cachedList<HellRankInfo>(
        'hell',
        () => _hell,
        (v) => _hell = v,
        () => _hellAt,
        (t) => _hellAt = t,
        PlayerApiService.queryHellRanking,
        force: force,
      );

  /// 正在进行的抓取（key → Future），并发调用同一榜单时复用同一个请求
  static final Map<String, Future<Object>> _inflight = {};

  /// 通用榜单缓存逻辑：
  /// 命中且在 TTL 内 → 直接返回；
  /// 命中但已过期 → 先返回旧数据，同时后台静默刷新；
  /// 未命中或 [force] → 同步请求，成功后缓存（force 失败保留旧缓存）；
  /// 无论哪种情况，同一榜单的并发调用共享同一个请求（[_inflight] 去重）。
  static Future<Object /* List<T> | QueryError */> _cachedList<T>(
    String key,
    List<T>? Function() read,
    void Function(List<T> value) write,
    DateTime? Function() readAt,
    void Function(DateTime time) writeAt,
    Future<Object> Function() fetch, {
    bool force = false,
  }) async {
    final cached = read();
    // 命中缓存且未强制刷新：TTL 内直接返回，过期则后台刷新后仍先给旧数据
    if (cached != null && !force) {
      final at = readAt();
      if (at == null || DateTime.now().difference(at) > ttl) {
        // TTL 过期：后台静默刷新，界面先拿旧数据，不空转；
        // 已有刷新进行中则直接跳过，避免并发重复请求
        final inflight = _inflight[key];
        if (inflight == null) {
          final future = fetch();
          _inflight[key] = future;
          future.then((result) {
            if (result is List<T>) {
              write(result);
              writeAt(DateTime.now());
            }
          }, onError: (_) {}).whenComplete(() => _inflight.remove(key));
        }
      }
      return cached;
    }
    // 未命中或强制刷新：并发调用时复用同一个请求，避免重复抓取
    final inflight = _inflight[key];
    if (inflight != null) return inflight;
    final future = fetch();
    _inflight[key] = future;
    try {
      final result = await future;
      if (result is List<T>) {
        write(result);
        writeAt(DateTime.now());
      }
      return result;
    } finally {
      _inflight.remove(key);
    }
  }
}
