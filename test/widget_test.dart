// Full-app smoke test is deferred: MedifyApp resolves AppRouter through
// `getIt`, which requires `bootstrap()` to have run — and bootstrap opens
// flutter_secure_storage/Drift, which need real platform channels not
// available under `flutter_test`. This covers the one piece that's pure
// Dart/widgets: the placeholder screen shown while feature screens land.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medify/core/widgets/placeholder_home_screen.dart';

void main() {
  testWidgets('PlaceholderHomeScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlaceholderHomeScreen()));

    expect(find.text('Medify'), findsOneWidget);
  });
}
