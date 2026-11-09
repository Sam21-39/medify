import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/database/enums.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/database/settings_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SettingsStore store;

  setUp(() async {
    db = await MedifyDatabase.open(path: inMemoryDatabasePath);
    store = SettingsStore(db);
  });

  tearDown(() => db.close());

  test('bool, int, string and enum round trip', () async {
    await store.setBool('b', true);
    await store.setInt('i', 42);
    await store.setString('s', 'hello');
    await store.setEnum('e', ProfileRole.caregiver);

    expect(await store.getBool('b', defaultValue: false), isTrue);
    expect(await store.getInt('i', defaultValue: 0), 42);
    expect(await store.getString('s', defaultValue: ''), 'hello');
    expect(
      await store.getEnum(
        'e',
        ProfileRole.values,
        defaultValue: ProfileRole.patient,
      ),
      ProfileRole.caregiver,
    );
  });

  test('set overwrites the existing row', () async {
    await store.setInt('i', 1);
    await store.setInt('i', 2);
    expect(await store.getInt('i', defaultValue: 0), 2);
  });

  test('type mismatch on read returns the default', () async {
    await store.setInt('x', 7);
    expect(await store.getBool('x', defaultValue: true), isTrue);
    expect(await store.getString('x', defaultValue: 'd'), 'd');
    expect(
      await store.getEnum(
        'x',
        ProfileRole.values,
        defaultValue: ProfileRole.patient,
      ),
      ProfileRole.patient,
    );
  });

  test('missing key returns the default', () async {
    expect(await store.getInt('missing', defaultValue: 5), 5);
  });
}
