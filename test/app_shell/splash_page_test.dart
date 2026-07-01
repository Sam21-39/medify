import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/app_shell/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders the Medify title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));

    expect(find.text('Medify'), findsOneWidget);
  });
}
