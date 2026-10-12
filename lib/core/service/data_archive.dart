import 'dart:convert';

enum ArchiveError {
  /// JSON 解析失败
  invalidJson,

  /// 结构错误
  invalid,

  /// 缺少版本信息
  missingVersion,

  /// 由更新版本的应用创建
  newerVersion,

  /// 未知版本号
  unsupportedVersion,

  /// 缺少数据内容
  missingData,
}

class DataArchiveException implements Exception {
  const DataArchiveException(this.error);

  final ArchiveError error;

  @override
  String toString() => 'DataArchiveException(${error.name})';
}

class ArchiveContents {
  ArchiveContents({
    required this.formatVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.userData,
    required this.userMeta,
    required this.appMeta,
    required this.itemRules,
    required this.gameTrack,
  });

  final int formatVersion;
  final DateTime? exportedAt;
  final String? appVersion;

  /// 用户数据
  final Map<int, dynamic>? userData;
  final Map<String, dynamic>? userMeta;
  final Map<String, dynamic>? appMeta;
  final Map<String, dynamic>? itemRules;
  final Map<String, dynamic>? gameTrack;

  int get userCount => userData?.length ?? 0;

  /// 游戏轨迹记录数
  int get trackRecordCount {
    if (gameTrack == null) return 0;
    var total = 0;
    for (final value in gameTrack!.values) {
      if (value is List) total += value.length;
    }
    return total;
  }
}

/// 单一 UTF-8 JSON 文件，schema v1：
/// ```json
/// {
///   "formatVersion": 1, "appVersion": "1.5.4", "exportedAt": "...",
///   "data": {
///     "userData":  { "0": {...} },        // int key → JSON string key
///     "userMeta":  { "currentUserId": 0, "nextUserId": 2 },
///     "appMeta":   { ...非 webdav* 键... },
///     "itemRules": { "rules": "[...]" },
///     "gameTrack": { "user_0": [...] }
///   }
/// }
/// ```
abstract final class DataArchive {
  static const int formatVersion = 1;

  /// 编码时从 app_meta 排除的键前缀
  static const String appConfigExcludePrefix = 'webdav';

  /// 把 5 个 Hive box 的快照编码为完整归档 map
  static Map<String, dynamic> encode({
    required Map<Object?, dynamic> userDataBox,
    required Map<Object?, dynamic> userMetaBox,
    required Map<Object?, dynamic> appMetaBox,
    required Map<Object?, dynamic> itemRulesBox,
    required Map<Object?, dynamic> gameTrackBox,
    DateTime? now,
    String? appVersion,
  }) {
    final userData = <String, dynamic>{};
    userDataBox.forEach((key, value) {
      if (key is int && value is Map) {
        userData['$key'] = value;
      }
    });

    final appMeta = <String, dynamic>{};
    appMetaBox.forEach((key, value) {
      if (key is String && !key.startsWith(appConfigExcludePrefix)) {
        appMeta[key] = value;
      }
    });

    final archive = <String, dynamic>{
      'formatVersion': formatVersion,
      'appName': 'gcc_next',
      'appVersion': ?appVersion,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'data': {
        'userData': userData,
        'userMeta': Map<String, dynamic>.from(userMetaBox),
        'appMeta': appMeta,
        'itemRules': Map<String, dynamic>.from(itemRulesBox),
        'gameTrack': Map<String, dynamic>.from(gameTrackBox),
      },
    };
    return _jsonSafe(archive) as Map<String, dynamic>;
  }

  static Object? _jsonSafe(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value),
      };
    }
    if (value is List) {
      return [for (final item in value) _jsonSafe(item)];
    }
    return value;
  }

  static ArchiveContents decode(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const DataArchiveException(ArchiveError.invalidJson);
    }
    if (decoded is! Map) {
      throw const DataArchiveException(ArchiveError.invalid);
    }
    final root = Map<String, dynamic>.from(decoded);

    final version = root['formatVersion'];
    if (version is! int) {
      throw const DataArchiveException(ArchiveError.missingVersion);
    }
    if (version > formatVersion) {
      throw const DataArchiveException(ArchiveError.newerVersion);
    }
    if (version < 1) {
      throw const DataArchiveException(ArchiveError.unsupportedVersion);
    }

    final rawData = root['data'];
    if (rawData is! Map) {
      throw const DataArchiveException(ArchiveError.missingData);
    }
    final data = Map<String, dynamic>.from(rawData);

    final userData = <int, dynamic>{};
    final rawUserData = data['userData'];
    if (rawUserData is Map) {
      for (final entry in Map<String, dynamic>.from(rawUserData).entries) {
        final key = int.tryParse(entry.key);
        if (key != null && entry.value is Map) {
          userData[key] = entry.value;
        }
      }
    }

    Map<String, dynamic>? userMeta;
    final rawUserMeta = data['userMeta'];
    if (rawUserMeta is Map) {
      userMeta = Map<String, dynamic>.from(rawUserMeta);
      final maxKey = userData.isEmpty ? -1 : userData.keys.reduce((a, b) => a > b ? a : b);
      final rawNext = userMeta[_metaNextUserIdKey];
      final next = rawNext is num
          ? rawNext.toInt()
          : int.tryParse(rawNext?.toString() ?? '');
      if (next != null) {
        userMeta[_metaNextUserIdKey] = next > maxKey + 1 ? next : maxKey + 1;
      }
    }

    return ArchiveContents(
      formatVersion: version,
      exportedAt: DateTime.tryParse(root['exportedAt']?.toString() ?? ''),
      appVersion: root['appVersion']?.toString(),
      userData: userData.isEmpty ? null : userData,
      userMeta: userMeta,
      appMeta: _parseSection(data['appMeta']),
      itemRules: _parseSection(data['itemRules']),
      gameTrack: _parseSection(data['gameTrack']),
    );
  }

  static const String _metaNextUserIdKey = 'nextUserId';

  static Map<String, dynamic>? _parseSection(Object? raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }
}
