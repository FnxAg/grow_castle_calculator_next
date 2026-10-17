import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/src/item_lines.dart';
import 'package:grow_castle_calculator_next/core/src/u_line_wiki.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:grow_castle_calculator_next/view/widget/summary_row/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// U 词条详情
class WikiULineDetailPage extends StatelessWidget {
  const WikiULineDetailPage({super.key, required this.line});

  final ItemLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = line.wikiEntry;
    final textTheme = Theme.of(context).textTheme;
    final allowedTypes = line.allowedTypes;
    return Scaffold(
      appBar: AppBar(title: Text(entry?.title ?? line.label)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SummaryCard(
            children: <Widget>[
              SummaryRow(
                leadingIcon: Icons.translate,
                title: Text(l10n.wikiLineEnglishName),
                trailing: SummaryRowValueText(text: line.label),
              ),
              SummaryRow(
                leadingIcon: Icons.straighten,
                title: Text(l10n.wikiLineRange),
                trailing: SummaryRowValueText(text: _rangeText(line)),
              ),
            ],
          ),
          if (entry != null) ...[
            SectionHeader(l10n.wikiAdaptedUnits),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(entry.unit ?? '—'),
            ),
          ],
          if (allowedTypes != null) ...[
            SectionHeader(l10n.wikiLineTypes),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (final type in allowedTypes)
                    PillChip(text: Text(_typeLabel(l10n, type))),
                ],
              ),
            ),
          ],
          SectionHeader(l10n.wikiLineDescription),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entry == null
                  ? [Text(l10n.wikiNoEntry, style: textTheme.bodyMedium)]
                  : [
                      Text(entry.summary ?? '—', style: textTheme.bodyLarge),
                      for (final detail in entry.details) ...[
                        const SizedBox(height: 12.0),
                        Text(detail, style: textTheme.bodyMedium),
                      ],
                    ],
            ),
          ),
        ],
      ),
    );
  }

  String _rangeText(ItemLine line) {
    final range = line.overallValueRange();
    if (range == null) return '—';
    final (min, max) = range;
    final suffix = line.isPercent ? '%' : '';
    final digits = line.isPercent ? 1 : 2;
    final minText = '${min.format(fractionDigits: digits)}$suffix';
    if (min == max) return minText;
    return '$minText ~ ${max.format(fractionDigits: digits)}$suffix';
  }
}

String _typeLabel(AppLocalizations l10n, ItemType type) => switch (type) {
  ItemType.bow => l10n.itemTypeBow,
  ItemType.sword => l10n.itemTypeSword,
  ItemType.staff => l10n.itemTypeStaff,
  ItemType.hammer => l10n.itemTypeHammer,
  ItemType.ring => l10n.itemTypeRing,
  ItemType.necklace => l10n.itemTypeNecklace,
  ItemType.bracelet => l10n.itemTypeBracelet,
  ItemType.earrings => l10n.itemTypeEarrings,
};
