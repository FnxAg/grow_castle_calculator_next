import 'dart:async';

import 'package:grow_castle_calculator_next/data/res/store.dart';

import 'api.dart';

/// 公会成员「上次在线」会话级缓存（按玩家名精确 key，TTL 15 分钟）。
///
/// - 条目存原始 queryDate，读取时用当前时间重新格式化（相对时间保持准确）。
/// - TTL 内：`cached()` 同步返回（含 '' = 封禁/无数据），`fetch()` 返回 null
///   （页面已展示，不发请求、不重放动画）。
/// - 过期/未命中/force：进入有界并发队列（[_maxConcurrent] 路并发），成功
///   覆盖缓存并返回新值，失败返回 null（页面保留旧值）。
/// - 同名并发去重（[_inflight]），跨页面实例共享同一请求。
class LastOnlineCache {
  LastOnlineCache._();

  /// 缓存有效期（与公开榜单一致）
  static const Duration ttl = Duration(minutes: 15);

  /// 同时进行的网络查询上限（设置页可调，每次发放任务时动态读取）
  static int get _maxConcurrent =>
      Stores.appSettingsStore.lastOnlineConcurrencyNotifier.value;

  static final Map<String, _Entry> _entries = {};

  /// 进行中的拉取（玩家名 → Future）：同名并发调用复用同一请求
  static final Map<String, Future<String?>> _inflight = {};

  // ── 有界并发队列 ──────────────────────────────────────────────

  static final List<Future<void> Function()> _queue = [];
  static int _running = 0;

  /// 将 [task] 入队，保证并发不超过 [_maxConcurrent]，按入队顺序发出
  static Future<T> _runQueued<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue.add(() async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    _pump();
    return completer.future;
  }

  static void _pump() {
    while (_running < _maxConcurrent && _queue.isNotEmpty) {
      _running++;
      final task = _queue.removeAt(0);
      task().whenComplete(() {
        _running--;
        _pump();
      });
    }
  }

  /// 同步读取：返回格式化后的展示串（'' = 封禁/无数据），未缓存返回 null。
  /// 过期条目也返回（页面先展示旧值，fetch 后台刷新）。
  static String? cached(String name) {
    final entry = _entries[name];
    if (entry == null) return null;
    return PlayerApiService.formatLastOnline(entry.queryDate, DateTime.now());
  }

  /// 异步获取：TTL 内新鲜缓存直接返回 null（页面已展示，无需刷新）；
  /// 过期/未命中/[force] 排队请求，成功返回新值，失败（QueryError）返回 null。
  static Future<String?> fetch(String name, {bool force = false}) {
    final entry = _entries[name];
    final now = DateTime.now();
    if (!force && entry != null && now.difference(entry.fetchedAt) <= ttl) {
      return Future.value(null);
    }
    final inflight = _inflight[name];
    if (inflight != null) return inflight;
    final future = _runQueued(() async {
      final result = await PlayerApiService.query(name);
      if (result is PlayerQueryResult) {
        // 封禁成员（queryDate 为空）同样入缓存：TTL 内不重复查询。
        // fetchedAt 记查询完成时刻（队列等待时间不计入 TTL）
        _entries[name] = _Entry(result.queryDate, DateTime.now());
        return PlayerApiService.formatLastOnline(
          result.queryDate,
          DateTime.now(),
        );
      }
      return null; // QueryError：不覆盖缓存，页面保留旧值
    });
    _inflight[name] = future;
    future.whenComplete(() => _inflight.remove(name));
    return future;
  }
}

class _Entry {
  const _Entry(this.queryDate, this.fetchedAt);

  /// 原始"上次在线"日期串（'' = 封禁/无数据）
  final String queryDate;
  final DateTime fetchedAt;
}
