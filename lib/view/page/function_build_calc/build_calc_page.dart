import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/widget/formation_listtile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        : ReorderableListView.builder(
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
          );

    final appBarInfo = AppBarInfo(
      children: <Widget>[
        AppBarItem.currentUser(),
        AppBarItem.currentUserTotalGold(),
        AppBarItem.currentUserGp(),
        AppBarItem.currentUserGpCn(),
      ],
    );
    // 随系统字号给出的信息行高度
    final infoRowHeight =
        MediaQuery.textScalerOf(context).scale(12.0) * 1.5 + 10.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabFormation),
        actions: appBarActions,
        // 信息行独占一整行，避免和标题/返回键/操作按钮抢宽度
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(infoRowHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: appBarInfo,
            ),
          ),
        ),
      ),
      body: SafeArea(top: false, child: formationExpanded),
    );
  }
}
