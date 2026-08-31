import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Stores.appSettingsStore.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'GCC Next',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: widget.lightDynamic ??
                ColorScheme.fromSeed(
                  seedColor: defaultColor,
                  brightness: Brightness.light,
                ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: widget.darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: defaultColor,
                  brightness: Brightness.dark,
                ),
          ),
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


