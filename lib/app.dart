import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/shell/main_shell.dart';
import 'package:grow_castle_calculator_next/view/widget/dynamic_color.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  ColorScheme? _lightDynamic;
  ColorScheme? _darkDynamic;
  Color defaultColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDynamicColor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 退到后台/即将终止前立即落盘，避免延迟保存的数据丢失
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      Stores.infoStore.flush();
    }
  }

  ThemeData _lightTheme(ColorScheme? dynamic) {
    return ThemeData(
      colorScheme: dynamic ?? ColorScheme.fromSeed(seedColor: defaultColor, brightness: Brightness.light),
      useMaterial3: true,
    );
  }

  ThemeData _darkTheme(ColorScheme? dynamic) {
    return ThemeData(
      colorScheme: dynamic ?? ColorScheme.fromSeed(seedColor: defaultColor, brightness: Brightness.dark),
      useMaterial3: true,
    );
  }

  Future<void> _fetchDynamicColor() async {
    final light = await NativeDynamicColorUtil.getDynamicColorScheme(Brightness.light);
    final dark = await NativeDynamicColorUtil.getDynamicColorScheme(Brightness.dark);
    setState(() {
      _lightDynamic = light;
      _darkDynamic = dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Stores.appSettingsStore.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'GCC Next',
          theme: _lightTheme(_lightDynamic),
          darkTheme: _darkTheme(_darkDynamic),
          themeMode: themeMode,
          home: const MainShell(),
          builder: (context, child) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: child!,
            );
          },
        );
      },
    );
  }
}


