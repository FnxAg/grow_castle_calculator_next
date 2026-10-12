import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// 收入来源「推波」tab
class WaveTab extends ConsumerStatefulWidget {
  const WaveTab({super.key});

  @override
  ConsumerState<WaveTab> createState() => _WaveTabState();
}

class _WaveTabState extends ConsumerState<WaveTab> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _doubleController(
    String key,
    double value,
    ValueChanged<double> onSave,
  ) {
    return _controllers.putIfAbsent(key, () {
      final c = TextEditingController(
        text: value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toString(),
      );
      c.addListener(() {
        onSave(double.tryParse(c.text) ?? 0.0);
        if (mounted) setState(() {});
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _hoursOf(String key, double stored) {
    final c = _controllers[key];
    if (c == null) return stored;
    return double.tryParse(c.text) ?? stored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider);
    final gabTime = _hoursOf('gabTime', user.gabTime);
    final tabTime = _hoursOf('tabTime', user.tabTime);
    final total = gabTime + tabTime;
    final errorText = total > 24.0 + 1e-9 ? 'Sum > 24h' : null;

    var waveIncomeWidgets = [
      ListTile(
        title: Text(l10n.labelGabAverageBonus),
        trailing: SizedBox(
          width: 80,
          child: SelectAllTextField(
            controller: _doubleController(
              'gabBonus',
              user.gabBonus,
              ref.users.setCurrentUserGabBonus,
            ),
            decoration: const InputDecoration(isDense: true, suffixText: '%'),
            keyboardType: TextInputType.number,
          ),
        ),
      ),
      ListTile(
        title: Text(l10n.labelDailyGabTime),
        trailing: SizedBox(
          width: 80,
          child: SelectAllTextField(
            controller: _doubleController(
              'gabTime',
              user.gabTime,
              ref.users.setCurrentUserGabTime,
            ),
            decoration: InputDecoration(
              isDense: true,
              suffixText: 'h',
              errorText: errorText,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ),
      ListTile(
        title: Text(l10n.labelDailyTabTime),
        trailing: SizedBox(
          width: 80,
          child: SelectAllTextField(
            controller: _doubleController(
              'tabTime',
              user.tabTime,
              ref.users.setCurrentUserTabTime,
            ),
            decoration: InputDecoration(
              isDense: true,
              suffixText: 'h',
              errorText: errorText,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ),
    ];
    return isMobile
        ? ListView(children: waveIncomeWidgets)
        : Column(children: waveIncomeWidgets);
  }
}
