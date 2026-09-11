import 'package:material_ui/material_ui.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.actions = const [],
    required this.trailing,
  });

  final IconData leadingIcon;
  final Widget title;
  final List<Widget> actions;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(leadingIcon, size: 20.0, color: colorScheme.primary),
        const SizedBox(width: 8.0),
        title,
        const SizedBox(width: 8.0),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 4.0),
          actions[i],
        ],
        const Spacer(),
        trailing,
      ],
    );
  }
}

class SummaryRowValueText extends StatelessWidget {
  const SummaryRowValueText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }
}
