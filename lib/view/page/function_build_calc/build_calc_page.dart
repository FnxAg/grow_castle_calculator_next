import 'package:grow_castle_calculator_next/core/calc/gold_income.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/widget/formation_listtile.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/notice/top_notice.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容经济计算页
class BuildCalcPage extends ConsumerStatefulWidget {
  const BuildCalcPage({super.key});

  @override
  ConsumerState<BuildCalcPage> createState() => _FormationCalcPageState();
}

class _FormationCalcPageState extends ConsumerState<BuildCalcPage> {
  final Map<int, FocusNode> _numberFocusNodes = {};
  final Map<int, FocusNode> _textFocusNodes = {};
  final Map<int, TextEditingController> _numberControllers = {};
  final Map<int, TextEditingController> _textControllers = {};

  FocusNode _focusNodeFor(int id, Map<int, FocusNode> cache) {
    return cache.putIfAbsent(id, () => FocusNode());
  }

  TextEditingController _numberControllerFor(int id) {
    return _numberControllers.putIfAbsent(id, () {
      final c = TextEditingController(
        text: ref.read(currentUserProvider).numberValues[id] ?? '',
      );
      c.addListener(() => ref.users.setNumberValue(id, c.text));
      return c;
    });
  }

  TextEditingController _textControllerFor(int id) {
    return _textControllers.putIfAbsent(id, () {
      final c = TextEditingController(
        text: ref.read(currentUserProvider).textValues[id] ?? '',
      );
      c.addListener(() => ref.users.setTextValue(id, c.text));
      return c;
    });
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(userReloadSignalProvider, (_, _) {
      if (!mounted) return;
      reloadForCurrentUser();
    });
  }

  @override
  void dispose() {
    _discardCardCaches();
    super.dispose();
  }

  /// 丢弃按卡片 id 缓存的控制器与焦点
  void _discardCardCaches() {
    for (final node in _numberFocusNodes.values) {
      node.dispose();
    }
    for (final node in _textFocusNodes.values) {
      node.dispose();
    }
    for (final c in _numberControllers.values) {
      c.dispose();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _numberFocusNodes.clear();
    _textFocusNodes.clear();
    _numberControllers.clear();
    _textControllers.clear();
  }

  void _removeCard(int id) {
    _numberFocusNodes.remove(id)?.dispose();
    _textFocusNodes.remove(id)?.dispose();
    _numberControllers.remove(id)?.dispose();
    _textControllers.remove(id)?.dispose();
    ref.users.removeCard(id);
  }

  /// 切换用户：先丢弃上一个用户的输入缓存，重建后按新用户取值
  void reloadForCurrentUser() {
    _discardCardCaches();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cardIds = ref.watch(currentUserCardIdsProvider);

    final List<Widget> appBarActions = <Widget>[
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: l10n.tooltipAddEntry,
        onPressed: () => ref.users.addNewCard(),
      ),
    ];

    final Widget formationExpanded = cardIds.isEmpty
        ? Center(
            child: Text(
              l10n.emptyFormationHint,
              style: const TextStyle(color: Colors.grey),
            ),
          )
        : Expanded(
            child: ReorderableListView.builder(
              key: const PageStorageKey('formation_card_list'),
              itemCount: cardIds.length,
              padding: EdgeInsets.only(
                bottom: 8.0,
                left: UIs.padding.left,
                right: UIs.padding.right,
              ),
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final double elevation = 4.0 * animation.value;
                    return Material(
                      elevation: elevation,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(8.0),
                      child: IgnorePointer(child: child),
                    );
                  },
                  child: child,
                );
              },
              onReorderItem: (oldIndex, newIndex) {
                FocusManager.instance.primaryFocus?.unfocus();
                ref.users.reorderCard(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final id = cardIds[index];
                return FormationCardTile(
                  key: ValueKey(id),
                  id: id,
                  index: index,
                  textController: _textControllerFor(id),
                  numberController: _numberControllerFor(id),
                  textFocusNode: _focusNodeFor(id, _textFocusNodes),
                  numberFocusNode: _focusNodeFor(id, _numberFocusNodes),
                  onRemove: _removeCard,
                );
              },
              buildDefaultDragHandles: false,
              scrollDirection: .vertical,
            ),
          );

    final totalGold = ref.watch(currentUserTotalGoldProvider);
    final rTotalGold = ref.watch(currentUserRTotalGoldProvider);
    final gp = ref.watch(currentUserGpProvider);
    final gpCn = ref.watch(currentUserGpCnProvider);
    final username = ref.watch(currentUsernameProvider);
    final wave = ref.watch(currentUserWaveProvider);
    final tgStr = totalGold.formatCompact(
      fractionDigits: 2,
      english: context.isCompactUnitEnglish,
      traditional: context.isTraditionalChineseLocale,
    );
    final rtgStr = rTotalGold.formatCompact(
      fractionDigits: 2,
      english: context.isCompactUnitEnglish,
      traditional: context.isTraditionalChineseLocale,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabFormation), actions: appBarActions),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: UIs.padding,
              child: CardTile(
                title: Text(username),
                trailing: Wrap(
                  spacing: 2.0,
                  children: [
                    Tooltip(
                      message: l10n.totalGold,
                      child: PillChip(
                        text: totalGold.formatCompact(
                          fractionDigits: 2,
                          english: context.isCompactUnitEnglish,
                          traditional: context.isTraditionalChineseLocale,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: l10n.gp,
                      child: PillChip(text: gp.toStringAsFixed(3)),
                    ),
                    Tooltip(
                      message: l10n.gpCN,
                      child: PillChip(text: gpCn.toStringAsFixed(3)),
                    ),
                  ],
                ),
                onTap: () => showTopNotice(
                  context,
                  duration: const Duration(seconds: 5),
                  content: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: IntrinsicColumnWidth(),
                    },
                    defaultVerticalAlignment:
                        TableCellVerticalAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TableRow(
                        children: [
                          Text('${l10n.totalGold}:'),
                          Text('$tgStr ($rtgStr)'),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text('${l10n.gp}:'),
                          Text(
                            '${gp.toStringAsFixed(3)} (${calcGp(wave: wave, gold: rTotalGold).toStringAsFixed(3)})',
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text('${l10n.gpCN}:'),
                          Text(
                            '${gpCn.toStringAsFixed(3)} (${calcGpCN(wave: wave, gold: rTotalGold).toStringAsFixed(3)})',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            formationExpanded,
          ],
        ),
      ),
    );
  }
}
