import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 桌面小组件数据快照：把当前用户的展示数据（用户名 / 总波数 / 赛季波数 /
/// 在线情况）以 JSON 形式写入应用文件目录，供原生侧 [AppWidgetProvider] 读取。
///
/// - 原生侧不解析 Hive 二进制（格式不稳定 + 锁文件），统一走这个 JSON 旁路；
/// - 写入为 fire-and-forget：异步落盘、内部 try/catch，绝不阻塞 store 热路径、
///   绝不向调用方抛异常（如无插件环境）；
/// - 内容与上一次相同则跳过写盘，合并 `flush()` 等冗余调用。
/// 文件位置：`getApplicationSupportDirectory()`（Android 即 `context.filesDir`）。
abstract final class WidgetSnapshot {
  static const String fileName = 'widget_state.json';

  /// 目录解析缓存：首次解析后复用
  static Future<Directory>? _dirFuture;

  /// 上一次写入的完整 JSON 文本；内容未变时跳过写盘
  static String? _lastJson;

  /// 记录当前用户快照。参数均为展示字段：`lastOnline` 为空字符串表示未查询过；
  /// [isDefault] 为默认用户标记（userId == 0），原生侧据此显示引导态而非联网抓取。
  static void write({
    required String username,
    required int wave,
    required int seasonWave,
    required String lastOnline,
    bool isDefault = false,
  }) {
    try {
      final json = jsonEncode({
        'username': username,
        'wave': wave,
        'seasonWave': seasonWave,
        'lastOnline': lastOnline,
        'isDefault': isDefault,
        // 诊断用（原生侧不依赖）
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      if (json == _lastJson) {
        return;
      }
      _lastJson = json;
      unawaited(_doWrite(json));
    } catch (e) {
      debugPrint('WidgetSnapshot.write failed: $e');
    }
  }

  static Future<void> _doWrite(String json) async {
    try {
      final dir = _dirFuture ??= getApplicationSupportDirectory();
      final file = File('${(await dir).path}/$fileName');
      await file.writeAsString(json, flush: true);
    } catch (e) {
      debugPrint('WidgetSnapshot write failed: $e');
    }
  }
}
