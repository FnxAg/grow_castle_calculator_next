import 'package:material_ui/material_ui.dart';

abstract class UIs extends StatelessWidget {
  static const padding = EdgeInsets.symmetric(horizontal: 16.0);

  static const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
  );

  static const cardTileColorAlpha = 127;
}