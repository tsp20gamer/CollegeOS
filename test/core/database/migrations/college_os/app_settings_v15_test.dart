import 'package:college_os/core/database/app_database.dart';
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
      //
      // These are read through raw SQL on purpose: the database is correctly
      // v15-shaped here, which is one column short of the Dart table this app
      // object maps, so a typed settings read cannot even address the older
      // row. The same assertions re-run through the typed repository in the
      // v16 test, where the shapes finally meet.
      await database.customStatement(
        'INSERT INTO app_settings (id) VALUES (1)',
      );
      final row =
          (await database
                  .customSelect(
                    'SELECT class_reminders_enabled, '
                    'class_reminder_minutes_before, '
                    'default_attendance_target '
                    'FROM app_settings WHERE id = 1',
                  )
                  .getSingle())
              .data;
      expect(row['class_reminders_enabled'], 1);
      expect(row['class_reminder_minutes_before'], 10);
      expect(row['default_attendance_target'], 0.75);
      final count =
          (await database
                  .customSelect('SELECT COUNT(*) AS c FROM app_settings')
                  .getSingle())
              .read<int>('c');
      expect(count, 1);
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
