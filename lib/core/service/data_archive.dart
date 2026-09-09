import 'dart:convert';

/// 数据归档异常：message 为面向用户的中文提示
class DataArchiveException implements Exception {
  DataArchiveException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 归档解析产物：各 section 均为「可直接写入 Hive box」的形态。
///
/// section 为 null 表示归档中缺失该节（旧格式/被裁剪），恢复时应保留本地数据。
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

  /// 用户数据：key 已从 JSON 字符串还原为 int；
  /// 值为 UserData.toMap() 形态（嵌套 int-key map 经 JSON 后为字符串 key，
  /// 由 UserData.fromMap 的 int.tryParse 兜底解析，见 user_data.dart）
  final Map<int, dynamic>? userData;
  final Map<String, dynamic>? userMeta;
  final Map<String, dynamic>? appMeta;
  final Map<String, dynamic>? itemRules;
  final Map<String, dynamic>? gameTrack;

  int get userCount => userData?.length ?? 0;

  /// 游戏轨迹记录数（game_track 各 `user_<id>` 键下 List 的长度之和）
  int get trackRecordCount {
    if (gameTrack == null) return 0;
    var total = 0;
    for (final value in gameTrack!.values) {
      if (value is List) total += value.length;
    }
    return total;
  }
}

/// 全量数据归档的编解码（纯逻辑，不触碰 Hive/文件/网络）。
///
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

  /// 编码时从 app_meta 排除的键前缀：WebDAV 配置（含云端凭据）不进备份文件
  static const String appConfigExcludePrefix = 'webdav';

  /// 把 5 个 Hive box 的快照编码为完整归档 map。
  /// [now] 与 [appVersion] 可注入便于测试。
  static Map<String, dynamic> encode({
    required Map<Object?, dynamic> userDataBox,
    required Map<Object?, dynamic> userMetaBox,
    required Map<Object?, dynamic> appMetaBox,
    required Map<Object?, dynamic> itemRulesBox,
    required Map<Object?, dynamic> gameTrackBox,
    DateTime? now,
    String? appVersion,
  }) {
    // user_data:仅收 int key 且值为 Map 的条目（与 InfoStore._loadFromHive 的
    // 验收条件一致），key 显式字符串化
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
    // JSON 编码仅接受字符串 key;Hive 内嵌的 int-key map(如 unitGold/applyFlags)
    // 在归档层就逐层字符串化,保证整档可直接 jsonEncode
    return _jsonSafe(archive) as Map<String, dynamic>;
  }

  /// 逐层把 map 的 key 转成字符串(值递归处理),其余类型原样返回
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

  /// 解析归档 JSON 文本；损坏/版本过新时抛 [DataArchiveException]。
  static ArchiveContents decode(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw DataArchiveException('不是有效的备份文件（JSON 解析失败）');
    }
    if (decoded is! Map) {
      throw DataArchiveException('不是有效的备份文件');
    }
    final root = Map<String, dynamic>.from(decoded);

    final version = root['formatVersion'];
    if (version is! int) {
      throw DataArchiveException('不是有效的备份文件（缺少版本信息）');
    }
    if (version > formatVersion) {
      throw DataArchiveException(
        '该备份由更新版本的应用创建，请先升级应用后再导入',
      );
    }
    if (version < 1) {
      throw DataArchiveException('不支持该备份文件版本');
    }

    final rawData = root['data'];
    if (rawData is! Map) {
      throw DataArchiveException('不是有效的备份文件（缺少数据内容）');
    }
    final data = Map<String, dynamic>.from(rawData);

    // user_data:JSON key 是字符串,顶层还原为 int;解析失败/非 Map 值跳过
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

    // user_meta:currentUserId/nextUserId 类型兜底;
    // nextUserId 防御性抬升,防止脏归档导致新用户 id 与现有用户重叠
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

  /// 解析一节 JSON map;不是 Map 时返回 null(该节缺失)
  static Map<String, dynamic>? _parseSection(Object? raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }
}
