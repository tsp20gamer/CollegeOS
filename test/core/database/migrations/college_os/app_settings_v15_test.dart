import 'package:college_os/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

/// The generated migration test proves every historical schema reaches v15.
/// This checks the part that only the recreation can satisfy: the upgraded table
/// carries the same CHECK a fresh v15 create writes, so an upgraded install
/// cannot accept a class reminder lead time a new install would reject. A plain
/// `addColumn` would leave the constraint behind.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test(
    'a v14 database gains the class notifier with its schema CHECK',
    () async {
      final schema = await verifier.schemaAt(14);
      final database = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(database, 15);

      final tables = await database
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type = 'table'",
          )
          .get();
      final tableSql = tables
          .singleWhere((row) => row.read<String>('name') == 'app_settings')
          .read<String>('sql');
      expect(
        tableSql,
        contains('CHECK (class_reminder_minutes_before BETWEEN 0 AND 10080)'),
      );

      // The row holds the new preferences with the defaults an upgrade stores:
      // nothing that already reminded stops reminding.
      await database
          .into(database.appSettings)
          .insert(const AppSettingsCompanion(id: Value(1)));
      final settings = await database.settingsDao.getSettings();
      expect(settings.classRemindersEnabled, isTrue);
      expect(settings.classReminderMinutesBefore, 10);
      expect(settings.defaultAttendanceTarget, 0.75);
      expect(await database.select(database.appSettings).get(), hasLength(1));
      expect(await database.passesIntegrityCheck(), isTrue);

      // The database enforces the same range as the form and the backup reader.
      expect(
        () => database.customStatement(
          'UPDATE app_settings SET class_reminder_minutes_before = 10081 '
          'WHERE id = 1',
        ),
        throwsA(anything),
      );

      await database.close();
      schema.close();
    },
  );
}
