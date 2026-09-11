import 'dart:async';

import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/function/bonus_gold_calc.dart';
import 'package:grow_castle_calculator_next/view/page/function/game_track_page.dart';
import 'package:grow_castle_calculator_next/view/page/function/income_page.dart';
import 'package:grow_castle_calculator_next/view/page/function/wave_status_page.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/current_user_guild.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/last_online.dart';
import 'package:material_ui/material_ui.dart';

/// 当前用户的功能页
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        store.currentUserNotifier,
        store.dataVersionNotifier,
      ]),
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: .start,
              children: [
                const Text('功能'),
                _AppBarInfo(),
              ],
            ),
          ),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.bolt),
                title: const Text('跳波状态'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WaveStatusPage(),
                    ),
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
                    MaterialPageRoute(
                      builder: (context) => const GameTrackPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final store = Stores.infoStore;
    return ListenableBuilder(
      listenable: Listenable.merge([
        store.lastOnlineNotifier,
        store.guildNotifier,
      ]),
      builder: (context, _) {
        final segments = <Widget>[
          CurrentUser(),
          LastOnline(),
          CurrentUserGuild(),
        ];
        return AppBarInfo(children: segments);
      },
    );
  }
}

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
