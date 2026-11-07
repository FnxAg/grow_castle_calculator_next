import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

/// 卡片下拉框：外观与 CardField 一致
class CardDropdown<T> extends StatelessWidget {
  const CardDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = true,
  });

  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: UIs.cardMargin,
      color: ListTileTheme.of(context).tileColor,
      shape: UIs.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: UIs.cardFieldPadding,
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: isExpanded,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: UIs.cardFieldContentPadding,
            labelText: title,
          ),
        ),
      ),
    );
  }
}
