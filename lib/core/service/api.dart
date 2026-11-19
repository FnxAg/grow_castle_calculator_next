import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:grow_castle_calculator_next/core/service/api/api_guild.dart'
    as guild_api;
import 'package:grow_castle_calculator_next/core/service/api/api_leaderboard.dart'
    as leaderboard_api;
import 'package:grow_castle_calculator_next/core/service/api/api_player.dart'
    as player_api;
import 'package:grow_castle_calculator_next/core/service/api_client.dart';

enum Api { lbPlayer, lbGuild, lbHell, player, guild, playerWph }

class SeasonRange {
  final DateTime? start;
  final DateTime? end;

  const SeasonRange({this.start, this.end});
}

class SeasonQueryResult<T> {
  final List<T> items;
  final SeasonRange season;

  const SeasonQueryResult({required this.items, required this.season});
}

/// Result of a successful player query.
class PlayerQueryResult {
  final int wave;
  final int seasonalScore;
  final String queryDate;
  final SeasonRange season;

  const PlayerQueryResult({
    required this.wave,
    required this.seasonalScore,
    required this.queryDate,
    required this.season,
  });
}

class RankInfo {
  final int rank;
  final String name;
  final int score;
  final int? gapPrev;
  final String? prevName;
  final int? gapNext;
  final String? nextName;

  const RankInfo({
    required this.rank,
    required this.name,
    required this.score,
    this.gapPrev,
    this.prevName,
    this.gapNext,
    this.nextName,
  });
}

/// A member of a guild.
class GuildMember {
  final String name;
  final int score;

  const GuildMember({required this.name, required this.score});
}

/// 玩家在某赛季的每小时波速快照集合（来自第三方 API）。
///
/// [wphs] 保持接口返回顺序（快照 id 降序，即赛季内最新在前），
/// 缺失的波速记录以 null 表示。
class SeasonWphGroup {
  final String season;
  final List<int?> wphs;

  const SeasonWphGroup({required this.season, required this.wphs});
}

/// Simple wrapper for API error cases.
sealed class QueryError {
  const QueryError();
}

class NameNotFound extends QueryError {
  const NameNotFound();
}

class EmptyData extends QueryError {
  const EmptyData();
}

class NetworkError extends QueryError {
  final String message;
  const NetworkError(this.message);
}

class TimeoutError extends QueryError {
  const TimeoutError();
}

/// Service that fetches player data from the Grow Castle season API.
///
/// The endpoint URL is assembled from parts at runtime so it is never
/// stored as a single plain-text literal.
class PlayerApiService {
  PlayerApiService._();

  static const Duration _timeout = Duration(seconds: 10);

  // ── URL decoding ──────────────────────────────────────────────────────

  static const _xk = 0x5F;

  /// Decodes a hex string that was XOR-obfuscated with [_xk].
  static String _d(String hex) {
    final chars = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      chars.add(int.parse(hex.substring(i, i + 2), radix: 16) ^ _xk);
    }
    return String.fromCharCodes(chars);
  }

  // ── Obfuscated URL segments (XOR hex) ─────────────────────────────────

  static const _s0 = '372B2B2F2C657070';
  static const _s1 = '2D3E3031383E323A2C';
  static const _s2 = '713C303270';
  static const _s3 = '382D30283C3E2C2B333A70';
  static const _s4 = '2D3A2C2B3E2F3670';
  static const _s5 = '2C3A3E2C303170';
  static const _s6 = '313028';
  static const _s7 = '702F333E263A2D2C';
  static const _s8 = '70382A36333B2C';
  static const _s9 = '70373A3333';

  // ── URL builders ──────────────────────────────────────────────────────

  static String get _officialBase =>
      '${_d(_s0)}${_d(_s1)}${_d(_s2)}${_d(_s3)}${_d(_s4)}';

  /// 接口地址；[name] 为玩家名/公会名
  static String _url(
    Api api, {
    DateTime? seasonDate,
    String? name,
    String? baseUrl,
  }) {
    final suffix = name == null ? '' : '/${Uri.encodeComponent(name)}';
    final seasonBase = '$_officialBase${_d(_s5)}${_seasonSegment(seasonDate)}';
    return switch (api) {
      Api.playerWph => '${_trimSlash(baseUrl!)}/season/all/players$suffix',
      Api.lbPlayer || Api.player => '$seasonBase${_d(_s7)}$suffix',
      Api.lbGuild || Api.guild => '$seasonBase${_d(_s8)}$suffix',
      Api.lbHell => '$seasonBase${_d(_s9)}$suffix',
    };
  }

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// 赛季路径段：默认 `now`，历史查询为 `yyyyMMdd`
  static String _seasonSegment(DateTime? date) {
    if (date == null) return _d(_s6);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}';
  }

  static Future<Object> query(String playerName) => _query(
    Api.player,
    _parsePlayer,
    name: playerName.trim(),
    nameNotFound: true,
  );

  static Future<Object> queryPlayerRanking({DateTime? seasonDate}) =>
      _query(Api.lbPlayer, _parseLeaderboard, seasonDate: seasonDate);

  static Future<Object> queryHellRanking({DateTime? seasonDate}) =>
      _query(Api.lbHell, _parseLeaderboard, seasonDate: seasonDate);

  static Future<Object> queryGuildRanking({DateTime? seasonDate}) =>
      _query(Api.lbGuild, _parseLeaderboard, seasonDate: seasonDate);

  static Future<Object> queryGuildDetail(
    String guildName, {
    DateTime? seasonDate,
  }) => _query(
    Api.guild,
    _parseGuildDetail,
    seasonDate: seasonDate,
    name: guildName.trim(),
  );

  // ── Request / parse ────────────────────────────────────────────────────

  /// 发起 GET 并解析；网络/解析异常统一映射为 [QueryError]
  static Future<Object> _get(
    Uri uri,
    Object Function(Object? json) parse, {
    Options? options,
    Object Function(int status)? onHttpError,
  }) async {
    try {
      final response = await ApiClient.get(
        uri,
        options: options,
      ).timeout(_timeout);
      final status = response.statusCode ?? 0;
      if (status != 200) {
        return onHttpError?.call(status) ?? NetworkError('HTTP $status');
      }
      return parse(json.decode(response.data ?? ''));
    } on TimeoutException {
      return const TimeoutError();
    } catch (e) {
      return _mapNetworkError(e);
    }
  }

  /// 官方接口：请求、校验 code 并解析
  static Future<Object> _query(
    Api api,
    Object Function(Map<String, dynamic> json) parse, {
    DateTime? seasonDate,
    String? name,
    bool nameNotFound = false,
  }) {
    final uri = Uri.parse(_url(api, seasonDate: seasonDate, name: name));
    return _get(uri, (json) {
      if (json is! Map<String, dynamic>) {
        return nameNotFound
            ? const NameNotFound()
            : const NetworkError('Invalid response format');
      }
      final code = _readCode(json);
      if (code != null && code != 200) {
        return nameNotFound
            ? const NameNotFound()
            : NetworkError('API code: $code');
      }
      final result = parse(json);
      if (seasonDate != null &&
          result is SeasonQueryResult<Object?> &&
          result.items.isEmpty) {
        return const EmptyData();
      }
      return result;
    }, onHttpError: nameNotFound ? (_) => const NameNotFound() : null);
  }

  static Object _parseLeaderboard(Map<String, dynamic> json) {
    final parsed = leaderboard_api.ApiLeaderboardResponse.fromJson(json);
    return SeasonQueryResult(
      items: _leaderboardRanks(parsed.result.list),
      season: _seasonRange(
        parsed.result.date.seasonStart,
        parsed.result.date.seasonEnd,
      ),
    );
  }

  static Object _parsePlayer(Map<String, dynamic> json) {
    final parsed = player_api.ApiPlayerResponse.fromJson(json);
    if (parsed.result.list.isEmpty) return const NameNotFound();
    final player = parsed.result.list.first;
    return PlayerQueryResult(
      wave: player.wave ?? 0,
      seasonalScore: player.score,
      queryDate: player.lastOnline?.toIso8601String() ?? '',
      season: _seasonRange(
        parsed.result.date.seasonStart,
        parsed.result.date.seasonEnd,
      ),
    );
  }

  static Object _parseGuildDetail(Map<String, dynamic> json) {
    final parsed = guild_api.ApiGuildResponse.fromJson(json);
    final members = <GuildMember>[
      for (final item in parsed.result.list)
        if (item.username != null && item.username!.isNotEmpty)
          GuildMember(name: item.username!, score: item.score),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return SeasonQueryResult(
      items: members,
      season: _seasonRange(
        parsed.result.date.seasonStart,
        parsed.result.date.seasonEnd,
      ),
    );
  }

  /// Fetches the player's per-season wph history from the custom third-party
  /// API (`{baseUrl}/season/all/players/{name}`).
  ///
  /// The response is a list of hourly snapshots spanning multiple seasons;
  /// only `season` and `wph` are used, snapshots are grouped by season
  /// (keeping the API's newest-first order within each season). Returns the
  /// seasons ordered newest first, or a [QueryError]. Player without
  /// third-party data (404/empty list) yields an empty list.
  static Future<Object> queryPlayerWphHistory(
    String playerName,
    String baseUrl, {
    required String username,
    required String guild,
  }) async {
    final options = await ApiClient.thirdPartyOptions(
      baseUrl,
      username: username,
      guild: guild,
    );
    return _get(
      Uri.parse(_url(Api.playerWph, baseUrl: baseUrl, name: playerName.trim())),
      (json) {
        if (json is! List<dynamic>) {
          return const NetworkError('Invalid response format');
        }
        // 按赛季分组（保持接口快照顺序），只保留 season 与 wph 两个字段
        final bySeason = <String, List<int?>>{};
        for (final item in json) {
          if (item is! Map<String, dynamic>) continue;
          final season = (item['season'] as String?) ?? '';
          if (season.isEmpty) continue;
          final wphValue = item['wph'];
          bySeason
              .putIfAbsent(season, () => <int?>[])
              .add(wphValue is num ? wphValue.toInt() : null);
        }
        return bySeason.entries
            .map((e) => SeasonWphGroup(season: e.key, wphs: e.value))
            .toList()
          ..sort((a, b) => b.season.compareTo(a.season));
      },
      options: options,
      onHttpError: (status) => status == 404
          ? const <SeasonWphGroup>[]
          : NetworkError('HTTP $status'),
    );
  }

  static String formatLastOnline(String rawDate, DateTime now) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate);
      final diff = now.difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}min';
      final secs = diff.inSeconds;
      return '${secs > 0 ? secs : 0}s';
    } catch (_) {
      return '';
    }
  }

  static String? formatSeasonRemaining(DateTime end, DateTime now) {
    final diff = end.difference(now);
    if (diff.isNegative) return null;
    return '${diff.inDays}d ${diff.inHours % 24}h ${diff.inMinutes % 60}m';
  }

  /// 读取响应 code；兼容数字与字符串
  static int? _readCode(Map<String, dynamic> json) {
    final value = json['code'];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 请求阶段的异常映射为 [QueryError]
  static QueryError _mapNetworkError(Object e) {
    if (e is DioException) {
      final type = e.type;
      if (type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.receiveTimeout) {
        return const TimeoutError();
      }
      return const NetworkError('Network connection failed');
    }
    if (e is FormatException || e is TypeError) {
      return const NetworkError('Invalid response format');
    }
    return NetworkError(e.toString());
  }

  /// 榜单接口已按名次排序，不再重排；相邻分差按返回顺序计算
  static List<RankInfo> _leaderboardRanks(
    List<leaderboard_api.ApiResponseResultList> list,
  ) {
    return _withGaps([
      for (final item in list)
        RankInfo(rank: item.rank, name: item.name, score: item.score),
    ]);
  }

  /// 按顺序补充相邻名次的分差
  static List<RankInfo> _withGaps(List<RankInfo> items) {
    return <RankInfo>[
      for (var i = 0; i < items.length; i++)
        RankInfo(
          rank: items[i].rank,
          name: items[i].name,
          score: items[i].score,
          gapPrev: i > 0 ? items[i - 1].score - items[i].score : null,
          prevName: i > 0 ? items[i - 1].name : null,
          gapNext: i < items.length - 1
              ? items[i].score - items[i + 1].score
              : null,
          nextName: i < items.length - 1 ? items[i + 1].name : null,
        ),
    ];
  }

  static SeasonRange _seasonRange(DateTime start, DateTime end) => SeasonRange(
    start: _toLocalSeasonTime(start),
    end: _toLocalSeasonTime(end),
  );

  /// 接口时间不带时区时按 UTC 处理
  static DateTime _toLocalSeasonTime(DateTime value) {
    if (value.isUtc) return value.toLocal();
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    ).toLocal();
  }
}
