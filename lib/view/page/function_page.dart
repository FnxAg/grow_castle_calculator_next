import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/function/bonus_gold_calc.dart';
import 'package:grow_castle_calculator_next/view/page/function/income_page.dart';
import 'package:grow_castle_calculator_next/view/page/function/game_track_page.dart';
import 'package:grow_castle_calculator_next/view/page/function/wave_status_page.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 当前用户的更多信息与状态
class FunctionPage extends StatefulWidget {
  const FunctionPage({super.key});

  @override
  State<FunctionPage> createState() => _FunctionPageState();
}

class _FunctionPageState extends State<FunctionPage> {
  @override
  Widget build(BuildContext context) {
    final store = Stores.infoStore;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return UserPageScaffold(
      title: '功能',
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bolt),
            title: const Text('跳波状态'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WaveStatusPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.percent),
            title: Row(
              children: [
                const Text('推波收益计算'),
                const Spacer(),
                ValueListenableBuilder(
                  valueListenable: store.incomeNotifier,
                  builder: (context, value, child) {
                    return Text(
                      '${store.getCurrentUserGabBonus().toStringAsFixed(2)}%',
                      style: style,
                    );
                  },
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BonusGoldCalcPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: Row(
              children: [
                const Text('收入'),
                const Spacer(),
                ValueListenableBuilder(
                  valueListenable: store.incomeNotifier,
                  builder: (context, _, child) {
                    final totalIncome = store
                        .getCurrentUserDailyIncomeBreakdown()
                        .total;
                    return Text(
                      totalIncome.formatCompact(
                        fractionDigits: 2,
                        english: false,
                      ),
                      style: style,
                    );
                  },
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const IncomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.timeline),
            title: Row(
              children: [
                const Text('游戏轨迹'),
                const Spacer(),
                _RelativeTimeText(style: style),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const GameTrackPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 「游戏轨迹」右侧的相对时间，每秒自刷新。
///
/// 每秒 tick 的资源必须由**这个 widget 自己**持有，不能挂在外层
/// [_FunctionPageState] 上：这一段子树会被整体重建（横竖屏切换时
/// ShortWindowFallback 换布局分支、切换用户时 UserPageScaffold 的
/// KeyedSubtree 换 key），外层 State 存活而本 widget 是新的。若用外层 State
/// 持有的单订阅流（`Stream.periodic`），新实例会二次 listen 同一个流，抛
/// "Bad state: Stream has already been listened to."，整个 ListTile 被替换成
/// ErrorWidget —— 在 Android 上就是一块高度无界的灰块，且不会自愈。
class _RelativeTimeText extends StatefulWidget {
  const _RelativeTimeText({required this.style});

  final TextStyle? style;

  @override
  State<_RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<_RelativeTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 用户 id 每次 tick 重新读：切换用户后本 widget 不重建也能显示新用户的数据
    final lastTime = Stores.gameTrackStore.getLastRecordTime(
      Stores.infoStore.getCurrentUserId(),
    );
    final text = lastTime == null
        ? '无记录'
        : _formatRelativeTime(lastTime.toLocal(), DateTime.now());
    return Text(text, style: widget.style);
  }
}

String _formatRelativeTime(DateTime time, DateTime now) {
  final duration = now.difference(time);
  if (duration.inSeconds < 60) {
    return '${duration.inSeconds} 秒前';
  }
  if (duration.inMinutes < 60) {
    return '${duration.inMinutes} 分钟前';
  }
  if (duration.inHours < 24) {
    return '${duration.inHours} 小时前';
  }
  if (duration.inDays < 30) {
    return '${duration.inDays} 天前';
  }
  final months = duration.inDays ~/ 30;
  if (months < 12) {
    return '$months 月前';
  }
  final years = months ~/ 12;
  return '$years 年前';
}
