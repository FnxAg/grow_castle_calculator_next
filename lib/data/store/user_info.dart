import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InfoStore {
  static const String _usersBoxName = 'user_data';
  static const String _metaBoxName = 'user_meta';
  static const String _metaCurrentUserIdKey = 'currentUserId';
  static const String _metaNextUserIdKey = 'nextUserId';

  final Box _usersBox = Hive.box(_usersBoxName);
  final Box _metaBox = Hive.box(_metaBoxName);

  final Map<int, UserData> _data = {};
  final Map<String, int> _userIds = {};
  int _nextUserId = 0;
  int _currentUserId = 0;
  String _currentUser = 'default';

  List<int> _cardIds = [];
  Map<int, bool> _applyFlags = {};
  Map<int, String> _textValues = {};
  Map<int, String> _numberValues = {};
  Map<int, double> _unitGold = {};
  double _totalGold = 0;
  int _wave = 1;
  int _seasonWave = 0;
  double _gp = 0;
  double _gpCN = 0;

  /// 延迟落盘定时器：输入热路径合并写盘
  Timer? _saveDebounce;

  /// 当前用户总金币变化通知（供 UI 实时刷新）
  final ValueNotifier<double> totalGoldNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> gpNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> gpCNNotifier = ValueNotifier<double>(0);

  /// 卡片列表结构变化通知（新增/删除/排序），供卡片列表重建
  final ValueNotifier<int> cardIdsNotifier = ValueNotifier<int>(0);

  /// 默认用户数据
  static const Map<int, Map<String, dynamic>> defaultUserData = {
    0: {  // 给一个用户分配的编号
      'username': 'default',  // 将用户名作为 key 存储
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
      }
    }
  };

  InfoStore() {
    _loadFromHive();
  }

  /// 获取当前用户资料
  Map<String, dynamic> get currentUserData => _data[_currentUserId]?.toMap() ?? defaultUserData[0]!;

  /// 获取当前用户名称
  String getCurrentUser() => _currentUser;

  /// 获取所有用户名称
  List<String> getAllUsernames() => _userIds.keys.toList();

  void _loadFromHive() {
    _data.clear();
    _userIds.clear();

    for (final key in _usersBox.keys) {
      final rawValue = _usersBox.get(key);
      if (key is int && rawValue is Map) {
        final userData = UserData.fromMap(Map<dynamic, dynamic>.from(rawValue));
        _data[key] = userData;
        _userIds[userData.username] = key;
      }
    }

    if (_data.isEmpty) {
      _registerUser(0, UserData(username: 'default'));
      _nextUserId = 1;
      _currentUserId = 0;
      _persistUser(0);
      _persistMeta();
      _loadUserState(0);
      return;
    }

    final savedNextUserId = _metaBox.get(_metaNextUserIdKey);
    if (savedNextUserId is int) {
      _nextUserId = savedNextUserId;
    } else {
      _nextUserId = _data.keys.isEmpty ? 0 : (_data.keys.reduce((a, b) => a > b ? a : b) + 1);
    }

    final savedCurrentUserId = _metaBox.get(_metaCurrentUserIdKey);
    _currentUserId = savedCurrentUserId is int && _data.containsKey(savedCurrentUserId)
        ? savedCurrentUserId
        : _data.keys.contains(0)
            ? 0
            : _data.keys.first;

    _loadUserState(_currentUserId);
  }

  /// 注册新用户
  void _registerUser(int userId, UserData userData) {
    _data[userId] = userData;
    _userIds[userData.username] = userId;
    _nextUserId = _nextUserId <= userId ? userId + 1 : _nextUserId;
  }

  /// 将用户数据持久化到 Hive 中
  void _persistUser(int userId) {
    final userData = _data[userId];
    if (userData == null) {
      return;
    }
    _usersBox.put(userId, userData.toMap());
  }

  void _persistMeta() {
    _metaBox.put(_metaCurrentUserIdKey, _currentUserId);
    _metaBox.put(_metaNextUserIdKey, _nextUserId);
  }

  /// 加载指定用户的数据
  /// 并写入到当前用户的状态中
  void _loadUserState(int userId) {
    // 切换用户前取消待执行的延迟保存，避免旧用户数据被误写
    _saveDebounce?.cancel();
    _saveDebounce = null;
    final userData = _data[userId];
    if (userData == null) {
      throw ArgumentError('User not found');
    }
    _currentUserId = userId;
    _currentUser = userData.username;

    _cardIds = List<int>.from(userData.cardIds);
    _applyFlags = Map<int, bool>.from(userData.applyFlags);
    _textValues = Map<int, String>.from(userData.textValues);
    _numberValues = Map<int, String>.from(userData.numberValues);
    _unitGold = Map<int, double>.from(userData.unitGold);
    _wave = userData.wave;
    _seasonWave = userData.seasonWave;
    _gp = userData.gp;
    _gpCN = userData.gpCN;
    _totalGold = userData.totalGold;

    // 通知 UI 更新
    totalGoldNotifier.value = _totalGold;
    gpNotifier.value = _gp;
    gpCNNotifier.value = _gpCN;
    _persistMeta();
  }

  /// 保存当前用户的数据到内存中
  void _saveCurrentState() {
    final currentState = _data[_currentUserId];
    if (currentState == null) {
      return;
    }

    currentState.cardIds = List<int>.from(_cardIds);
    currentState.applyFlags = Map<int, bool>.from(_applyFlags);
    currentState.textValues = Map<int, String>.from(_textValues);
    currentState.numberValues = Map<int, String>.from(_numberValues);
    currentState.unitGold = Map<int, double>.from(_unitGold);
    currentState.totalGold = _totalGold;
    currentState.wave = _wave;
    currentState.seasonWave = _seasonWave;
    currentState.gp = _gp;
    currentState.gpCN = _gpCN;
    _persistUser(_currentUserId);
    _persistMeta();
    // print(_usersBox.toMap());
  }

  /// 延迟落盘：输入热路径只更新内存与通知，停笔后统一保存
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      _saveDebounce = null;
      _saveCurrentState();
    });
  }

  /// 立即落盘并取消待执行的延迟保存
  /// （切换用户/重命名/应用退到后台前调用，避免丢失最近输入）
  void flush() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _saveCurrentState();
  }

  /// 重置为默认用户
  void resetToDefaultUser() {
    if (_data[0] == null) {
      _registerUser(0, UserData(username: 'default'));
      _persistUser(0);
    }
    _loadUserState(0);
  }

  /// 获取用户 ID，如果不存在则返回 -1
  int getUserId(String username) {
    return _userIds[username] ?? -1;
  }
  
  /// 更新当前用户的数据
  void updateData(String username) {
    if (username.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    if (userId == _currentUserId) {
      // 输入热路径：只更新内存与通知，延迟落盘合并写次数
      _scheduleSave();
    } else {
      // 目标不是当前用户：切换前立即保存
      flush();
      _loadUserState(userId);
    }
  }

  /// 创建新用户
  void createUser(String username) {
    if (username.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    if (getUserId(username) != -1) {
      throw ArgumentError('User already exists');
    }
    final newUserId = _nextUserId++;
    
    _registerUser(newUserId, UserData(username: username, cardIds: [1, 2], applyFlags: {1: true, 2: true}));
    _persistUser(newUserId);
    _persistMeta();

  }

  /// 删除用户
  void deleteUser(String username) {
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    if (userId == 0) {
      throw ArgumentError('Default user cannot be deleted');
    }
    if (_currentUserId == userId) {
      resetToDefaultUser();
    }
    _userIds.remove(username);
    _data.remove(userId);
    _usersBox.delete(userId);
    _persistMeta();
  }

  /// 切换用户
  void setCurrentUser(String username) {
    if (username.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    if (userId == _currentUserId) {
      return;
    }
    // 切换前立即落盘，确保当前用户最近输入不丢失
    flush();
    _loadUserState(userId);
  }

  /// 用户名重命名
  void renameUser(String oldUsername, String newUsername) {
    if (newUsername.isEmpty) {
      throw ArgumentError('New username cannot be empty');
    }
    final userId = getUserId(oldUsername);
    if (userId == -1) {
      throw ArgumentError('Old user not found');
    }
    if (getUserId(newUsername) != -1) {
      throw ArgumentError('New username already exists');
    }
    final userData = _data[userId];
    if (userData == null) {
      throw ArgumentError('User data not found');
    }
    // 重命名前先落盘：避免 _data 里还是延迟保存前的旧快照
    flush();
    userData.username = newUsername;
    _userIds.remove(oldUsername);
    _userIds[newUsername] = userId;
    if (_currentUserId == userId) {
      _currentUser = newUsername;
    }
    _persistUser(userId);
    _persistMeta();
  }

  /// 添加条目 ID 到当前用户的列表中
  void _addCard(int id) {
    if (!_cardIds.contains(id)) {
      _cardIds.add(id);
    }
  }

  /// 返回当前用户的条目 ID 列表
  List<int> getCardIds() => _cardIds; 

  /// 设置当前条目的应用标志
  void setApplyFlag(int id, bool value) {
    _addCard(id);
    _applyFlags[id] = value;
    updateData(_currentUser);
  }

  /// 获取当前条目的应用标志
  bool getApplyFlag(int id) => _applyFlags[id] ?? true; 

  /// 设置当前条目的名称
  void setTextValue(int id, String value) {
    _addCard(id);
    _textValues[id] = value;
    updateData(_currentUser);
  }

  /// 获取当前条目的名称
  String getTextValue(int id) => _textValues[id] ?? '';

  /// 设置当前条目的等级
  void setNumberValue(int id, String value) {
    _addCard(id);
    _numberValues[id] = value;
    _setUnitGold(id, value.isEmpty ? 0 : int.tryParse(value) ?? 0);
    updateData(_currentUser);
  }

  /// 获取当前条目的等级
  String getNumberValue(int id) => _numberValues[id] ?? '';

  /// 重新计算并通知 UI
  void _recalc() {
    _totalGold = _unitGold.values.fold(0.0, (sum, gold) => sum + gold);
    _gp = (_wave > 0) ? _totalGold / (0.5 * (310 + _wave * 310) * _wave) * 100 : 0.0;
    _gpCN = (_wave > 0) ? (_totalGold / (_wave * _wave)) : 0.0;
    totalGoldNotifier.value = _totalGold;
    gpNotifier.value = _gp;
    gpCNNotifier.value = _gpCN;
  }

  /// 设置当前条目的金币
  void _setUnitGold(int id, int value) {
    _addCard(id);
    _unitGold[id] = unitLevelSpendGold(value, id);
    _recalc();
    // 持久化统一由 setNumberValue 末尾的 updateData 负责（防抖落盘）
  }

  /// 获取当前波数
  int getWave() => _wave;

  /// 获取当前赛季波数
  int getSeasonWave() => _seasonWave;

  /// 设置当前波数
  void setWave(int wave) {
    _wave = wave;
    _recalc();
    _saveCurrentState();
  }

  /// 设置当前赛季波数
  void setSeasonWave(int seasonWave) {
    _seasonWave = seasonWave;
    _recalc();
    _saveCurrentState();
  }

  /// 获取当前条目的金币
  double getUnitGold(int id) => _unitGold[id] ?? 0.0;

  /// 获取总经济
  double getTotalGold(String username) {
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    // 当前用户返回内存实时值（防抖落盘期间 _data 里可能是旧快照）
    if (userId == _currentUserId) {
      return _totalGold;
    }
    return _data[userId]?.totalGold ?? 0.0;
  }

  /// 移除当前卡片
  void removeCard(int id) {
    // 默认条目不允许删除
    if (id == 1 || id == 2) return;

    _applyFlags.remove(id);
    _textValues.remove(id);
    _numberValues.remove(id);
    _unitGold.remove(id);
    _cardIds.remove(id);
    _recalc();
    updateData(_currentUser);
    cardIdsNotifier.value++;
  }

  /// 添加新条目（id 自动取当前最大 id + 1）
  void addNewCard() {
    final newId = _cardIds.isEmpty ? 1 : _cardIds.reduce((a, b) => a > b ? a : b) + 1;
    setApplyFlag(newId, true);
    updateData(_currentUser);
    cardIdsNotifier.value++;
  }

  /// 调整当前用户卡片的顺序
  void reorderCard(int oldIndex, int newIndex) {
    final id = _cardIds.removeAt(oldIndex);
    _cardIds.insert(newIndex, id);
    cardIdsNotifier.value++;
    _saveCurrentState();
  }

  double heroLevelSpendGold(int level) {
    if (level <= 0) return 0;

    const thresholds = [
      10000, 5000, 200, 180, 160, 140, 120, 100, 80, 60, 40, 20, 1,
    ];
    const baseGold = [
      187458432500, 37468432500, 35632500, 26157500, 18530000, 12530000,
      7997500, 4712500, 2475000, 1085000, 342500, 47500, 0,
    ];
    const baseMultiplier = [
      50000000, 20000000, 600000, 450000, 360000, 280000, 210000, 150000,
      100000, 60000, 30000, 10000, 250,
    ];
    const increment = [
      5000, 4000, 3000, 2500, 2250, 2000, 1750, 1500, 1250, 1000, 750, 500, 250,
    ];

    for (int i = 0; i < thresholds.length; i++) {
      if (level > thresholds[i]) {
        final diff = level - thresholds[i];
        return ((baseMultiplier[i] * 2 + increment[i] * (diff - 1)) / 2 * diff) +
            baseGold[i];
      }
    }

    return 0;
  }

  double unitLevelSpendGold(int level, int id) {
    switch (id) {
      case 1:
        return level * level * 1250;
      case 2:
        return level * level * 500;
      default:
        return heroLevelSpendGold(level);
    }
  }
}

class UserData {
  UserData({
    required this.username,
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
  })  : cardIds = cardIds ?? [1, 2],
        applyFlags = applyFlags ?? {1: true, 2: true},
        textValues = textValues ?? {},
        numberValues = numberValues ?? {},
        unitGold = unitGold ?? {},
        totalGold = totalGold ?? 0.0,
        wave = wave ?? 1,
        seasonWave = seasonWave ?? 0,
        gp = gp ?? 0,
        gpCN = gpCN ?? 0;


  String username;
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
  factory UserData.fromMap(Map<dynamic, dynamic> map) {
    final info = Map<String, dynamic>.from((map['info'] as Map?) ?? const {});
    final data = Map<String, dynamic>.from((map['data'] as Map?) ?? const {});

    return UserData(
      username: map['username']?.toString() ?? 'default',
      cardIds: List<int>.from((info['cardIds'] as List?) ?? const [1, 2]),
      applyFlags: _castIntKeyBoolMap(info['applyFlags']),
      textValues: _castIntKeyStringMap(info['textValues']),
      numberValues: _castIntKeyStringMap(info['numberValues']),
      unitGold: _castIntKeyDoubleMap(data['unitGold']),
      totalGold: (data['totalGold'] as num?)?.toDouble() ?? 0.0,
      wave: (data['wave'] as num?)?.toInt() ?? 1,
      seasonWave: (data['seasonWave'] as num?)?.toInt() ?? 0,
      gp: (data['gp'] as num?)?.toDouble() ?? 0.0,
      gpCN: (data['gpCN'] as num?)?.toDouble() ?? 0.0,
    );
  }

  UserData clone() {
    return UserData(
      username: username,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
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

  static Map<int, int> _castIntKeyIntMap(Object? value) {
    final result = <int, int>{};
    if (value is Map) {
      for (final entry in value.entries) {
        final key = int.tryParse(entry.key.toString());
        if (key != null) {
          result[key] = (entry.value as num?)?.toInt() ?? 0;
        }
      }
    }
    return result;
  }
}