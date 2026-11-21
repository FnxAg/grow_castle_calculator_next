import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/navigation/app_navigator.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/models.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:material_ui/material_ui.dart';

/// 工具页
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabTools)),
      body: ListView(
        padding: UIs.padding,
        children: [
          for (final kind in RankingKind.values)
            CardTile(
              leading: Icon(kind.icon),
              title: Text(rankingKindLabel(l10n, kind)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                context.openRanking(kind);
              },
            ),
          CardTile(
            leading: const Icon(Icons.calculate),
            title: Text(l10n.toolQuickCalculation),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.openQuickCalc();
            },
          ),
          CardTile(
            leading: const Icon(Icons.search),
            title: Text(l10n.toolSearch),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.openSearch();
            },
          ),
          CardTile(
            leading: const Icon(Icons.casino_outlined),
            title: Text(l10n.toolDragonSimulator),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.openDragonSimulator();
            },
          ),
          CardTile(
            leading: const Icon(Icons.compare_arrows),
            title: Text(l10n.toolItemComparer),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.openItemComparer();
            },
          ),
          CardTile(
            leading: const Icon(Icons.thumb_up),
            title: Text(l10n.toolBestLineCalc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.openBestLine();
            },
          ),
        ],
      ),
    );
  }
}
