import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/page/tool/wiki/u_line/main_page.dart';
import 'package:material_ui/material_ui.dart';

class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolWiki)),
      body: ListView(
        children: [
          // U 装词条说明
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(l10n.wikiULine),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WikiULinePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}