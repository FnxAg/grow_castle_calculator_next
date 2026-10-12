/// 用户数据模型：不可变数据类 + Hive 序列化 + schema 迁移
library;

import 'package:flutter/foundation.dart';

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
    double? gp,
    double? gpCN,
    bool? onlineQuery,
    int? infiniteColony,
    int? gameSpeed,
    int? chronoClass,
    bool? horn,
    bool? goldenHorn,
    int? devilHornSkip,
    bool? isGoldAutoBattle,
    double? gabTime,
    double? gabBonus,
    double? tabTime,
    int? icCooldownSkill,
    int? icGoldSkill,
    bool? equipWheel,
    bool? equipWhip,
    bool? seasonColony,
    bool? goldenTree,
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
        isGoldAutoBattle = isGoldAutoBattle ?? true,
        gabTime = gabTime ?? 0.0,
        gabBonus = gabBonus ?? 0.0,
        tabTime = tabTime ?? 0.0,
        icCooldownSkill = icCooldownSkill ?? 0,
        icGoldSkill = icGoldSkill ?? 0,
        equipWheel = equipWheel ?? false,
        equipWhip = equipWhip ?? false,
        seasonColony = seasonColony ?? false,
        goldenTree = goldenTree ?? false;

  final String username;
  final String guild;
  final List<int> cardIds;
  final Map<int, bool> applyFlags;
  final Map<int, String> textValues;
  final Map<int, String> numberValues;
  final Map<int, double> unitGold;
  final double totalGold;
  final int wave;
  final int seasonWave;
  final double gp;
  final double gpCN;
  final bool onlineQuery;
  final int infiniteColony;
  final int gameSpeed;
  final int chronoClass;
  final bool horn;
  final bool goldenHorn;
  final int devilHornSkip;
  final bool isGoldAutoBattle;
  final double gabTime;
  final double gabBonus;
  final double tabTime;
  final int icCooldownSkill;
  final int icGoldSkill;
  final bool equipWheel;
  final bool equipWhip;
  final bool seasonColony;
  final bool goldenTree;
  final int version;

  static const int currentVersion = 1;

  static bool isOutdated(Map<dynamic, dynamic> map) =>
      _asInt(map['version'], 1) < currentVersion;

  /// 逐级迁移原始数据到当前版本，已是最新时原样返回
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

    // 所有字段读时兜底
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
      gabTime: _asDouble(data['gabTime'], 0.0),
      gabBonus: _asDouble(data['gabBonus'], 0.0),
      tabTime: _asDouble(data['tabTime'], 0.0),
      icCooldownSkill: _asInt(data['icCooldown'], 0),
      icGoldSkill: _asInt(data['icGold'], 0),
      equipWheel: _asBool(data['equipWheel'], false),
      equipWhip: _asBool(data['equipWhip'], false),
      seasonColony: _asBool(data['seasonColony'], false),
      goldenTree: _asBool(data['goldenTree'], false),
    );
  }

  /// 按字段替换产生新实例
  UserData copyWith({
    String? username,
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
    double? gp,
    double? gpCN,
    bool? onlineQuery,
    int? infiniteColony,
    int? gameSpeed,
    int? chronoClass,
    bool? horn,
    bool? goldenHorn,
    int? devilHornSkip,
    bool? isGoldAutoBattle,
    double? gabTime,
    double? gabBonus,
    double? tabTime,
    int? icCooldownSkill,
    int? icGoldSkill,
    bool? equipWheel,
    bool? equipWhip,
    bool? seasonColony,
    bool? goldenTree,
  }) {
    return UserData(
      username: username ?? this.username,
      version: version ?? this.version,
      guild: guild ?? this.guild,
      cardIds: cardIds ?? this.cardIds,
      applyFlags: applyFlags ?? this.applyFlags,
      textValues: textValues ?? this.textValues,
      numberValues: numberValues ?? this.numberValues,
      unitGold: unitGold ?? this.unitGold,
      totalGold: totalGold ?? this.totalGold,
      wave: wave ?? this.wave,
      seasonWave: seasonWave ?? this.seasonWave,
      gp: gp ?? this.gp,
      gpCN: gpCN ?? this.gpCN,
      onlineQuery: onlineQuery ?? this.onlineQuery,
      infiniteColony: infiniteColony ?? this.infiniteColony,
      gameSpeed: gameSpeed ?? this.gameSpeed,
      chronoClass: chronoClass ?? this.chronoClass,
      horn: horn ?? this.horn,
      goldenHorn: goldenHorn ?? this.goldenHorn,
      devilHornSkip: devilHornSkip ?? this.devilHornSkip,
      isGoldAutoBattle: isGoldAutoBattle ?? this.isGoldAutoBattle,
      gabTime: gabTime ?? this.gabTime,
      gabBonus: gabBonus ?? this.gabBonus,
      tabTime: tabTime ?? this.tabTime,
      icCooldownSkill: icCooldownSkill ?? this.icCooldownSkill,
      icGoldSkill: icGoldSkill ?? this.icGoldSkill,
      equipWheel: equipWheel ?? this.equipWheel,
      equipWhip: equipWhip ?? this.equipWhip,
      seasonColony: seasonColony ?? this.seasonColony,
      goldenTree: goldenTree ?? this.goldenTree,
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
        'gameSpeed': gameSpeed,
        'chronoClass': chronoClass,
        'horn': horn,
        'goldenHorn': goldenHorn,
        'devilHornSkip': devilHornSkip,
        'isGoldAutoBattle': isGoldAutoBattle,
        'gabTime': gabTime,
        'gabBonus': gabBonus,
        'tabTime': tabTime,
        'icCooldown': icCooldownSkill,
        'icGold': icGoldSkill,
        'equipWheel': equipWheel,
        'equipWhip': equipWhip,
        'seasonColony': seasonColony,
        'goldenTree': goldenTree,
      },
      'setting': {
        'onlineQuery': onlineQuery,
      },
    };
  }

  /// 按值深比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.username == username &&
        other.version == version &&
        other.guild == guild &&
        listEquals(other.cardIds, cardIds) &&
        mapEquals(other.applyFlags, applyFlags) &&
        mapEquals(other.textValues, textValues) &&
        mapEquals(other.numberValues, numberValues) &&
        mapEquals(other.unitGold, unitGold) &&
        other.totalGold == totalGold &&
        other.wave == wave &&
        other.seasonWave == seasonWave &&
        other.gp == gp &&
        other.gpCN == gpCN &&
        other.onlineQuery == onlineQuery &&
        other.infiniteColony == infiniteColony &&
        other.gameSpeed == gameSpeed &&
        other.chronoClass == chronoClass &&
        other.horn == horn &&
        other.goldenHorn == goldenHorn &&
        other.devilHornSkip == devilHornSkip &&
        other.isGoldAutoBattle == isGoldAutoBattle &&
        other.gabTime == gabTime &&
        other.gabBonus == gabBonus &&
        other.tabTime == tabTime &&
        other.icCooldownSkill == icCooldownSkill &&
        other.icGoldSkill == icGoldSkill &&
        other.equipWheel == equipWheel &&
        other.equipWhip == equipWhip &&
        other.seasonColony == seasonColony &&
        other.goldenTree == goldenTree;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        username,
        version,
        guild,
        Object.hashAll(cardIds),
        _mapHash(applyFlags),
        _mapHash(textValues),
        _mapHash(numberValues),
        _mapHash(unitGold),
        totalGold,
        wave,
        seasonWave,
        gp,
        gpCN,
        onlineQuery,
        infiniteColony,
        gameSpeed,
        chronoClass,
        horn,
        goldenHorn,
        devilHornSkip,
        isGoldAutoBattle,
        gabTime,
        gabBonus,
        tabTime,
        icCooldownSkill,
        icGoldSkill,
        equipWheel,
        equipWhip,
        seasonColony,
        goldenTree,
      ]);

  /// 与 mapEquals 的逐键值语义保持一致，无序哈希每个 (key, value) 对
  static int _mapHash(Map<Object?, Object?> map) => Object.hashAllUnordered(
        map.entries.map((e) => Object.hash(e.key, e.value)),
      );

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
/// 0 是固定分配给默认用户的编号
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
      'gabTime': 0.0,
      'gabBonus': 0.0,
      'tabTime': 0.0,
      'icCooldown': 0,
      'icGold': 0,
      'equipWheel': false,
      'equipWhip': false,
      'seasonColony': false,
      'goldenTree': false,
    },
    'setting': {
      'onlineQuery': false,
    },
  },
};
