import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_provider.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/main_shell.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, this.lightDynamic, this.darkDynamic});

  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  static const Color defaultColor = Colors.blue;

  /// 简繁判定
  static Locale _resolveLocale(
    List<Locale>? preferredLocales,
    Iterable<Locale> supportedLocales,
  ) {
    for (final locale in preferredLocales ?? const <Locale>[]) {
      if (locale.languageCode != 'zh') break;
      final isTraditional =
          locale.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(locale.countryCode);
      final wantedScript = isTraditional ? 'Hant' : null;
      for (final supported in supportedLocales) {
        if (supported.languageCode == 'zh' &&
            supported.scriptCode == wantedScript) {
          return supported;
        }
      }
      break;
    }
    return basicLocaleListResolution(preferredLocales, supportedLocales);
  }

  String? get platformFontFamily {
    if (Platform.isWindows) {
      return 'Segoe UI';
    }
    return null;
  }

  List<String>? get platformFontFallback {
    if (Platform.isWindows) {
      return const ['Microsoft YaHei UI'];
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
      ref.read(usersProvider.notifier).flush();
    }
  }

  (ThemeData, ThemeData) _buildThemeData(
    ColorScheme lightDynamic,
    ColorScheme darkDynamic,
  ) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightDynamic,
      fontFamily: platformFontFamily,
      fontFamilyFallback: platformFontFallback,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkDynamic,
      fontFamily: platformFontFamily,
      fontFamilyFallback: platformFontFallback,
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
    final appSettings = Stores.appSettingsStore;
    return ListenableBuilder(
      listenable: Listenable.merge([
        appSettings.themeModeNotifier,
        appSettings.languageNotifier,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: 'GCC Next',
          theme: lightTheme,
          darkTheme: darkTheme,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: _resolveLocale,
          locale: appSettings.languageNotifier.value.locale,
          themeMode: appSettings.themeModeNotifier.value,
          home: const MainShell(),
          builder: (context, child) {
            Widget content = GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: child!,
            );
            if (isDesktopPlatform()) {
              content = Overlay.wrap(
                child: SelectionArea(
                  key: ValueKey(appSettings.languageNotifier.value),
                  child: content,
                ),
              );
            }
            if (!Platform.isAndroid) {
              return content;
            }
            // Flutter 按“顶部注解管状态栏、底部注解管导航栏”合并样式，
            // AppBar 自带的注解负责状态栏，这里只接管导航栏。
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: _navigationBarStyle(Theme.of(context)),
              child: content,
            );
          },
        );
      },
    );
  }
}

/// Android 系统导航栏样式跟随应用内主题，而不是系统主题。
///
/// 三键导航时系统会按自己的深浅状态给导航栏铺对比度底色，应用内切到深色
/// 而系统仍是浅色时就会出现白色横条。这里显式声明导航栏的样式：
///
/// - [SystemUiOverlayStyle.systemNavigationBarColor] 在 Android 15 以下生效；
///   Android 15+ 强制 edge-to-edge，颜色被系统忽略，导航栏透明。
/// - [SystemUiOverlayStyle.systemNavigationBarContrastEnforced] 关闭系统对比度
///   蒙层（API 29+），它跟随系统而不是应用主题。
/// - [SystemUiOverlayStyle.systemNavigationBarIconBrightness] 决定导航按钮的明暗。
SystemUiOverlayStyle _navigationBarStyle(ThemeData theme) {
  final bool isDark = theme.brightness == Brightness.dark;
  // 与 Material 3 NavigationBar 的默认底色一致，动态取色时也能跟随。
  final Color color = theme.colorScheme.surfaceContainer;
  return SystemUiOverlayStyle(
    systemNavigationBarColor: color,
    systemNavigationBarDividerColor: color,
    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
