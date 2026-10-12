/// 用户数据的 Riverpod 状态层
///
/// - [userDataRepositoryProvider]：Hive 网关
/// - [usersProvider]：全部用户 + 当前用户 id 的单一原子状态，所有变更入口
/// - [dataVersionProvider]：数据被整体替换时的自增计数
/// - [lastOnlineByUserProvider]：各用户「上次在线」展示串
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grow_castle_calculator_next/core/calc/gold_income.dart';
import 'package:grow_castle_calculator_next/core/calc/level_spend_gold.dart';
import 'package:grow_castle_calculator_next/core/calc/wave_speed.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:grow_castle_calculator_next/data/store/game_track.dart';
import 'package:grow_castle_calculator_next/data/store/user_data_repository.dart';
import 'package:grow_castle_calculator_next/data/store/widget_snapshot.dart';
import 'package:grow_castle_calculator_next/model/userdata/user_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_data_provider.g.dart';

/// Hive 网关
@Riverpod(keepAlive: true)
UserDataRepository userDataRepository(Ref ref) => UserDataRepository();

/// 全部用户 + 当前用户 id + 下一个可分配 id
@immutable
class UsersState {
  const UsersState({
    required this.users,
    required this.currentUserId,
    required this.nextUserId,
  });

  /// userId
  final Map<int, UserData> users;
  final int currentUserId;

  /// 下一个可分配的用户 id
  final int nextUserId;

  UserData get currentUser => users[currentUserId]!;

  List<String> get usernames =>
      [for (final u in users.values) u.username];

  /// 用户名/公会名归一化
  static String normalize(String s) => s.trim().toLowerCase();

  /// 按归一化用户名查 id，未找到返回 -1
  int findId(String username) {
    final key = normalize(username);
    var found = -1;
    for (final entry in users.entries) {
      if (normalize(entry.value.username) == key) {
        found = entry.key;
      }
    }
    return found;
  }

  /// 按用户名取用户；未找到返回 null
  UserData? findByUsername(String username) {
    final id = findId(username);
    return id == -1 ? null : users[id];
  }

  UsersState copyWith({
    Map<int, UserData>? users,
    int? currentUserId,
    int? nextUserId,
  }) {
    return UsersState(
      users: users ?? this.users,
      currentUserId: currentUserId ?? this.currentUserId,
      nextUserId: nextUserId ?? this.nextUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsersState &&
        _sameUsers(other.users, users) &&
        other.currentUserId == currentUserId &&
        other.nextUserId == nextUserId;
  }

  @override
  int get hashCode =>
      Object.hash(_usersHash(users), currentUserId, nextUserId);

  /// 用户表比较
  static bool _sameUsers(Map<int, UserData> a, Map<int, UserData> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      if (!identical(entry.value, other) && entry.value != other) return false;
    }
    return true;
  }

  static int _usersHash(Map<int, UserData> users) => Object.hashAllUnordered(
        users.entries.map((e) => Object.hash(e.key, e.value)),
      );
}

/// 用户数据状态容器
@Riverpod(keepAlive: true)
class Users extends _$Users {
  /// 延迟落盘定时器
  Timer? _saveDebounce;

  @override
  UsersState build() {
    // 取消挂起的延迟保存
    _saveDebounce?.cancel();
    _saveDebounce = null;
    ref.onDispose(() {
      _saveDebounce?.cancel();
      _saveDebounce = null;
    });

    final snapshot = ref.read(userDataRepositoryProvider).readAll();
    return UsersState(
      users: snapshot.users,
      currentUserId: snapshot.currentUserId,
      nextUserId: snapshot.nextUserId,
    );
  }

  /// 延迟落盘
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      _saveDebounce = null;
      _persistNow();
    });
  }

  /// 立即落盘并取消待执行的延迟保存
  void flush() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _persistNow();
  }

  /// 把当前用户写盘 + 落 meta + 同步桌面小组件快照
  void _persistNow() {
    final s = state;
    final user = s.users[s.currentUserId];
    if (user == null) {
      return;
    }
    final repo = ref.read(userDataRepositoryProvider);
    repo.writeUser(s.currentUserId, user);
    _persistMeta();
    _writeWidgetSnapshot();
  }

  void _persistMeta() {
    ref
        .read(userDataRepositoryProvider)
        .writeMeta(
          currentUserId: state.currentUserId,
          nextUserId: state.nextUserId,
        );
  }

  /// 同步桌面小组件快照
  void _writeWidgetSnapshot() {
    final s = state;
    final user = s.users[s.currentUserId];
    if (user == null) {
      return;
    }
    WidgetSnapshot.write(
      username: user.username,
      wave: user.wave,
      seasonWave: user.seasonWave,
      lastOnline: ref.read(lastOnlineByUserProvider)[s.currentUserId] ?? '',
      // 默认用户
      isDefault: s.currentUserId == 0,
    );
  }

  /// 替换当前用户的数据，[immediate] 决定是否立即落盘
  void _setCurrentUser(UserData updated, {required bool immediate}) {
    final s = state;
    state = s.copyWith(users: {...s.users, s.currentUserId: updated});
    if (immediate) {
      _persistNow();
    } else {
      _scheduleSave();
    }
  }

  /// 重算总金币与派生指标（GP / GP-CN），不落盘
  UserData _recalc(UserData u) {
    var totalGold = 0.0;
    for (final entry in u.unitGold.entries) {
      if (u.applyFlags[entry.key] ?? true) {
        totalGold += entry.value;
      }
    }
    return u.copyWith(
      totalGold: totalGold,
      gp: u.wave > 0
          ? totalGold / (0.5 * (310 + u.wave * 310) * u.wave) * 100
          : 0.0,
      gpCN: u.wave > 0 ? (totalGold / (u.wave * u.wave)) : 0.0,
    );
  }

  /// 把 [id] 加入卡片列表（若已存在则原样返回）
  List<int> _withCard(List<int> cardIds, int id) =>
      cardIds.contains(id) ? cardIds : [...cardIds, id];

  // 当前用户跳波参数

  int getCurrentUserGameSpeed() => state.currentUser.gameSpeed;

  void setCurrentUserGameSpeed(int value) {
    final u = state.currentUser;
    if (u.gameSpeed == value) return;
    _setCurrentUser(u.copyWith(gameSpeed: value), immediate: false);
  }

  int getCurrentUserChronoClass() => state.currentUser.chronoClass;

  void setCurrentUserChronoClass(int value) {
    final u = state.currentUser;
    if (u.chronoClass == value) return;
    _setCurrentUser(u.copyWith(chronoClass: value), immediate: false);
  }

  bool getCurrentUserHorn() => state.currentUser.horn;

  void setCurrentUserHorn(bool value) {
    final u = state.currentUser;
    if (u.horn == value) return;
    _setCurrentUser(u.copyWith(horn: value), immediate: false);
  }

  bool getCurrentUserGoldenHorn() => state.currentUser.goldenHorn;

  void setCurrentUserGoldenHorn(bool value) {
    final u = state.currentUser;
    if (u.goldenHorn == value) return;
    _setCurrentUser(u.copyWith(goldenHorn: value), immediate: false);
  }

  int getCurrentUserDevilHornSkip() => state.currentUser.devilHornSkip;

  void setCurrentUserDevilHornSkip(int value) {
    final u = state.currentUser;
    if (u.devilHornSkip == value) return;
    _setCurrentUser(u.copyWith(devilHornSkip: value), immediate: false);
  }

  bool getCurrentUserIsGoldAutoBattle() => state.currentUser.isGoldAutoBattle;

  void setCurrentUserIsGoldAutoBattle(bool value) {
    final u = state.currentUser;
    if (u.isGoldAutoBattle == value) return;
    _setCurrentUser(u.copyWith(isGoldAutoBattle: value), immediate: false);
  }

  // 当前用户收入参数

  int getCurrentUserInfiniteColony() => state.currentUser.infiniteColony;

  void setCurrentUserInfiniteColony(int value) {
    final u = state.currentUser;
    if (u.infiniteColony == value) return;
    _setCurrentUser(u.copyWith(infiniteColony: value), immediate: false);
  }

  double getCurrentUserGabTime() => state.currentUser.gabTime;

  void setCurrentUserGabTime(double value) {
    final u = state.currentUser;
    if (u.gabTime == value) return;
    _setCurrentUser(u.copyWith(gabTime: value), immediate: false);
  }

  double getCurrentUserGabBonus() => state.currentUser.gabBonus;

  void setCurrentUserGabBonus(double value) {
    final u = state.currentUser;
    if (u.gabBonus == value) return;
    _setCurrentUser(u.copyWith(gabBonus: value), immediate: false);
  }

  double getCurrentUserTabTime() => state.currentUser.tabTime;

  void setCurrentUserTabTime(double value) {
    final u = state.currentUser;
    if (u.tabTime == value) return;
    _setCurrentUser(u.copyWith(tabTime: value), immediate: false);
  }

  int getCurrentUserIcCooldown() => state.currentUser.icCooldownSkill;

  void setCurrentUserIcCooldown(int value) {
    final u = state.currentUser;
    if (u.icCooldownSkill == value) return;
    _setCurrentUser(u.copyWith(icCooldownSkill: value), immediate: false);
  }

  int getCurrentUserIcGold() => state.currentUser.icGoldSkill;

  void setCurrentUserIcGold(int value) {
    final u = state.currentUser;
    if (u.icGoldSkill == value) return;
    _setCurrentUser(u.copyWith(icGoldSkill: value), immediate: false);
  }

  bool getCurrentUserEquipWheel() => state.currentUser.equipWheel;

  void setCurrentUserEquipWheel(bool value) {
    final u = state.currentUser;
    if (u.equipWheel == value) return;
    _setCurrentUser(u.copyWith(equipWheel: value), immediate: false);
  }

  bool getCurrentUserEquipWhip() => state.currentUser.equipWhip;

  void setCurrentUserEquipWhip(bool value) {
    final u = state.currentUser;
    if (u.equipWhip == value) return;
    _setCurrentUser(u.copyWith(equipWhip: value), immediate: false);
  }

  bool getCurrentUserSeasonColony() => state.currentUser.seasonColony;

  void setCurrentUserSeasonColony(bool value) {
    final u = state.currentUser;
    if (u.seasonColony == value) return;
    _setCurrentUser(u.copyWith(seasonColony: value), immediate: false);
  }

  bool getCurrentUserGoldenTree() => state.currentUser.goldenTree;

  void setCurrentUserGoldenTree(bool value) {
    final u = state.currentUser;
    if (u.goldenTree == value) return;
    _setCurrentUser(u.copyWith(goldenTree: value), immediate: false);
  }

  // 当前用户联网查询开关，未启用

  bool getOnlineQuery() => state.currentUser.onlineQuery;

  void setOnlineQuery(int id, bool value) {
    final u = state.currentUser;
    _setCurrentUser(
      u.copyWith(cardIds: _withCard(u.cardIds, id), onlineQuery: value),
      immediate: false,
    );
  }

  // 当前用户卡片

  List<int> getCardIds() => state.currentUser.cardIds;

  bool getApplyFlag(int id) => state.currentUser.applyFlags[id] ?? true;

  String getTextValue(int id) => state.currentUser.textValues[id] ?? '';

  String getNumberValue(int id) => state.currentUser.numberValues[id] ?? '';

  double getCurrentUserUnitGold(int id) =>
      state.currentUser.unitGold[id] ?? 0.0;

  void setApplyFlag(int id, bool value) {
    final u = state.currentUser;
    final updated = u.copyWith(
      cardIds: _withCard(u.cardIds, id),
      applyFlags: {...u.applyFlags, id: value},
    );
    _setCurrentUser(_recalc(updated), immediate: false);
  }

  void setTextValue(int id, String value) {
    final u = state.currentUser;
    _setCurrentUser(
      u.copyWith(
        cardIds: _withCard(u.cardIds, id),
        textValues: {...u.textValues, id: value},
      ),
      immediate: false,
    );
  }

  /// 设置等级并同步重算该单位的金币与总金币
  void setNumberValue(int id, String value) {
    final u = state.currentUser;
    final level = value.isEmpty ? 0 : int.tryParse(value) ?? 0;
    final updated = u.copyWith(
      cardIds: _withCard(u.cardIds, id),
      numberValues: {...u.numberValues, id: value},
      unitGold: {...u.unitGold, id: unitLevelSpendGold(level, id)},
    );
    _setCurrentUser(_recalc(updated), immediate: false);
  }

  /// 移除卡片（默认条目 1/2 不允许删除）
  void removeCard(int id) {
    if (id == 1 || id == 2) return;
    final u = state.currentUser;
    final updated = u.copyWith(
      applyFlags: {...u.applyFlags}..remove(id),
      textValues: {...u.textValues}..remove(id),
      numberValues: {...u.numberValues}..remove(id),
      unitGold: {...u.unitGold}..remove(id),
      cardIds: [...u.cardIds]..remove(id),
    );
    _setCurrentUser(_recalc(updated), immediate: false);
  }

  /// 添加新条目（id 自动取当前最大 id + 1）
  void addNewCard() {
    final u = state.currentUser;
    final newId =
        u.cardIds.isEmpty ? 1 : u.cardIds.reduce((a, b) => a > b ? a : b) + 1;
    final updated = u.copyWith(
      cardIds: [...u.cardIds, newId],
      applyFlags: {...u.applyFlags, newId: true},
    );
    _setCurrentUser(_recalc(updated), immediate: false);
  }

  // 当前用户波数

  int getCurrentUserWave() => state.currentUser.wave;

  void setUserWave(int wave) {
    _setCurrentUser(_recalc(state.currentUser.copyWith(wave: wave)), immediate: true);
  }

  int getCurrentUserSeasonWave() => state.currentUser.seasonWave;

  void setCurrentUserSeasonWave(int seasonWave) {
    _setCurrentUser(
      _recalc(state.currentUser.copyWith(seasonWave: seasonWave)),
      immediate: true,
    );
  }

  /// 调整卡片顺序
  void reorderCard(int oldIndex, int newIndex) {
    final ids = [...state.currentUser.cardIds];
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);
    _setCurrentUser(state.currentUser.copyWith(cardIds: ids), immediate: true);
  }

  /// 将联网查询结果一次性写入当前用户的波数与赛季波数
  void applyOnlineQuery(int wave, int seasonWave, {String lastOnline = ''}) {
    if (lastOnline.isNotEmpty) {
      ref
          .read(lastOnlineByUserProvider.notifier)
          .setFor(state.currentUserId, lastOnline);
    }
    final updated = state.currentUser.copyWith(
      wave: wave,
      seasonWave: seasonWave,
    );
    _setCurrentUser(_recalc(updated), immediate: true);
  }

  /// 仅更新「上次在线」展示串（如封禁标记），不修改任何波数数据
  void setLastOnline(String lastOnline) {
    ref
        .read(lastOnlineByUserProvider.notifier)
        .setFor(state.currentUserId, lastOnline);
    // 不走落盘的独立路径，需单独同步小组件快照
    _writeWidgetSnapshot();
  }

  // 用户身份与跨用户读取

  int getCurrentUserId() => state.currentUserId;

  String getCurrentUsername() => state.currentUser.username;

  String getCurrentUserGuild() => state.currentUser.guild;

  /// 当前用户的完整数据快照
  Map<String, dynamic> get currentUserData => state.currentUser.toMap();

  List<String> getAllUsernames() => state.usernames;

  /// 获取用户 ID
  int getUserId(String username) => state.findId(username);

  /// 获取指定用户的完整数据，不存在返回 null
  UserData? getUserData(String username) => state.findByUsername(username);

  String getUserGuild(String username) {
    final u = state.findByUsername(username);
    if (u == null) {
      throw ArgumentError('User not found');
    }
    return u.guild;
  }

  int getUserWave(String username) {
    final u = state.findByUsername(username);
    if (u == null) {
      throw ArgumentError('User not found');
    }
    return u.wave;
  }

  int getUserSeasonWave(String username) {
    final u = state.findByUsername(username);
    if (u == null) {
      throw ArgumentError('User not found');
    }
    return u.seasonWave;
  }

  double getUserTotalGold(String username) {
    final u = state.findByUsername(username);
    if (u == null) {
      throw ArgumentError('User not found');
    }
    return u.totalGold;
  }

  /// 指定用户的理论 WPH
  int getUserTheoreticalWph(String username) {
    final u = state.findByUsername(username);
    if (u == null) {
      throw ArgumentError('User not found');
    }
    return getWph(
      devilHornSkip: u.devilHornSkip,
      isGoldAutoBattle: u.isGoldAutoBattle,
      gameSpeed: u.gameSpeed,
      chronoBonus: u.chronoClass,
      equipHorn: u.horn,
      equipGoldenHorn: u.goldenHorn,
    ).round();
  }

  /// 指定用户的真实 WPH / RWPH
  int getUserRwph(String username) {
    final u = state.findByUsername(username);
    if (u == null) {
      throw ArgumentError('User not found');
    }
    return getRwph(
      gameSpeed: u.gameSpeed,
      chronoBonus: u.chronoClass,
      equipHorn: u.horn,
      equipGoldenHorn: u.goldenHorn,
    ).round();
  }

  // 多用户增删改切

  /// 设置指定用户的公会
  void setUserGuild(String username, String guild) {
    final userId = state.findId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    final user = state.users[userId];
    // 公会名大小写不敏感
    if (user == null ||
        UsersState.normalize(user.guild) == UsersState.normalize(guild)) {
      return;
    }
    final updated = user.copyWith(guild: guild);
    state = state.copyWith(users: {...state.users, userId: updated});
    ref.read(userDataRepositoryProvider).writeUser(userId, updated);
  }

  /// 创建新用户
  void createUser(String username, {String guild = ''}) {
    if (username.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    if (state.findId(username) != -1) {
      throw ArgumentError('Username already exists (case-insensitive)');
    }
    final newUserId = state.nextUserId;
    final newUser = UserData(
      username: username,
      cardIds: [1, 2],
      applyFlags: {1: true, 2: true},
      guild: guild,
    );
    state = state.copyWith(
      users: {...state.users, newUserId: newUser},
      nextUserId: newUserId + 1,
    );
    final repo = ref.read(userDataRepositoryProvider);
    repo.writeUser(newUserId, newUser);
    _persistMeta();
  }

  /// 删除用户，0 号默认用户受保护，删除当前用户时回落到默认用户
  void deleteUser(String username) {
    final userId = state.findId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    if (userId == 0) {
      throw ArgumentError('Default user cannot be deleted');
    }
    if (state.currentUserId == userId) {
      resetToDefaultUser();
    } else {
      // 取消挂起的防抖
      _saveDebounce?.cancel();
      _saveDebounce = null;
    }
    state = state.copyWith(users: {...state.users}..remove(userId));
    ref.read(userDataRepositoryProvider).deleteUser(userId);
    GameTrackStore().removeUser(userId);
    _persistMeta();
  }

  /// 重置为默认用户
  void resetToDefaultUser() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    var users = state.users;
    if (!users.containsKey(0)) {
      final defaultUser = UserData(username: 'default');
      users = {...users, 0: defaultUser};
      ref.read(userDataRepositoryProvider).writeUser(0, defaultUser);
    }
    state = state.copyWith(users: users, currentUserId: 0);
    _persistMeta();
    _writeWidgetSnapshot();
  }

  /// 切换用户
  void setCurrentUser(String username) {
    if (username.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    final userId = state.findId(username);
    if (userId == -1) {
      throw ArgumentError('User not found');
    }
    if (userId == state.currentUserId) {
      return;
    }
    // 切换前立即落盘，确保当前用户最近输入不丢失
    flush();
    state = state.copyWith(currentUserId: userId);
    _persistMeta();
    _writeWidgetSnapshot();
  }

  /// 用户名重命名
  void renameUser(String oldUsername, String newUsername) {
    if (newUsername.isEmpty) {
      throw ArgumentError('New username cannot be empty');
    }
    final userId = state.findId(oldUsername);
    if (userId == -1) {
      throw ArgumentError('Old user not found');
    }
    // 大小写不敏感去重，禁止重名
    final existingId = state.findId(newUsername);
    if (existingId != -1 && existingId != userId) {
      throw ArgumentError('New username already exists (case-insensitive)');
    }
    final user = state.users[userId];
    if (user == null) {
      throw ArgumentError('User data not found');
    }
    // 重命名前先落盘
    flush();
    final renamed = user.copyWith(username: newUsername);
    state = state.copyWith(users: {...state.users, userId: renamed});
    if (state.currentUserId == userId) {
      _writeWidgetSnapshot();
    }
    ref.read(userDataRepositoryProvider).writeUser(userId, renamed);
    _persistMeta();
  }

  // 数据整体替换

  /// 数据整体被替换（云端恢复/本地导入）后重新从 Hive 全量加载
  void reload() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    final snapshot = ref.read(userDataRepositoryProvider).readAll();
    state = UsersState(
      users: snapshot.users,
      currentUserId: snapshot.currentUserId,
      nextUserId: snapshot.nextUserId,
    );
    ref.read(dataVersionProvider.notifier).bump();
  }

  // 联网同步

  /// 联网同步当前用户
  Future<Object /* PlayerQueryResult | QueryError */> syncCurrentUser() async {
    final result = await PlayerApiService.query(state.currentUser.username);
    if (result is PlayerQueryResult) {
      final lastOnline =
          PlayerApiService.formatLastOnline(result.queryDate, DateTime.now());
      if (result.wave == 0 && result.queryDate.isEmpty) {
        // 封禁检测
        setLastOnline('Banned');
      } else {
        applyOnlineQuery(
          result.wave,
          result.seasonalScore,
          lastOnline: lastOnline,
        );
        await _recordGameTrack();
      }
    }
    return result;
  }

  /// 记录一次游戏轨迹
  Future<void> _recordGameTrack() async {
    final settings = AppSettingsStore();
    if (!settings.gameTrackEnabledNotifier.value) return;
    final u = state.currentUser;
    final hasFormationInput = u.cardIds.any(
      (id) =>
          (u.textValues[id]?.trim().isNotEmpty ?? false) ||
          (u.numberValues[id]?.trim().isNotEmpty ?? false),
    );
    if (!hasFormationInput) return;
    final now = DateTime.now();
    final trackStore = GameTrackStore();
    final interval = Duration(
      minutes: settings.gameTrackIntervalMinutesNotifier.value,
    );
    if (!trackStore.canRecord(state.currentUserId, now, interval)) return;

    final units = u.cardIds
        .map(
          (id) {
            final customName = u.textValues[id]?.trim() ?? '';
            // final name = customName.isNotEmpty
            //     ? customName
            //     : id == 1
            //         ? '城堡'
            //         : id == 2
            //             ? '城弓'
            //             : '单位$id';
            final name = customName.isNotEmpty ? customName : '$id.';
            return GameTrackUnit(
              name: name,
              level: int.tryParse(u.numberValues[id] ?? '') ?? 0,
              enabled: u.applyFlags[id] ?? true,
            );
          },
        )
        .toList(growable: false);
    await trackStore.addRecord(
      state.currentUserId,
      GameTrackRecord(
        id: now.microsecondsSinceEpoch.toString(),
        recordedAt: now,
        wave: u.wave,
        totalGold: u.totalGold,
        gp: u.gp,
        gpCN: u.gpCN,
        units: units,
      ),
    );
  }

  // 每日收入

  /// 当前用户每日收入分项
  ({double colony, double autoBattle, double other, double total})
      getCurrentUserDailyIncomeBreakdown() {
    final u = state.currentUser;
    return getDailyIncomeBreakdown(
      wave: u.wave,
      gameSpeed: u.gameSpeed,
      chronoBonus: u.chronoClass,
      equipHorn: u.horn,
      equipGoldenHorn: u.goldenHorn,
      infiniteColony: u.infiniteColony,
      icCooldownSkill: u.icCooldownSkill,
      icGoldSkill: u.icGoldSkill,
      equipWheel: u.equipWheel,
      equipWhip: u.equipWhip,
      gabTime: u.gabTime,
      gabBonus: u.gabBonus,
      tabTime: u.tabTime,
      seasonColony: u.seasonColony,
      goldenTree: u.goldenTree,
    );
  }
}

/// 数据整体替换计数
@Riverpod(keepAlive: true)
class DataVersion extends _$DataVersion {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

/// 各用户「上次在线」展示串
@Riverpod(keepAlive: true)
class LastOnlineByUser extends _$LastOnlineByUser {
  @override
  Map<int, String> build() => const {};

  void setFor(int userId, String value) {
    state = {...state, userId: value};
  }
}
