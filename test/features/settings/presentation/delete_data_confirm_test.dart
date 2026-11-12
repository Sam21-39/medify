import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/settings/presentation/pages/settings_page.dart';
import 'package:medify/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Delete all data stays disabled until the text is exactly DELETE',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDeleteDataConfirmDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));
      FilledButton confirm() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, l10n.deleteAllDataConfirm),
      );

      expect(confirm().onPressed, isNull);
      for (final text in ['', 'delete', 'DELETE ']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump();
        expect(confirm().onPressed, isNull, reason: 'text: "$text"');
      }

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
    },
  );
}
