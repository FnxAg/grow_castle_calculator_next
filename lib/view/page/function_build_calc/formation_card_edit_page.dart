import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:material_ui/material_ui.dart';

/// 阵容条目编辑页
class FormationCardEditPage extends ConsumerStatefulWidget {
  const FormationCardEditPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<FormationCardEditPage> createState() =>
      _FormationCardEditPageState();
}

class _FormationCardEditPageState extends ConsumerState<FormationCardEditPage> {
  late final TextEditingController _textController;
  late final TextEditingController _numberController;
  final FocusNode _textFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _textController =
        TextEditingController(text: user.textValues[widget.id] ?? '')
          ..addListener(
            () => ref.users.setTextValue(widget.id, _textController.text),
          );
    _numberController =
        TextEditingController(text: user.numberValues[widget.id] ?? '')
          ..addListener(
            () => ref.users.setNumberValue(widget.id, _numberController.text),
          );
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _numberFocusNode.dispose();
    _textController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  String _nameLabel(AppLocalizations l10n) => widget.id == 1
      ? l10n.nameLabelCastle
      : widget.id == 2
      ? l10n.nameLabelTownArcher
      : l10n.nameLabelGeneric;

  /// 删除当前条目（城堡与城弓固定存在，不可删除）
  void _confirmRemove() {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.actionDelete),
        content: Text(l10n.dialogDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.users.removeCard(widget.id);
              navigator.pop();
            },
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final applied = ref.watch(applyFlagProvider(widget.id));
    final removable = widget.id != 1 && widget.id != 2;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleEditFormationEntry)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: UIs.padding,
          children: [
            CardField(
              title: _nameLabel(l10n),
              controller: _textController,
              focusNode: _textFocusNode,
              keyboardType: TextInputType.text,
            ),
            CardField(
              title: l10n.labelLevel,
              controller: _numberController,
              focusNode: _numberFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SwitchCardTile(
              title: Text(applied ? l10n.actionApplied : l10n.actionNotApplied),
              value: applied,
              onChanged: (value) => ref.users.setApplyFlag(widget.id, value),
            ),
            if (removable) ...[
              const SizedBox(height: 24.0),
              CardTile(
                title: Text(
                  l10n.actionDelete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: _confirmRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
