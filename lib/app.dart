import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/page/home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(ColorScheme? dynamic, bool isDark) {
    final ColorScheme colorScheme = dynamic ?? 
      (isDark ? ColorScheme.dark() : ColorScheme.light());
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'GCC Next',
          theme: _buildTheme(lightDynamic, false),
          darkTheme: _buildTheme(darkDynamic, true),
          home: const MyHomePage(title: 'GCC Next'),
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


