import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/page/home.dart';
import 'package:grow_castle_calculator_next/view/widget/dynamic_color.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  ColorScheme? _lightDynamic;
  ColorScheme? _darkDynamic;
  Color defaultColor = Colors.blue;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _fetchDynamicColor();
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

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'GCC Next',
      theme: _lightTheme(_lightDynamic),
      darkTheme: _darkTheme(_darkDynamic),
      themeMode: _themeMode,
      home: MyHomePage(title: 'GCC Next', onToggleTheme: _toggleTheme),
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: child!,
        );
      },
    );
  }
}


