/// 用户数据模型：纯数据类 + Hive 序列化 + schema 迁移。
///
/// 读写逻辑（持久化、切换用户、通知）在 [InfoStore]（user_info.dart）。
class UserData {
  UserData({
    required this.username,
    int? version,
    String? guild,
    List<int>? cardIds,
    Map<int, bool>? applyFlags,
    Map<int, String>? textValues,
    Map<int, String>? numberValues,
    Map<int, double>? unitGold,
    double? totalGold,
    int? wave,
    int? seasonWave,
    double? gp,    // Gold Power
    double? gpCN,  // 十里坡剑神指数
    bool? onlineQuery,
    int? infiniteColony,
    int? gameSpeed,
    int? chronoClass,
    bool? horn,
    bool? goldenHorn,
    int? devilHornSkip,
    bool? isGoldAutoBattle,
  })  : version = version ?? 1,
        guild = guild ?? '',
        cardIds = cardIds ?? [1, 2],
        applyFlags = applyFlags ?? {1: true, 2: true},
        textValues = textValues ?? {},
        numberValues = numberValues ?? {},
        unitGold = unitGold ?? {},
        totalGold = totalGold ?? 0.0,
        wave = wave ?? 1,
        seasonWave = seasonWave ?? 0,
        gp = gp ?? 0,
        gpCN = gpCN ?? 0,
        onlineQuery = onlineQuery ?? false,
        infiniteColony = infiniteColony ?? 0,
        gameSpeed = gameSpeed ?? 0,
        chronoClass = chronoClass ?? 0,
        horn = horn ?? false,
        goldenHorn = goldenHorn ?? false,
        devilHornSkip = devilHornSkip ?? 1,
        isGoldAutoBattle = isGoldAutoBattle ?? true;

  String username;
  String guild;
  List<int> cardIds;
  Map<int, bool> applyFlags;
  Map<int, String> textValues;
  Map<int, String> numberValues;
  Map<int, double> unitGold;
  double totalGold;
  int wave;
  int seasonWave;
  double gp;    // Gold Power
  double gpCN;  // 十里坡剑神指数
  bool onlineQuery;
  int infiniteColony;
  /// 跳波状态（wave_status_page 持久化于 data 字段）
  /// 游戏速度下标（0=2速 / 1=2速+10广 / 2=3速）
  int gameSpeed;
  /// 闹钟转职下标（0=白 / 1=黄 / 2=蓝）
  int chronoClass;
  /// 10%角
  bool horn;
  /// 30%角
  bool goldenHorn;
  /// 恶魔号角跳波数（1=无）
  int devilHornSkip;
  /// 挂机类型（true=金挂）
  bool isGoldAutoBattle;
  /// 数据 schema 版本：结构变更时递增并在 migrate 里补迁移逻辑
  int version;

  /// 当前 schema 版本（结构变更时 +1）
  static const int currentVersion = 1;

  /// 判断原始数据是否低于当前 schema 版本，需要迁移
  static bool isOutdated(Map<dynamic, dynamic> map) =>
      _asInt(map['version'], 1) < currentVersion;

  /// 逐级迁移原始数据到当前版本；已是最新时原样返回
  static Map<dynamic, dynamic> migrate(Map<dynamic, dynamic> raw) {
    var map = Map<String, dynamic>.from(raw);
    var v = _asInt(map['version'], 1);
    while (v < currentVersion) {
      switch (v) {
        case 1:
          // v1 -> v2 示例：补默认字段 / 重算派生值 / 字段改名
          break;
      }
      v++;
    }
    map['version'] = v;
    return map;
  }

  factory UserData.fromMap(Map<dynamic, dynamic> map) {
    final info = (map['info'] is Map)
        ? Map<String, dynamic>.from(map['info'] as Map)
        : const <String, dynamic>{};
    final data = (map['data'] is Map)
        ? Map<String, dynamic>.from(map['data'] as Map)
        : const <String, dynamic>{};
    final setting = (map['setting'] is Map)
        ? Map<String, dynamic>.from(map['setting'] as Map)
        : const <String, dynamic>{};

    // 所有字段读时兜底：缺失或类型不符都回退默认值，保证 fromMap 永不抛异常
    return UserData(
      version: _asInt(map['version'], 1),
      username: map['username']?.toString() ?? 'default',
      guild: map['guild']?.toString() ?? '',
      cardIds: _castCardIds(info['cardIds']),
      applyFlags: _castIntKeyBoolMap(info['applyFlags']),
      textValues: _castIntKeyStringMap(info['textValues']),
      numberValues: _castIntKeyStringMap(info['numberValues']),
      unitGold: _castIntKeyDoubleMap(data['unitGold']),
      totalGold: _asDouble(data['totalGold'], 0.0),
      wave: _asInt(data['wave'], 1),
      seasonWave: _asInt(data['seasonWave'], 0),
      gp: _asDouble(data['gp'], 0.0),
      gpCN: _asDouble(data['gpCN'], 0.0),
      onlineQuery: _asBool(setting['onlineQuery'], false),
      infiniteColony: _asInt(data['infiniteColony'], 0),
      gameSpeed: _asInt(data['gameSpeed'], 0),
      chronoClass: _asInt(data['chronoClass'], 0),
      horn: _asBool(data['horn'], false),
      goldenHorn: _asBool(data['goldenHorn'], false),
      devilHornSkip: _asInt(data['devilHornSkip'], 1),
      isGoldAutoBattle: _asBool(data['isGoldAutoBattle'], true),
    );
  }

  UserData clone() {
    return UserData(
      username: username,
      version: version,
      cardIds: List<int>.from(cardIds),
      applyFlags: Map<int, bool>.from(applyFlags),
      textValues: Map<int, String>.from(textValues),
      numberValues: Map<int, String>.from(numberValues),
      unitGold: Map<int, double>.from(unitGold),
      totalGold: totalGold,
      wave: wave,
      seasonWave: seasonWave,
      gp: gp,
      gpCN: gpCN,
      onlineQuery: onlineQuery,
      infiniteColony: infiniteColony,
      gameSpeed: gameSpeed,
      chronoClass: chronoClass,
      horn: horn,
      goldenHorn: goldenHorn,
      devilHornSkip: devilHornSkip,
      isGoldAutoBattle: isGoldAutoBattle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guild': guild,
      'username': username,
      'version': version,
      'info': {
        'cardIds': List<int>.from(cardIds),
        'applyFlags': Map<int, bool>.from(applyFlags),
        'textValues': Map<int, String>.from(textValues),
        'numberValues': Map<int, String>.from(numberValues),
      },
      'data': {
        'unitGold': Map<int, double>.from(unitGold),
        'totalGold': totalGold,
        'wave': wave,
        'seasonWave': seasonWave,
        'gp': gp,
        'gpCN': gpCN,
        'infiniteColony': infiniteColony,
        // 跳波状态（wave_status_page）
        'gameSpeed': gameSpeed,
        'chronoClass': chronoClass,
        'horn': horn,
        'goldenHorn': goldenHorn,
        'devilHornSkip': devilHornSkip,
        'isGoldAutoBattle': isGoldAutoBattle,
      },
      'setting': {
        'onlineQuery': onlineQuery,
      },
    };
  }

  static Map<int, bool> _castIntKeyBoolMap(Object? value) {
    final result = <int, bool>{};
    if (value is Map) {
      for (final entry in value.entries) {
        final key = int.tryParse(entry.key.toString());
        if (key != null) {
          result[key] = entry.value == true;
        }
      }
    }
    return result;
  }

  static Map<int, String> _castIntKeyStringMap(Object? value) {
    final result = <int, String>{};
    if (value is Map) {
      for (final entry in value.entries) {
        final key = int.tryParse(entry.key.toString());
        if (key != null) {
          result[key] = entry.value?.toString() ?? '';
        }
      }
    }
    return result;
  }

  static Map<int, double> _castIntKeyDoubleMap(Object? value) {
    final result = <int, double>{};
    if (value is Map) {
      for (final entry in value.entries) {
        final key = int.tryParse(entry.key.toString());
        if (key != null) {
          result[key] = (entry.value as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return result;
  }

  static int _asInt(Object? value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _asDouble(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _asBool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static List<int> _castCardIds(Object? value) {
    if (value is List) {
      final result = <int>[];
      for (final entry in value) {
        final n = entry is num ? entry.toInt() : int.tryParse(entry.toString());
        if (n != null) {
          result.add(n);
        }
      }
      return result;
    }
    return const [1, 2];
  }
}

/// 默认用户数据
///
/// 0 是固定分配给默认用户的编号；用户名作为 key 存储。
const Map<int, Map<String, dynamic>> defaultUserData = {
  0: {
    'username': 'default',
    'version': UserData.currentVersion,
    'guild': '',
    'info': {
      'cardIds': [1, 2],
      'applyFlags': {1: true, 2: true},
      'textValues': {},
      'numberValues': {},
    },
    'data': {
      'unitGold': {},
      'totalGold': 0,
      'wave': 1,
      'seasonWave': 0,
      'gp': 0,
      'gpCN': 0,
      'infiniteColony': 0,
      'gameSpeed': 0,
      'chronoClass': 0,
      'horn': false,
      'goldenHorn': false,
      'devilHornSkip': 1,
      'isGoldAutoBattle': true,
    },
    'setting': {
      'onlineQuery': false,
    },
  },
};
