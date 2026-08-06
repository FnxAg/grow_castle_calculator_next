import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/data/store/user_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InfoStore {
  static const String _usersBoxName = 'user_data';
  static const String _metaBoxName = 'user_meta';
  static const String _metaCurrentUserIdKey = 'currentUserId';
  static const String _metaNextUserIdKey = 'nextUserId';

  final Box _usersBox = Hive.box(_usersBoxName);
  final Box _metaBox = Hive.box(_metaBoxName);

  final Map<int, UserData> _data = {};
  /// 用户名 → userId 索引（展示用，保留原始大小写）
  final Map<String, int> _userIds = {};
  /// 归一化用户名（trim + 小写）→ userId 索引：实现大小写不敏感查找
  final Map<String, int> _userIdsLower = {};

  /// 用户名/公会名归一化：大小写不敏感比较与索引的基准（trim + lowercase）
  static String _normalize(String s) => s.trim().toLowerCase();
  
  int _nextUserId = 0;
  int _currentUserId = 0;
  String _currentUser = 'default';

  String _guild = '';
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
  bool _onlineQuery = false;
  int _infiniteColony = 0;

  /// 延迟落盘定时器：输入热路径合并写盘
  Timer? _saveDebounce;

  /// 当前用户总金币变化通知
  final ValueNotifier<double> totalGoldNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> gpNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> gpCNNotifier = ValueNotifier<double>(0);
  /// 当前用户波数变化通知
  final ValueNotifier<int> waveNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> seasonWaveNotifier = ValueNotifier<int>(0);
  // 当前用户设置变化通知
  final ValueNotifier<bool> onlineQueryNotifier = ValueNotifier<bool>(false);
  /// 各用户最近一次联网查询的"上次在线"展示字符串（仅内存，不持久化）
  final Map<int, String> _lastOnline = {};
  /// 当前用户"上次在线"时间通知（查询成功时格式化并固定，仅内存）
  final ValueNotifier<String> lastOnlineNotifier = ValueNotifier<String>('');

  /// 卡片列表结构变化通知（新增/删除/排序），供卡片列表重建
  final ValueNotifier<int> cardIdsNotifier = ValueNotifier<int>(0);

  /// 当前用户名称变化通知：切换/重命名用户时触发。
  ///
  /// 供 UserPageScaffold 全局监听——PageView 保活的用户页面不会随
  /// 「发起切换的页面」的局部 setState 重建，必须由这里统一驱动
  final ValueNotifier<String> currentUserNotifier = ValueNotifier<String>('default');

  InfoStore() {
    _loadFromHive();
  }

  /// 获取当前用户资料（无数据时返回默认用户副本，避免外部改动污染常量）
  Map<String, dynamic> get currentUserData =>
      _data[_currentUserId]?.toMap() ?? UserData.fromMap(defaultUserData[0]!).toMap();

  /// 获取当前用户名称
  String getCurrentUsername() => _currentUser;

  /// 获取当前用户 ID
  int getCurrentUserId() => _currentUserId;

  /// 获取当前用户公会
  String getCurrentUserGuild() => _guild;

  /// 获取指定用户的公会
  String getUserGuild(String username) {
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    return _data[userId]?.guild ?? '';
  }

  /// 设置指定用户的公会（跨用户操作；为当前用户时同步内存态并落盘）
  void setUserGuild(String username, String guild) {
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    final userData = _data[userId];
    // 公会名大小写不敏感：内容仅大小写/首尾空格不同时不重复写入
    if (userData == null || _normalize(userData.guild) == _normalize(guild)) {
      return;
    }
    userData.guild = guild;
    if (userId == _currentUserId) {
      _guild = guild;
    }
    _persistUser(userId);
  }

  /// 获取所有用户名称
  List<String> getAllUsernames() => _userIds.keys.toList();

  void _loadFromHive() {
    _data.clear();
    _userIds.clear();
    _userIdsLower.clear();

    for (final key in _usersBox.keys) {
      final rawValue = _usersBox.get(key);
      if (key is int && rawValue is Map) {
        var raw = Map<dynamic, dynamic>.from(rawValue);
        // 旧版本数据缺少新字段：逐级迁移并一次性写回磁盘
        if (UserData.isOutdated(raw)) {
          raw = UserData.migrate(raw);
          _usersBox.put(key, raw);
        }
        final userData = UserData.fromMap(raw);
        _data[key] = userData;
        _userIds[userData.username] = key;
        _userIdsLower[_normalize(userData.username)] = key;
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
    _userIdsLower[_normalize(userData.username)] = userId;
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
    currentUserNotifier.value = userData.username;
    _guild = userData.guild;

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
    _onlineQuery = userData.onlineQuery;
    _infiniteColony = userData.infiniteColony;

    // 通知 UI 更新
    totalGoldNotifier.value = _totalGold;
    gpNotifier.value = _gp;
    gpCNNotifier.value = _gpCN;
    waveNotifier.value = _wave;
    seasonWaveNotifier.value = _seasonWave;
    onlineQueryNotifier.value = _onlineQuery;
    lastOnlineNotifier.value = _lastOnline[userId] ?? '';
    _persistMeta();
  }

  /// 保存当前用户的数据到内存中
  void _saveCurrentState() {
    final currentState = _data[_currentUserId];
    if (currentState == null) {
      return;
    }

    currentState.guild = _guild;
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
    currentState.onlineQuery = _onlineQuery;
    currentState.infiniteColony = _infiniteColony;
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

  /// 获取用户 ID（大小写不敏感），如果不存在则返回 -1
  int getUserId(String username) {
    return _userIdsLower[_normalize(username)] ?? -1;
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
  void createUser(String username, {String guild = ''}) {
    if (username.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    if (getUserId(username) != -1) {
      throw ArgumentError('Username already exists (case-insensitive)');
    }
    final newUserId = _nextUserId++;
    
    _registerUser(newUserId, UserData(username: username, cardIds: [1, 2], applyFlags: {1: true, 2: true}, guild: guild));
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
    // 按 userId 移除索引：传入名的大小写可能与存储不一致
    _userIds.removeWhere((name, id) => id == userId);
    _userIdsLower.removeWhere((name, id) => id == userId);
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
    // 大小写不敏感去重：允许仅改大小写（如 Alice → alice），禁止与其他人重名
    final existingId = getUserId(newUsername);
    if (existingId != -1 && existingId != userId) {
      throw ArgumentError('New username already exists (case-insensitive)');
    }
    final userData = _data[userId];
    if (userData == null) {
      throw ArgumentError('User data not found');
    }
    // 重命名前先落盘：避免 _data 里还是延迟保存前的旧快照
    flush();
    userData.username = newUsername;
    // 按 userId 移除旧索引：旧名传入大小写可能与存储不一致
    _userIds.removeWhere((name, id) => id == userId);
    _userIdsLower.removeWhere((name, id) => id == userId);
    _userIds[newUsername] = userId;
    _userIdsLower[_normalize(newUsername)] = userId;
    if (_currentUserId == userId) {
      _currentUser = newUsername;
      currentUserNotifier.value = newUsername;
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

  /// 修改当前用户联网查询设置
  void setOnlineQuery(int id, bool value) {
    _addCard(id);
    _onlineQuery = value;
    onlineQueryNotifier.value = _onlineQuery;
    updateData(_currentUser);
  }

  /// 获取当前用户联网查询设置状态
  bool getOnlineQuery() => _onlineQuery;

  /// 重新计算并通知 UI
  /// 仅累加启用单位（applyFlag != false）的金币，未启用的 unitGold 保留但不计入汇总
  void _recalc() {
    _totalGold = 0.0;
    for (final entry in _unitGold.entries) {
      if (_applyFlags[entry.key] ?? true) {
        _totalGold += entry.value;
      }
    }
    _gp = (_wave > 0) ? _totalGold / (0.5 * (310 + _wave * 310) * _wave) * 100 : 0.0;
    _gpCN = (_wave > 0) ? (_totalGold / (_wave * _wave)) : 0.0;
    totalGoldNotifier.value = _totalGold;
    gpNotifier.value = _gp;
    gpCNNotifier.value = _gpCN;
  }

  /// 获取当前用户的条目 ID 列表
  List<int> getCardIds() => _cardIds; 

  /// 获取当前条目的应用标志
  bool getApplyFlag(int id) => _applyFlags[id] ?? true;

  /// 设置当前条目的应用标志
  void setApplyFlag(int id, bool value) {
    _addCard(id);
    _applyFlags[id] = value;
    _recalc();
    updateData(_currentUser);
  } 

  /// 获取当前条目的名称
  String getTextValue(int id) => _textValues[id] ?? '';

  /// 设置当前条目的名称
  void setTextValue(int id, String value) {
    _addCard(id);
    _textValues[id] = value;
    updateData(_currentUser);
  }

  /// 获取当前条目的等级
  String getNumberValue(int id) => _numberValues[id] ?? '';

  /// 设置当前条目的等级
  void setNumberValue(int id, String value) {
    _addCard(id);
    _numberValues[id] = value;
    _setUnitGold(id, value.isEmpty ? 0 : int.tryParse(value) ?? 0);
    updateData(_currentUser);
  }

  /// 设置当前条目的金币
  void _setUnitGold(int id, int value) {
    _addCard(id);
    _unitGold[id] = unitLevelSpendGold(value, id);
    _recalc();
    // 持久化统一由 setNumberValue 末尾的 updateData 负责（防抖落盘）
  }

  /// 获取当前用户总波数
  int getCurrentUserWave() => _wave;

  /// 获取指定用户总波数
  int getUserWave(String username) {
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    return _data[userId]?.wave ?? 1;
  }

  /// 设置当前用户总波数
  void setUserWave(int wave) {
    _wave = wave;
    _recalc();
    waveNotifier.value = _wave;
    _saveCurrentState();
  }

  /// 获取当前用户赛季波数
  int getCurrentUserSeasonWave() => _seasonWave;

  /// 获取指定用户赛季波数
  int getUserSeasonWave(String username) {
    final userId = getUserId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    return _data[userId]?.seasonWave ?? 1;
  }

  /// 设置当前用户赛季波数
  void setCurrentUserSeasonWave(int seasonWave) {
    _seasonWave = seasonWave;
    _recalc();
    seasonWaveNotifier.value = _seasonWave;
    _saveCurrentState();
  }

  /// 将联网查询结果一次性写入当前用户的波数与赛季波数
  /// （合并 setWave/setSeasonWave，只重算与落盘一次）
  /// [lastOnline] 为查询时格式化好的"上次在线"展示字符串，仅内存记录、不持久化
  void applyOnlineQuery(int wave, int seasonWave, {String lastOnline = ''}) {
    _wave = wave;
    _seasonWave = seasonWave;
    if (lastOnline.isNotEmpty) {
      _lastOnline[_currentUserId] = lastOnline;
      lastOnlineNotifier.value = lastOnline;
    }
    _recalc();
    waveNotifier.value = _wave;
    seasonWaveNotifier.value = _seasonWave;
    _saveCurrentState();
  }

  /// 联网同步当前用户：拉取个人赛季数据并写入 store。
  ///
  /// 成功返回 [PlayerQueryResult]（波数与赛季波数已写入；封禁时仅标记
  /// 「已封禁」不写波数），失败返回 [QueryError]；UI 层自行决定提示文案。
  /// 供「阵容」页同步按钮与「公会」页下拉刷新共用。
  Future<Object /* PlayerQueryResult | QueryError */> syncCurrentUser() async {
    final result = await PlayerApiService.query(_currentUser);
    if (result is PlayerQueryResult) {
      final lastOnline =
          PlayerApiService.formatLastOnline(result.queryDate, DateTime.now());
      if (result.wave == 0 && result.queryDate.isEmpty) {
        // 封禁检测：仅标记「已封禁」（AppBar 副标题展示），不写入波数
        setLastOnline('Banned');
      } else {
        applyOnlineQuery(
          result.wave,
          result.seasonalScore,
          lastOnline: lastOnline,
        );
      }
    }
    return result;
  }

  /// 仅更新「上次在线」展示字符串（如封禁标记），不修改任何波数数据
  void setLastOnline(String lastOnline) {
    _lastOnline[_currentUserId] = lastOnline;
    lastOnlineNotifier.value = lastOnline;
  }

  /// 获取当前条目的金币
  double getCurrentUserUnitGold(int id) => _unitGold[id] ?? 0.0;

  /// 获取指定用户总经济
  double getUserTotalGold(String username) {
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

  /// 获取指定用户的完整数据快照（返回拷贝，外部修改不会污染 store）。
  /// 用于在用户列表中查看非当前用户的汇总；当前用户可能有 ≤400ms 防抖延迟。
  UserData? getUserData(String username) {
    final userId = getUserId(username);
    if (userId == -1 || !_data.containsKey(userId)) {
      return null;
    }
    return UserData.fromMap(_data[userId]!.toMap());
  }

  /// 移除卡片
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

