import 'package:material_ui/material_ui.dart';

abstract class UIs extends StatelessWidget {
  static const padding = EdgeInsets.symmetric(horizontal: 16.0);

  static const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
  );

  static const cardTileColorAlpha = 127;

  /// 卡片内 ListTile 的最小高度与紧凑程度
  static const double cardTileMinHeight = 44.0;
  static const bool cardTileDense = false;

  /// 卡片主标题 / 副标题字号
  static const double cardTitleFontSize = 16.0;
  static const double cardSubtitleFontSize = 14.0;
  static Color cardSubtitleColor = Colors.grey[600]!;

  /// 卡片外边距（压缩卡片之间以及卡片内部的垂直间距）
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: 4.0,
    vertical: 2.0,
  );

  /// 卡片输入类组件的内边距与输入框内容内边距
  static const EdgeInsets cardFieldPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 2.0,
  );
  static const EdgeInsets cardFieldContentPadding = EdgeInsets.symmetric(
    vertical: 8.0,
  );
}
