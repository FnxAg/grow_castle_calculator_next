import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/colony_section.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_edit_tile.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_field.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/other_section.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/summary_bar.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/wave_section.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:material_ui/material_ui.dart';

/// 收入计算页
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardController;
  late final CurvedAnimation _cardAnimation;
  bool _showCard = true;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _cardAnimation.dispose();
    _cardController.dispose();
    super.dispose();
  }

  /// 根据滑动方向显示/隐藏底部汇总卡片
  void _setCardVisible(bool visible) {
    if (_showCard == visible) return;
    setState(() => _showCard = visible);
    if (visible) {
      _cardController.forward();
    } else {
      _cardController.reverse();
    }
  }

  /// 手势滑动
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          _setCardVisible(false);
        case ScrollDirection.forward:
          _setCardVisible(true);
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  /// 鼠标滚轮/触控板滚动
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && event.scrollDelta.dy != 0.0) {
      _setCardVisible(event.scrollDelta.dy < 0.0);
    }
  }

  Widget _buildList({required bool wide, required AppLocalizations l10n}) {
    final list = ListView(
      // 内容不足一屏时也接受拖动，卡片才能响应手势
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const IncomeEditTile(field: IncomeField.gabTime),
        const IncomeEditTile(field: IncomeField.tabTime),
        SectionHeader(l10n.tabIncomeWave),
        const WaveSection(),
        SectionHeader(l10n.tabIncomeColony),
        const ColonySection(),
        SectionHeader(l10n.tabIncomeOther),
        const OtherSection(),
      ],
    );
    if (wide) return list;
    return NotificationListener<UserScrollNotification>(
      onNotification: _onScrollNotification,
      child: list,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = context.isWideContent;
    final list = _buildList(wide: wide, l10n: l10n);
    final body = wide
        ? Row(
            children: [
              Expanded(flex: 6, child: list),
              const Expanded(flex: 4, child: IncomeSummaryBar()),
            ],
          )
        : Listener(
            onPointerSignal: _onPointerSignal,
            child: Stack(
              children: [
                Positioned.fill(child: list),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: !_showCard,
                    child: SizeTransition(
                      sizeFactor: _cardAnimation,
                      alignment: Alignment.topCenter,
                      child: const IncomeSummaryBar(),
                    ),
                  ),
                ),
              ],
            ),
          );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.tabIncome), _AppBarInfo()],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.tooltipInfo,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(l10n.tooltipInfo),
                    content: Text(l10n.dialogIncomeNotice),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.actionClose),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: KeyedSubtree(
          key: ValueKey(ref.watch(userReloadSignalProvider)),
          child: body,
        ),
      ),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = [
      AppBarItem.currentUser(),
      AppBarItem.currentUserTotalGold(),
      AppBarItem.currentUserDailyIncome(),
    ];
    return AppBarInfo(children: segments);
  }
}
