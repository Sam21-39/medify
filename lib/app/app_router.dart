import 'package:go_router/go_router.dart';
import 'package:medify/app/main_navigation_page.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/presentation/pages/add_edit_medicine_page.dart';
import 'package:medify/features/medicines/presentation/pages/medicine_list_page.dart';
import 'package:medify/features/history/presentation/pages/history_page.dart';
import 'package:medify/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:medify/features/profiles/presentation/pages/role_page.dart';
import 'package:medify/features/schedule/presentation/pages/alarm_page.dart';
import 'package:medify/features/schedule/presentation/pages/schedule_page.dart';
import 'package:medify/features/settings/presentation/pages/settings_page.dart';
import 'package:medify/features/statistics/presentation/pages/statistics_page.dart';

GoRouter buildRouter(PreferencesService prefs) {
  return GoRouter(
    initialLocation: prefs.isFirstLaunch
        ? '/onboarding'
        : prefs.roleChosen
        ? '/today'
        : '/role',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/role', builder: (context, state) => const RolePage()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/alarm',
        builder: (context, state) => AlarmPage(
          medicineId:
              int.tryParse(state.uri.queryParameters['medicineId'] ?? '') ?? 0,
          scheduledSeconds:
              int.tryParse(state.uri.queryParameters['seconds'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/medicine/add',
        builder: (context, state) => const AddEditMedicinePage(),
      ),
      GoRoute(
        path: '/medicine/edit',
        builder: (context, state) =>
            AddEditMedicinePage(medicine: state.extra as Medicine?),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainNavigationPage(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const SchedulePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/medicines',
                builder: (context, state) => const MedicineListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatisticsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
