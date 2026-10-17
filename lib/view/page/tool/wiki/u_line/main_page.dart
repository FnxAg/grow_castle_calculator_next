import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/core/src/u_line_wiki.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/page/tool/wiki/u_line/detail_page.dart';
import 'package:material_ui/material_ui.dart';

class WikiULinePage extends StatelessWidget {
  const WikiULinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wikiULine)),
      body: ListView(
        children: [
          for (final line in ItemLine.purpleLines)
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text(line.wikiEntry?.title ?? line.label),
              subtitle: Text(line.wikiEntry?.summary ?? l10n.wikiNoEntry),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WikiULineDetailPage(line: line),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
