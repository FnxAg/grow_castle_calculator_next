import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';

/// 赛季进度指示按钮（AppBar action 区用）。
///
/// 原生 [IconButton]，文本只显示进度百分比（start 缺失无法计算进度时
/// 回退显示剩余时长）；点击弹出赛季详情（进度条 / 起止时间 / 剩余时间）。
/// 赛季起止时间已由 [_parseSeason] 换算为本地时区；无赛季结束时间时
/// 不渲染；组件内部每分钟自刷新一次。
class SeasonIndicator extends StatefulWidget {
  const SeasonIndicator({super.key, required this.notifier});

  final ValueListenable<SeasonRange?> notifier;

  @override
  State<SeasonIndicator> createState() => _SeasonIndicatorState();
}

class _SeasonIndicatorState extends State<SeasonIndicator> {
  /// 分钟精度：百分比与剩余时间每分钟刷新一次
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SeasonRange?>(
      valueListenable: widget.notifier,
      builder: (context, season, _) {
        if (season == null) return const SizedBox.shrink();
        final end = season.end;
        if (end == null) return const SizedBox.shrink();
        return IconButton(
          tooltip: '赛季进度',
          icon: Row(
            children: [
              Icon(Icons.timer),
              // const SizedBox(width: 2.0),
              Text(
                _label(season, end),
                style: TextStyle(
                  // fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          onPressed: () => _showDetail(season, end),
        );
      },
    );
  }

  /// 只显示百分比；start 缺失（无法计算进度）时回退显示剩余时长
  String _label(SeasonRange season, DateTime end) {
    final start = season.start;
    if (start == null) {
      return PlayerApiService.formatSeasonRemaining(end, DateTime.now());
    }
    final total = end.difference(start).inMilliseconds;
    if (total <= 0) return '已结束';
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    final percent = (elapsed / total * 100).clamp(0, 100).round();
    return '$percent%';
  }

  static double _progress(SeasonRange season, DateTime end, DateTime now) {
    final start = season.start;
    if (start == null) return 0;
    final total = end.difference(start).inMilliseconds;
    if (total <= 0) return 0;
    return (now.difference(start).inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// "年-月-日 时:分:秒"（时间已换算为本地时区）
  static String _fmt(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  /// 赛季详情弹窗：进度条 + 起止时间 + 剩余时间
  void _showDetail(SeasonRange season, DateTime end) {
    final now = DateTime.now();
    final start = season.start;
    showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('赛季进度'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (start != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: _progress(season, end, now),
                    minHeight: 8.0,
                  ),
                ),
                _detailRow('开始', _fmt(start), scheme),
              ],
              _detailRow('结束', _fmt(end), scheme),
              _detailRow(
                '剩余',
                PlayerApiService.formatSeasonRemaining(end, now),
                scheme,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 16.0),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
