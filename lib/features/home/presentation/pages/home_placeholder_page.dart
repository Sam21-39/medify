import 'package:flutter/material.dart';

/// Placeholder landing page for authenticated + consented users.
/// Replaced by the real dashboard in Phase 1.7.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home (Phase 1.7)')));
  }
}
