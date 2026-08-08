import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'core/di/di_setup.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  await bootstrap();
  runApp(const MedifyApp());
}

class MedifyApp extends StatelessWidget {
  const MedifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Medify',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: getIt<AppRouter>().router,
    );
  }
}
