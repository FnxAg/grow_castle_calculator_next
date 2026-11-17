import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 历史日期查询按钮（含返回当前赛季）
class HistoryDateActions extends StatelessWidget {
  const HistoryDateActions({
    super.key,
    required this.date,
    required this.onChanged,
  });

  /// 已选历史日期；null 表示当前赛季
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: l10n.tooltipHistoryData,
          onPressed: () => _pick(context),
        ),
        if (date != null)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.tooltipBackToCurrentSeason,
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  /// 官方 API 仅支持近 90 天（含今天）
  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(const Duration(days: 89));
    var initialDate = date ?? today;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(today)) initialDate = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
      helpText: AppLocalizations.of(context).historyDateHelp,
    );
    if (picked == null || !context.mounted) return;

    final current = date;
    if (current != null &&
        picked.year == current.year &&
        picked.month == current.month &&
        picked.day == current.day) {
      return;
    }
    onChanged(picked);
  }
}
