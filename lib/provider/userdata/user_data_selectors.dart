library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/calc/gold_income.dart';
import 'package:grow_castle_calculator_next/core/calc/wave_speed.dart';
import 'package:grow_castle_calculator_next/model/userdata/user_data.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';

/// 当前用户的完整数据
final currentUserProvider = Provider<UserData>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser)),
);

final currentUserIdProvider = Provider<int>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUserId)),
);

final currentUsernameProvider = Provider<String>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.username)),
);

final currentUserGuildProvider = Provider<String>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.guild)),
);

/// 全部用户名（按 userId 顺序）
final usernamesProvider = Provider<List<String>>((ref) {
  final users = ref.watch(usersProvider.select((s) => s.users));
  return [for (final u in users.values) u.username];
});

/// 当前用户「上次在线」展示串
final currentUserLastOnlineProvider = Provider<String>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(lastOnlineByUserProvider)[userId] ?? '';
});

/// 当前用户的卡片顺序
final currentUserCardIdsProvider = Provider<List<int>>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.cardIds)),
);

/// 当前用户总金币
final currentUserTotalGoldProvider = Provider<double>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.totalGold)),
);

/// 当前用户总波数
final currentUserWaveProvider = Provider<int>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.wave)),
);

/// 当前用户赛季波数
final currentUserSeasonWaveProvider = Provider<int>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.seasonWave)),
);

/// 当前用户金挂平均收益（%）
final currentUserGabBonusProvider = Provider<double>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.gabBonus)),
);

/// 当前用户 GP
final currentUserGpProvider = Provider<double>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.gp)),
);

/// 当前用户指数
final currentUserGpCnProvider = Provider<double>(
  (ref) => ref.watch(usersProvider.select((s) => s.currentUser.gpCN)),
);

// 单字段

final applyFlagProvider = Provider.family<bool, int>(
  (ref, id) => ref.watch(
    usersProvider.select((s) => s.currentUser.applyFlags[id] ?? true),
  ),
);

final textValueProvider = Provider.family<String, int>(
  (ref, id) => ref.watch(
    usersProvider.select((s) => s.currentUser.textValues[id] ?? ''),
  ),
);

final numberValueProvider = Provider.family<String, int>(
  (ref, id) => ref.watch(
    usersProvider.select((s) => s.currentUser.numberValues[id] ?? ''),
  ),
);

final unitGoldProvider = Provider.family<double, int>(
  (ref, id) => ref.watch(
    usersProvider.select((s) => s.currentUser.unitGold[id] ?? 0.0),
  ),
);

/// 指定用户的完整数据，不存在时为 null
final userByNameProvider = Provider.family<UserData?, String>(
  (ref, username) =>
      ref.watch(usersProvider.select((s) => s.findByUsername(username))),
);

/// 指定用户的 userId（大小写不敏感），不存在时为 -1
final userIdProvider = Provider.family<int, String>(
  (ref, username) =>
      ref.watch(usersProvider.select((s) => s.findId(username))),
);

// 派生值

/// 当前用户理论 WPH
final theoreticalWphProvider = Provider<int>((ref) {
  final u = ref.watch(currentUserProvider);
  return getWph(
    devilHornSkip: u.devilHornSkip,
    isGoldAutoBattle: u.isGoldAutoBattle,
    gameSpeed: u.gameSpeed,
    chronoBonus: u.chronoClass,
    equipHorn: u.horn,
    equipGoldenHorn: u.goldenHorn,
  ).round();
});

/// 当前用户真实 WPH（RWPH）
final theoreticalRwphProvider = Provider<int>((ref) {
  final u = ref.watch(currentUserProvider);
  return getRwph(
    gameSpeed: u.gameSpeed,
    chronoBonus: u.chronoClass,
    equipHorn: u.horn,
    equipGoldenHorn: u.goldenHorn,
  ).round();
});

/// 当前用户每日收入分项
final dailyIncomeProvider =
    Provider<({double colony, double autoBattle, double other, double total})>(
  (ref) {
    final u = ref.watch(currentUserProvider);
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
  },
);

// 重载信号

/// 切换/重命名用户，或数据被整体替换时变化
final userReloadSignalProvider = Provider<UserReloadSignal>((ref) {
  return (
    username: ref.watch(currentUsernameProvider),
    dataVersion: ref.watch(dataVersionProvider),
  );
});

/// [userReloadSignalProvider] 的值类型
typedef UserReloadSignal = ({String username, int dataVersion});

/// 让 `store.setXxx` 形式的 tear-off 保持一个 token 的长度：`ref.users.setXxx`。
///
/// 安全前提：`Notifier` 实例在 provider 生命周期内被 Riverpod 保留，而
/// keepAlive 保证该生命周期等于容器——捕获的 tear-off 不会失效。
extension UsersWidgetRef on WidgetRef {
  Users get users => read(usersProvider.notifier);
}
