import 'package:material_ui/material_ui.dart';

class SubtitlePillWrap extends StatelessWidget {
  final List<Widget> children;

  const SubtitlePillWrap({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4.0,
      runSpacing: 2.0,
      children: children,
    );
  }
}
