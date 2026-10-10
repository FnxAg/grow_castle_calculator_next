/// 用户数据的 Hive 网关
library;

import 'package:grow_castle_calculator_next/model/userdata/user_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 一次全量读取的结果
class UserSnapshot {
  const UserSnapshot({
    required this.users,
    required this.currentUserId,
    required this.nextUserId,
  });

  /// userId -> 用户数据
  final Map<int, UserData> users;

  /// 当前用户 id
  final int currentUserId;

  /// 下一个可分配的用户 id
  final int nextUserId;
}

class UserDataRepository {
  static const String usersBoxName = 'user_data';
  static const String metaBoxName = 'user_meta';
  static const String metaCurrentUserIdKey = 'currentUserId';
  static const String metaNextUserIdKey = 'nextUserId';

  /// box 在构造时解析
  final Box _usersBox = Hive.box(usersBoxName);
  final Box _metaBox = Hive.box(metaBoxName);

  /// 全量读取所有用户，并完成 schema 迁移与两个 meta 键的兜底
  UserSnapshot readAll() {
    final users = <int, UserData>{};

    for (final key in _usersBox.keys) {
      final rawValue = _usersBox.get(key);
      if (key is int && rawValue is Map) {
        var raw = Map<dynamic, dynamic>.from(rawValue);
        // 旧版本数据缺少新字段，逐级迁移并一次性写回磁盘
        if (UserData.isOutdated(raw)) {
          raw = UserData.migrate(raw);
          _usersBox.put(key, raw);
        }
        users[key] = UserData.fromMap(raw);
      }
    }

    if (users.isEmpty) {
      // 空库兜底时，建 0 号默认用户并落盘
      final defaultUser = UserData(username: 'default');
      writeUser(0, defaultUser);
      writeMeta(currentUserId: 0, nextUserId: 1);
      return UserSnapshot(
        users: {0: defaultUser},
        currentUserId: 0,
        nextUserId: 1,
      );
    }

    final savedNextUserId = _metaBox.get(metaNextUserIdKey);
    final nextUserId = savedNextUserId is int
        ? savedNextUserId
        : users.keys.reduce((a, b) => a > b ? a : b) + 1;

    final savedCurrentUserId = _metaBox.get(metaCurrentUserIdKey);
    final currentUserId =
        savedCurrentUserId is int && users.containsKey(savedCurrentUserId)
            ? savedCurrentUserId
            : users.containsKey(0)
                ? 0
                : users.keys.first;

    return UserSnapshot(
      users: users,
      currentUserId: currentUserId,
      nextUserId: nextUserId,
    );
  }

  /// 写入单个用户（key = userId）
  void writeUser(int userId, UserData data) {
    _usersBox.put(userId, data.toMap());
  }

  /// 删除单个用户
  void deleteUser(int userId) {
    _usersBox.delete(userId);
  }

  /// 写入 currentUserId / nextUserId
  void writeMeta({required int currentUserId, required int nextUserId}) {
    _metaBox.put(metaCurrentUserIdKey, currentUserId);
    _metaBox.put(metaNextUserIdKey, nextUserId);
  }
}
