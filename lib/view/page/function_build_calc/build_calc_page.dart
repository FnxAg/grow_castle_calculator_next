import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/widget/formation_listtile.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/widget/formation_summary_bar.dart';
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
  static bool _viewMode = false;

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
    final isWide = context.isWideContent;
    final l10n = AppLocalizations.of(context);
    final cardIds = ref.watch(currentUserCardIdsProvider);
    final List<Widget> actions = <Widget>[
      IconButton(
        icon: Icon(_viewMode ? Icons.edit : Icons.visibility),
        tooltip: _viewMode ? l10n.tooltipInputMode : l10n.tooltipViewMode,
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _viewMode = !_viewMode);
        },
      ),
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: l10n.tooltipAddEntry,
        onPressed: () => ref.users.addNewCard(),
      ),
    ];
    final Widget formationExpanded = Expanded(
      flex: isWide ? 6 : 1,
      child: cardIds.isEmpty
          ? Center(
              child: Text(
                l10n.emptyFormationHint,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ReorderableListView.builder(
              key: const PageStorageKey('formation_card_list'),
              itemCount: cardIds.length,
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
                  viewMode: _viewMode,
                  onRemove: _removeCard,
                );
              },
              buildDefaultDragHandles: false,
              scrollDirection: .vertical,
            ),
    );
    const Widget formationSummaryBar = FormationSummaryBar();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.tabFormation), _AppBarInfo()],
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: isWide
            ? Row(
                children: [
                  formationExpanded,
                  const Expanded(flex: 4, child: formationSummaryBar),
                ],
              )
            : Column(children: [formationExpanded, formationSummaryBar]),
      ),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo();

  @override
  Widget build(BuildContext context) {
    final List<Widget> segments = <Widget>[
      AppBarItem.currentUser(),
    ];
    return AppBarInfo(children: segments);
  }
}
