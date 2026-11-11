import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:medify/app/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/core/theme/theme_service.dart';
import 'package:medify/features/history/presentation/cubit/history_cubit.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_cubit.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_cubit.dart';
import 'package:medify/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:medify/features/statistics/presentation/cubit/statistics_cubit.dart';
import 'package:medify/l10n/app_localizations.dart';

/// Global key to access [MyAppState] from anywhere.
final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final PreferencesService _prefsService;
  late final GoRouter _router;
  late ThemeMode _themeMode;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _prefsService = getIt<PreferencesService>();
    _router = buildRouter(_prefsService);
    getIt<AppMessenger>().router = _router;
    _themeMode = _prefsService.themeMode;

    ThemeService().registerThemeCallback((themeMode) {
      setState(() {
        _themeMode = themeMode;
      });
    });
  }

  void updateThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void setLocale(Locale locale) {
    _locale = locale;
  }

  ThemeData _resolveMaterialTheme(BuildContext context) {
    final Brightness brightness;
    switch (_themeMode) {
      case ThemeMode.light:
        brightness = Brightness.light;
      case ThemeMode.dark:
        brightness = Brightness.dark;
      case ThemeMode.system:
        brightness = MediaQuery.platformBrightnessOf(context);
    }
    return brightness == Brightness.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MedicineCubit>(
          create: (context) => getIt<MedicineCubit>(),
        ),
        BlocProvider<MedicineLogCubit>(
          create: (context) => getIt<MedicineLogCubit>(),
        ),
        BlocProvider<StatisticsCubit>(
          create: (context) => getIt<StatisticsCubit>(),
        ),
        BlocProvider<HistoryCubit>(create: (context) => getIt<HistoryCubit>()),
        // COMMENTED OUT FOR UPCOMING RELEASE
        // BlocProvider<ProfileCubit>(create: (context) => getIt<ProfileCubit>()),
        BlocProvider<SettingsCubit>(
          create: (context) => getIt<SettingsCubit>(),
        ),
      ],
      // iOS 26+ → native Liquid Glass via adaptive_platform_ui;
      // Android → Material 3 tinted theme. Theme wrapper keeps MedifyTokens
      // + ScaffoldMessenger available under CupertinoApp on iOS.
      child: AdaptiveApp.router(
        title: 'Medify',
        themeMode: _themeMode,
        materialLightTheme: AppTheme.lightTheme,
        materialDarkTheme: AppTheme.darkTheme,
        cupertinoLightTheme: AppTheme.cupertinoLight,
        cupertinoDarkTheme: AppTheme.cupertinoDark,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        scaffoldMessengerKey: getIt<AppMessenger>().scaffoldKey,
        routerConfig: _router,
        builder: (context, child) {
          return Theme(
            data: _resolveMaterialTheme(context),
            // CupertinoApp (iOS) has no Material ancestor; Material widgets
            // (TextField, ListTile) assert without one.
            child: Material(
              type: MaterialType.transparency,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
