import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_info.dart';
import 'package:grow_castle_calculator_next/view/widget/app_bar/app_bar_item.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/widget/formation_listtile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容经济计算页
class BuildCalcPage extends ConsumerWidget {
  const BuildCalcPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = context.isWideContent;
    final l10n = AppLocalizations.of(context);
    final cardIds = ref.watch(currentUserCardIdsProvider);

    final List<Widget> appBarActions = <Widget>[
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: l10n.tooltipAddEntry,
        onPressed: () => ref.users.addNewCard(),
      ),
    ];

    final Widget floatingActions = FloatingActionButton(
      onPressed: () => ref.users.addNewCard(),
      tooltip: l10n.tooltipAddEntry,
      child: const Icon(Icons.add),
    );

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
              bottom: 72 + MediaQuery.of(context).padding.bottom,
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
              ref.users.reorderCard(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final id = cardIds[index];
              return FormationCardTile(
                key: ValueKey(id),
                id: id,
                index: index,
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: .start,
          children: [Text(l10n.tabFormation), appBarInfo],
        ),
        actions: isWide ? appBarActions : null,
      ),
      floatingActionButton: isWide ? null : floatingActions,
      body: SafeArea(top: false, child: formationExpanded),
    );
  }
}
