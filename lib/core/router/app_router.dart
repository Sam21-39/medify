import 'package:go_router/go_router.dart';

import '../../features/app_shell/presentation/pages/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (context, state) => const SplashPage())],
);
