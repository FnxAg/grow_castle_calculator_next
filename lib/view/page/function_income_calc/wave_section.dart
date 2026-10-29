import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_edit_tile.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_field.dart';
import 'package:material_ui/material_ui.dart';

/// 收入来源「推波」
class WaveSection extends StatelessWidget {
  const WaveSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IncomeEditTile(field: IncomeField.gabBonus),
      ],
    );
  }
}
