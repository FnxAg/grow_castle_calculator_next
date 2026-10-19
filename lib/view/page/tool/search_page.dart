import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/page/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/widget/username_textfield.dart';
import 'package:material_ui/material_ui.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static String _search = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = _search;
  }

  @override
  void dispose() {
    _search = _controller.text;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolSearch)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NameTextField(
            controller: _controller,
            labelText: l10n.labelName,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_controller.text.isEmpty) {
                      return;
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PlayerDetailPage(playerName: _controller.text),
                      ),
                    );
                  },
                  label: Text(l10n.toolSearchUser),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_controller.text.isEmpty) {
                      return;
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            GuildDetailPage(guildName: _controller.text),
                      ),
                    );
                  },
                  label: Text(l10n.toolSearchGuild),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
