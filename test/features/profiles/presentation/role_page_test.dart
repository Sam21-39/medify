import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/database/settings_store.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/theme/app_theme.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/features/medicines/data/sqflite/medicine_sqflite_repository.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/profiles/data/services/profile_service.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/profiles/data/sqflite/profile_sqflite_repository.dart';
import 'package:medify/features/profiles/domain/entities/user_profile.dart';
import 'package:medify/features/profiles/presentation/pages/role_page.dart';
import 'package:medify/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Records navigation instead of routing.
class _RecordingMessenger extends AppMessenger {
  final goes = <String>[];
  final pushes = <String>[];

  @override
  void go(String location) => goes.add(location);

  @override
  Future<T?> push<T>(String location, {Object? extra}) async {
    pushes.add(location);
    return null;
  }
}

const _flagKey = 'first_medicine_offer_shown';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _RecordingMessenger messenger;
  late Directory tempDir;

  setUp(() async {
    // Own file per test: in-memory DBs were shared, so the flag leaked.
    tempDir = Directory.systemTemp.createTempSync('role_page_test');
    final db = await MedifyDatabase.open(path: '${tempDir.path}/medify.db');
    final cipher = FieldCipher(List.filled(32, 7));
    final prefs = await PreferencesService.initialize(SettingsStore(db));
    final profiles = ProfileService(
      ProfileSqfliteRepository(db, cipher),
      prefs,
    );
    await profiles.initialize();
    messenger = _RecordingMessenger();
    getIt.registerSingleton<Database>(db);
    getIt.registerSingleton<PreferencesService>(prefs);
    getIt.registerSingleton<ProfileService>(profiles);
    getIt.registerSingleton<AppMessenger>(messenger);
    getIt.registerSingleton<MedicineRepository>(
      SqfliteMedicineRepository(db, cipher),
    );
  });

  tearDown(() async {
    await getIt<Database>().close();
    await getIt.reset();
    tempDir.deleteSync(recursive: true);
  });

  Future<int?> flagValue() => getIt<PreferencesService>().getInt(_flagKey);

  /// sqflite runs on real async turns, outside fake time, so poll for them.
  Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 1000 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
  }

  Future<AppLocalizations> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RolePage(),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(RolePage)))!;
  }

  testWidgets('patient with no medicines: "Later" goes to /today only', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.text(l10n.rolePatient));
    await pumpUntil(
      tester,
      () => find.text(l10n.addYourFirstMedicine).evaluate().isNotEmpty,
    );

    expect(find.text(l10n.addYourFirstMedicine), findsOneWidget);
    await tester.tap(find.text(l10n.firstMedicineLaterAction));
    await pumpUntil(tester, () => messenger.goes.isNotEmpty);

    expect(messenger.goes, ['/today']);
    expect(messenger.pushes, isEmpty);
    expect(await flagValue(), isNotNull);
  });

  testWidgets('"Add a medicine" goes to /today then opens the add form', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.text(l10n.rolePatient));
    await pumpUntil(
      tester,
      () =>
          messenger.goes.isNotEmpty ||
          find.text(l10n.addYourFirstMedicine).evaluate().isNotEmpty,
    );
    await tester.tap(find.text(l10n.firstMedicineAddAction));
    await pumpUntil(tester, () => messenger.pushes.isNotEmpty);

    expect(messenger.goes, ['/today']);
    expect(messenger.pushes, ['/medicine/add']);
    expect(await flagValue(), isNotNull);
  });

  testWidgets('active medicine present: no dialog, flag set', (tester) async {
    final l10n = await pumpPage(tester);
    // sqflite needs real async turns, so seed outside fake time.
    await tester.runAsync(
      () => getIt<MedicineRepository>().addMedicine(
        Medicine(
          profileId: getIt<ProfileService>().active!.id!,
          name: 'Aspirin',
          dosage: '1 tablet',
          reminderTimes: const [28800],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ),
    );

    await tester.tap(find.text(l10n.rolePatient));
    await pumpUntil(tester, () => messenger.goes.isNotEmpty);

    expect(find.text(l10n.addYourFirstMedicine), findsNothing);
    expect(messenger.goes, ['/today']);
    expect(messenger.pushes, isEmpty);
    expect(await flagValue(), isNotNull);
  });

  testWidgets('flag already set: no dialog', (tester) async {
    final l10n = await pumpPage(tester);
    await tester.runAsync(
      () => getIt<PreferencesService>().setInt(_flagKey, 1),
    );

    await tester.tap(find.text(l10n.rolePatient));
    await pumpUntil(tester, () => messenger.goes.isNotEmpty);

    expect(find.text(l10n.addYourFirstMedicine), findsNothing);
    expect(messenger.goes, ['/today']);
    expect(messenger.pushes, isEmpty);
  });

  testWidgets('barrier tap dismisses: /today, flag set, no push', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.text(l10n.rolePatient));
    await pumpUntil(
      tester,
      () => find.text(l10n.addYourFirstMedicine).evaluate().isNotEmpty,
    );
    await tester.tapAt(const Offset(5, 5));
    await pumpUntil(tester, () => messenger.goes.isNotEmpty);

    expect(messenger.goes, ['/today']);
    expect(messenger.pushes, isEmpty);
    expect(await flagValue(), isNotNull);
  });

  testWidgets('Escape dismisses: /today, flag set, no push', (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.text(l10n.rolePatient));
    await pumpUntil(
      tester,
      () => find.text(l10n.addYourFirstMedicine).evaluate().isNotEmpty,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpUntil(tester, () => messenger.goes.isNotEmpty);

    expect(messenger.goes, ['/today']);
    expect(messenger.pushes, isEmpty);
    expect(await flagValue(), isNotNull);
  });

  testWidgets('caregiver role: no first-medicine dialog, no push', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);
    await tester.runAsync(
      () => getIt<ProfileService>().createProfile(
        UserProfile(
          name: 'Mum',
          colorValue: 0xFF000000,
          role: 0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ),
    );

    await tester.tap(find.text(l10n.roleCaregiver));
    await pumpUntil(
      tester,
      () => find.text(l10n.whoAreYouHelping).evaluate().isNotEmpty,
    );
    expect(find.text(l10n.addYourFirstMedicine), findsNothing);

    await tester.tap(find.text('Mum'));
    await pumpUntil(tester, () => messenger.goes.isNotEmpty);

    expect(find.text(l10n.addYourFirstMedicine), findsNothing);
    expect(messenger.goes, ['/today']);
    expect(messenger.pushes, isEmpty);
  });
}
