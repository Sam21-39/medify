import 'package:flutter/material.dart';

import '../../../../core/design_system/medify_logo.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MedifyLogo(size: 96),
            SizedBox(height: 16),
            Text('Medify'),
          ],
        ),
      ),
    );
  }
}
