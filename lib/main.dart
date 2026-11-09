import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/di/injection_container.dart';
import 'core/services/navigation_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/theme_service.dart';
import 'core/themes/app_theme.dart';
import 'presentation/blocs/medicine/medicine_cubit.dart';
import 'presentation/blocs/medicine_log/medicine_log_cubit.dart';
// COMMENTED OUT FOR UPCOMING RELEASE
// import 'presentation/blocs/profile/profile_cubit.dart';
import 'presentation/blocs/settings/settings_cubit.dart';
import 'presentation/blocs/statistics/statistics_cubit.dart';
import 'presentation/blocs/history/history_cubit.dart';
import 'presentation/pages/main_navigation_page.dart';
import 'presentation/pages/onboarding_page.dart';

// Global key to access MyApp state from anywhere
final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await initializeDependencies();

  runApp(MyApp(key: myAppKey));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PreferencesService _prefsService;
  late ThemeMode _themeMode;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _prefsService = getIt<PreferencesService>();
    _themeMode = _prefsService.themeMode;

    // Register theme change callback
    ThemeService().registerThemeCallback((themeMode) {
      setState(() {
        _themeMode = themeMode;
      });
    });
  }

  /// Update theme mode
  void updateThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  /// Update locale
  void setLocale(Locale locale) {
    // setState(() {
    _locale = locale;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MedicineCubit>(create: (context) => getIt<MedicineCubit>()),
        BlocProvider<MedicineLogCubit>(create: (context) => getIt<MedicineLogCubit>()),
        BlocProvider<StatisticsCubit>(create: (context) => getIt<StatisticsCubit>()),
        BlocProvider<HistoryCubit>(create: (context) => getIt<HistoryCubit>()),
        // COMMENTED OUT FOR UPCOMING RELEASE
        // BlocProvider<ProfileCubit>(create: (context) => getIt<ProfileCubit>()),
        BlocProvider<SettingsCubit>(create: (context) => getIt<SettingsCubit>()),
      ],
      child: MaterialApp(
        title: 'Medify',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService().navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        locale: _locale,
        // Localization support
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          // Locale('hi'), // Hindi - Commented out for now
          // Locale('bn'), // Bengali - Commented out for now
        ],
        home: _prefsService.isFirstLaunch ? const OnboardingPage() : const MainNavigationPage(),
      ),
    );
  }
}
