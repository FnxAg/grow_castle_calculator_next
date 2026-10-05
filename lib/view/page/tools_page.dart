import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/page/tool/best_line_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool/dragon_simulator_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool/item_comparer.dart';
import 'package:grow_castle_calculator_next/view/page/tool/ranking_page.dart';
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
        children: [
          for (final kind in RankingKind.values)
            ListTile(
              leading: Icon(kind.icon),
              title: Text(rankingKindLabel(l10n, kind)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RankingPage(kind: kind),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.casino_outlined),
            title: Text(l10n.toolDragonSimulator),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DragonSimulatorPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: Text(l10n.toolItemComparer),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ItemComparerPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.thumb_up),
            title: Text(l10n.toolBestLineCalc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BestLineCalcPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
