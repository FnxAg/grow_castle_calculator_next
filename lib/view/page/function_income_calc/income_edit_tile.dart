import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/model/userdata/user_data.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_field.dart';
import 'package:grow_castle_calculator_next/view/widget/card/cards.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip/pill_chip.dart';
import 'package:material_ui/material_ui.dart';

/// 收入参数行：卡片内直接编辑，输入合法即保存，失焦时回退非法输入
class IncomeEditTile extends ConsumerStatefulWidget {
  const IncomeEditTile({super.key, required this.field});

  final IncomeField field;

  @override
  ConsumerState<IncomeEditTile> createState() => _IncomeEditTileState();
}

class _IncomeEditTileState extends ConsumerState<IncomeEditTile> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _error;

  IncomeField get field => widget.field;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: field.inputText(ref.read(currentUserProvider)),
    );
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _commit(revertOnError: true);
  }

  /// 校验并保存；[revertOnError] 时非法输入回退为已保存的值
  void _commit({bool revertOnError = false}) {
    final user = ref.read(currentUserProvider);
    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (revertOnError) _reset(user);
      return;
    }
    final String? error;
    if (!field.digitsOnly && double.tryParse(text) == null) {
      error = AppLocalizations.of(context).errorValueNotNumber;
    } else {
      error = field.validate(user, text);
    }
    if (error != null) {
      setState(() => _error = error);
      if (revertOnError) _reset(user);
      return;
    }
    setState(() => _error = null);
    field.save(ref.read(usersProvider.notifier), text);
  }

  void _reset(UserData user) {
    _controller.text = field.inputText(user);
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    // 外部改动（非本框编辑）时同步显示值
    ref.listen(currentUserProvider, (previous, next) {
      if (_focusNode.hasFocus) return;
      final text = field.inputText(next);
      if (_controller.text != text) {
        _controller.text = text;
        if (_error != null) setState(() => _error = null);
      }
    });
    return CardField(
      title:
          field.label(l10n) +
          (field.suffixText.isEmpty ? '' : ' (${field.suffixText})') +
          (field.prefixText.isEmpty ? '' : ' (${field.prefixText})'),
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.numberWithOptions(decimal: !field.digitsOnly),
      inputFormatters: field.digitsOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      suffix: field == IncomeField.infiniteColony
          ? PillChip(text: (user.infiniteColony * 1000 / user.wave).format())
          : null,
      errorText: _error ?? field.error(user),
      onChanged: (_) => _commit(),
    );
  }
}
