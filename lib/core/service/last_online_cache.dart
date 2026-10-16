import 'dart:async';

import 'package:grow_castle_calculator_next/data/res/store.dart';

import 'api.dart';

/// 公会成员「上次在线」会话级缓存（按玩家名精确 key，TTL 15 分钟）。
///
/// - 条目存原始 queryDate，读取时用当前时间重新格式化（相对时间保持准确）。
/// - TTL 内：`cached()` 同步返回（含 '' = 封禁/无数据），失败条目返回 null；
///   `fetch()` 返回 null（页面已展示或此前查询失败，不发请求、不重放动画）。
/// - 过期/未命中/force：进入有界并发队列（[_maxConcurrent] 路并发），成功
///   覆盖缓存并返回新值，失败也写入负缓存，页面保留旧值。
/// - 同名并发去重（[_inflight]），跨页面实例共享同一请求。
class LastOnlineCache {
  LastOnlineCache._();

  static const Duration ttl = Duration(minutes: 15);

  static int get _maxConcurrent =>
      Stores.appSettingsStore.lastOnlineConcurrencyNotifier.value;

  static final Map<String, _Entry> _entries = {};

  static final Map<String, Future<String?>> _inflight = {};

  static final List<Future<void> Function()> _queue = [];
  static int _running = 0;

  /// 请求队列
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

  static String? cached(String name) {
    final entry = _entries[name];
    if (entry == null) return null;
    final queryDate = entry.queryDate;
    if (queryDate == null) return null;
    return PlayerApiService.formatLastOnline(queryDate, DateTime.now());
  }

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
        _entries[name] = _Entry(result.queryDate, DateTime.now());
        return PlayerApiService.formatLastOnline(
          result.queryDate,
          DateTime.now(),
        );
      }
      _entries[name] = _Entry(null, DateTime.now());
      return null;
    });
    _inflight[name] = future;
    future.whenComplete(() => _inflight.remove(name));
    return future;
  }
}

class _Entry {
  const _Entry(this.queryDate, this.fetchedAt);

  /// '' = 封禁/无数据，null = 查询失败
  final String? queryDate;
  final DateTime fetchedAt;
}
