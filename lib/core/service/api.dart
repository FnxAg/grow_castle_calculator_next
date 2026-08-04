import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of a successful player query.
class PlayerQueryResult {
  final int wave;
  final int seasonalScore;
  final String queryDate;
  final Map<String, dynamic> rawResult;

  const PlayerQueryResult({
    required this.wave,
    required this.seasonalScore,
    required this.queryDate,
    required this.rawResult,
  });
}

/// Result of a successful guild list query.
class GuildInfo {
  final int rank;
  final String name;
  final int score;

  const GuildInfo({
    required this.rank,
    required this.name,
    required this.score,
  });
}

/// A player on the season leaderboard.
class PlayerRankInfo {
  final int rank;
  final String name;
  final int score;

  const PlayerRankInfo({
    required this.rank,
    required this.name,
    required this.score,
  });
}

/// A player on the hell-mode leaderboard.
class HellRankInfo {
  final int rank;
  final String name;
  final int score;

  const HellRankInfo({
    required this.rank,
    required this.name,
    required this.score,
  });
}

/// A member of a guild.
class GuildMember {
  final String name;
  final int score;

  const GuildMember({required this.name, required this.score});
}

/// Simple wrapper for API error cases.
sealed class QueryError {
  const QueryError();
}

class NameNotFound extends QueryError {
  const NameNotFound();
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
  static const _s5 = '2C3A3E2C303170313028702F333E263A2D2C70';
  static const _s6 = '2C3A3E2C303170313028702F333E263A2D2C';
  static const _s7 = '2C3A3E2C30317031302870382A36333B2C';
  static const _s8 = '2C3A3E2C30317031302870382A36333B2C70';
  static const _s9 = '2C3A3E2C30317031302870373A3333';

  // ── URL builders ──────────────────────────────────────────────────────

  static String _buildPlayerNowUrl(String playerName) {
    return '${_d(_s0)}${_d(_s1)}${_d(_s2)}${_d(_s3)}${_d(_s4)}${_d(_s5)}${Uri.encodeComponent(playerName)}';
  }

  static String _buildGuildsUrl() {
    return '${_d(_s0)}${_d(_s1)}${_d(_s2)}${_d(_s3)}${_d(_s4)}${_d(_s7)}';
  }

  static String _buildPlayerRankingUrl() {
    return '${_d(_s0)}${_d(_s1)}${_d(_s2)}${_d(_s3)}${_d(_s4)}${_d(_s6)}';
  }

  static String _buildGuildDetailUrl(String guildName) {
    return '${_d(_s0)}${_d(_s1)}${_d(_s2)}${_d(_s3)}${_d(_s4)}${_d(_s8)}${Uri.encodeComponent(guildName)}';
  }

  static String _buildHellRankingUrl() {
    return '${_d(_s0)}${_d(_s1)}${_d(_s2)}${_d(_s3)}${_d(_s4)}${_d(_s9)}';
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Fetches player info for [playerName] from the current season.
  ///
  /// Returns a [PlayerQueryResult] on success, or a [QueryError] on failure.
  static Future<Object /* PlayerQueryResult | QueryError */> query(
      String playerName) async {
    return _queryPlayer(_buildPlayerNowUrl(playerName.trim()));
  }

  /// Common player query logic shared by now/last season endpoints.
  static Future<Object /* PlayerQueryResult | QueryError */> _queryPlayer(
      String url) async {
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return const NameNotFound();
      }

      // Explicit UTF-8 decoding.
      final rawBody = utf8.decode(response.bodyBytes);
      final decoded = json.decode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return const NameNotFound();
      }
      final body = decoded;

      // code — may come as int or String.
      final code = _parseInt(body['code']);
      if (code != 200) {
        return const NameNotFound();
      }

      final result = body['result'];
      if (result is! Map<String, dynamic>) {
        return const NameNotFound();
      }

      final list = result['list'];
      if (list is! List<dynamic> || list.isEmpty) {
        return const NameNotFound();
      }

      final player = list[0];
      if (player is! Map<String, dynamic>) {
        return const NameNotFound();
      }

      final wave = _parseInt(player['wave']);
      final score = _parseInt(player['score']);
      final lastOnline = (player['date'] as String?) ?? '';

      return PlayerQueryResult(
        wave: wave,
        seasonalScore: score,
        queryDate: lastOnline,
        rawResult: Map<String, dynamic>.from(result),
      );
    } on TimeoutException {
      return const TimeoutError();
    } on http.ClientException {
      return const NetworkError('Network connection failed');
    } catch (e) {
      return NetworkError(e.toString());
    }
  }

  /// Fetches the player leaderboard for the current season.
  ///
  /// Returns a list of [PlayerRankInfo] on success, or a [QueryError] on failure.
  static Future<Object /* List<PlayerRankInfo> | QueryError */> queryPlayerRanking() async {
    final uri = Uri.parse(_buildPlayerRankingUrl());

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return NetworkError('HTTP ${response.statusCode}');
      }

      final rawBody = utf8.decode(response.bodyBytes);
      final decoded = json.decode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return const NetworkError('Invalid response format');
      }
      final body = decoded;

      final code = _parseInt(body['code']);
      if (code != 200) {
        return NetworkError('API code: $code');
      }

      final result = body['result'];
      if (result is! Map<String, dynamic>) {
        return const NetworkError('Missing result');
      }

      final list = result['list'];
      if (list is! List<dynamic>) {
        return const NetworkError('Missing player list');
      }

      final players = <PlayerRankInfo>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        players.add(PlayerRankInfo(
          rank: _parseInt(item['rank']),
          name: (item['name'] as String?) ?? '',
          score: _parseInt(item['score']),
        ));
      }

      return players;
    } on TimeoutException {
      return const TimeoutError();
    } on http.ClientException {
      return const NetworkError('Network connection failed');
    } catch (e) {
      return NetworkError(e.toString());
    }
  }

  /// Fetches the hell-mode leaderboard for the current season.
  ///
  /// Returns a list of [HellRankInfo] on success, or a [QueryError] on failure.
  static Future<Object /* List<HellRankInfo> | QueryError */> queryHellRanking() async {
    final uri = Uri.parse(_buildHellRankingUrl());

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return NetworkError('HTTP ${response.statusCode}');
      }

      final rawBody = utf8.decode(response.bodyBytes);
      final decoded = json.decode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return const NetworkError('Invalid response format');
      }
      final body = decoded;

      final code = _parseInt(body['code']);
      if (code != 200) {
        return NetworkError('API code: $code');
      }

      final result = body['result'];
      if (result is! Map<String, dynamic>) {
        return const NetworkError('Missing result');
      }

      final list = result['list'];
      if (list is! List<dynamic>) {
        return const NetworkError('Missing player list');
      }

      final players = <HellRankInfo>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        players.add(HellRankInfo(
          rank: _parseInt(item['rank']),
          name: (item['name'] as String?) ?? '',
          score: _parseInt(item['score']),
        ));
      }

      return players;
    } on TimeoutException {
      return const TimeoutError();
    } on http.ClientException {
      return const NetworkError('Network connection failed');
    } catch (e) {
      return NetworkError(e.toString());
    }
  }

  /// Fetches the guild leaderboard for the current season.
  ///
  /// Returns a list of [GuildInfo] on success, or a [QueryError] on failure.
  static Future<Object /* List<GuildInfo> | QueryError */> queryGuilds() async {
    final uri = Uri.parse(_buildGuildsUrl());

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return NetworkError('HTTP ${response.statusCode}');
      }

      final rawBody = utf8.decode(response.bodyBytes);
      final decoded = json.decode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return const NetworkError('Invalid response format');
      }
      final body = decoded;

      final code = _parseInt(body['code']);
      if (code != 200) {
        return NetworkError('API code: $code');
      }

      final result = body['result'];
      if (result is! Map<String, dynamic>) {
        return const NetworkError('Missing result');
      }

      final list = result['list'];
      if (list is! List<dynamic>) {
        return const NetworkError('Missing guild list');
      }

      final guilds = <GuildInfo>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        guilds.add(GuildInfo(
          rank: _parseInt(item['rank']),
          name: (item['name'] as String?) ?? '',
          score: _parseInt(item['score']),
        ));
      }

      return guilds;
    } on TimeoutException {
      return const TimeoutError();
    } on http.ClientException {
      return const NetworkError('Network connection failed');
    } catch (e) {
      return NetworkError(e.toString());
    }
  }

  /// Fetches the member list for a specific guild.
  ///
  /// Returns a list of [GuildMember] sorted by score descending,
  /// or a [QueryError] on failure. Members with null names are excluded.
  static Future<Object /* List<GuildMember> | QueryError */> queryGuildDetail(
      String guildName) async {
    final uri = Uri.parse(_buildGuildDetailUrl(guildName.trim()));

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return NetworkError('HTTP ${response.statusCode}');
      }

      final rawBody = utf8.decode(response.bodyBytes);
      final decoded = json.decode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return const NetworkError('Invalid response format');
      }
      final body = decoded;

      final code = _parseInt(body['code']);
      if (code != 200) {
        return NetworkError('API code: $code');
      }

      final result = body['result'];
      if (result is! Map<String, dynamic>) {
        return const NetworkError('Missing result');
      }

      final list = result['list'];
      if (list is! List<dynamic>) {
        return const NetworkError('Missing member list');
      }

      final members = <GuildMember>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final name = item['name'];
        if (name == null) continue; // skip null names
        members.add(GuildMember(
          name: name.toString(),
          score: _parseInt(item['score']),
        ));
      }

      // Sort by score descending.
      members.sort((a, b) => b.score.compareTo(a.score));

      return members;
    } on TimeoutException {
      return const TimeoutError();
    } on http.ClientException {
      return const NetworkError('Network connection failed');
    } catch (e) {
      return NetworkError(e.toString());
    }
  }

  /// Formats the time elapsed since [rawDate] (ISO 8601 UTC).
  ///
  /// Returns e.g. "30s", "5min", "6h", "3d". Units are locale-independent.
  static String formatLastOnline(String rawDate, DateTime now) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate);
      final diff = now.difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}min ago';
      final secs = diff.inSeconds;
      return '${secs > 0 ? secs : 0}s ago';
    } catch (_) {
      return '';
    }
  }

  /// Parses [value] to int, handling both `int` and `String` representations.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}