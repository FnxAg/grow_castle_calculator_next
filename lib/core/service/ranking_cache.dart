import 'api.dart';

/// 排行榜/公会数据的会话级缓存。
///
/// - 公会成员详情：命中缓存直接返回，**不自动刷新**（由用户手动刷新；
///   手动刷新失败时保留旧缓存）；
/// - 三个公开榜单（玩家赛季 / 无尽 / 公会前 300）：首次访问抓取并缓存，
///   TTL（[ttl]）过期后先返回旧数据、同时后台静默刷新——榜单是共享数据、
///   变化慢，不值得让用户等待，也避免高频请求。
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

  /// 公会前 300 榜单（返回 [GuildInfo] 列表或 [QueryError]）
  static Future<Object> guildRanking() => _cachedList<GuildInfo>(
        () => _guilds,
        (v) => _guilds = v,
        () => _guildsAt,
        (t) => _guildsAt = t,
        PlayerApiService.queryGuildRanking,
      );

  /// 玩家赛季波前 300 榜单
  static Future<Object> playerRanking() => _cachedList<PlayerRankInfo>(
        () => _players,
        (v) => _players = v,
        () => _playersAt,
        (t) => _playersAt = t,
        PlayerApiService.queryPlayerRanking,
      );

  /// 玩家无尽模式前 300 榜单
  static Future<Object> hellRanking() => _cachedList<HellRankInfo>(
        () => _hell,
        (v) => _hell = v,
        () => _hellAt,
        (t) => _hellAt = t,
        PlayerApiService.queryHellRanking,
      );

  /// 通用榜单缓存逻辑：
  /// 命中且在 TTL 内 → 直接返回；
  /// 命中但已过期 → 先返回旧数据，同时后台静默刷新；
  /// 未命中 → 同步请求，成功后缓存。
  static Future<Object /* List<T> | QueryError */> _cachedList<T>(
    List<T>? Function() read,
    void Function(List<T> value) write,
    DateTime? Function() readAt,
    void Function(DateTime time) writeAt,
    Future<Object> Function() fetch,
  ) async {
    final cached = read();
    if (cached != null) {
      final at = readAt();
      if (at == null || DateTime.now().difference(at) > ttl) {
        // TTL 过期：后台静默刷新，界面先拿旧数据，不空转
        fetch().then((result) {
          if (result is List<T>) {
            write(result);
            writeAt(DateTime.now());
          }
        });
      }
      return cached;
    }
    final result = await fetch();
    if (result is List<T>) {
      write(result);
      writeAt(DateTime.now());
    }
    return result;
  }
}
