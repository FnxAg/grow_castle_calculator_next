import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/main_shell.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.lightDynamic, this.darkDynamic});

  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Color defaultColor = Colors.blue;

  String? get platformFontFamily {
    if (Platform.isWindows) {
      return 'Segoe UI, Microsoft YaHei UI';
    } else if (Platform.isAndroid) {
      return null;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      Stores.infoStore.flush();
    }
  }

  (ThemeData, ThemeData) _buildThemeData(
      ColorScheme lightDynamic, ColorScheme darkDynamic) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightDynamic,
      fontFamily: platformFontFamily,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkDynamic,
      fontFamily: platformFontFamily,
    );

    return (lightTheme, darkTheme);
  }

  @override
  Widget build(BuildContext context) {
    final (ThemeData lightTheme, ThemeData darkTheme) = _buildThemeData(
      widget.lightDynamic ??
          ColorScheme.fromSeed(
            seedColor: defaultColor,
            brightness: Brightness.light,
          ),
      widget.darkDynamic ??
          ColorScheme.fromSeed(
            seedColor: defaultColor,
            brightness: Brightness.dark,
          ),
    );
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Stores.appSettingsStore.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'GCC Next',
          theme: lightTheme,
          darkTheme: darkTheme,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          locale: const Locale('zh', 'CN'),
          themeMode: themeMode,
          home: const MainShell(),
          builder: (context, child) {
            Widget content = GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: child!,
            );
            // 桌面端全局文本可选（鼠标拖选即可复制榜单分数/详情数值等）；
            // 绝不在移动端开启：SelectionArea 的 touch 长按选词会与
            // ReorderableListView 的长按拖拽重排在手势竞技场互抢
            if (isDesktopPlatform()) {
              // SelectionArea 需要 Overlay 祖先（选择工具栏/手柄挂在上面），
              // 而 builder 的产物位于 Navigator（及其 Overlay）**之上**，
              // 直接包会抛 "No Overlay widget found"。Overlay.wrap 是框架提供
              // 的公开工具：补一个 Overlay 并把内容放进它的 entry，
              // 于是导航栈整体都落在可选范围内
              content = Overlay.wrap(child: SelectionArea(child: content));
            }
            return content;
          },
        );
      },
    );
  }
}
