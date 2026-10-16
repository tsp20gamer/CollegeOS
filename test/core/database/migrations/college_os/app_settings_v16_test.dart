import 'package:college_os/core/database/app_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

/// The derived-holiday rules arrive as three defaulted columns, so an existing
/// install keeps the attendance it already had and simply gains the days off.
///
/// The table is rebuilt (not appended to), which is what keeps the v15 lead-time
/// CHECK and the singleton CHECK in the upgraded table: a plain `addColumn`
/// would leave the old constraints behind. The verifier proves the rebuilt
/// schema matches a fresh v16 create; this test proves the data survives it.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test(
    'a v15 database gains the three rules, enabled, with its row intact',
    () async {
      final schema = await verifier.schemaAt(15);
      final database = AppDatabase.forTesting(schema.newConnection());
      // Seed a v15-shaped settings row through raw SQL: the Dart table class
      // already carries the v16 columns, so a typed insert would name columns
      // this older schema does not have yet.
      await database.customStatement(
        "INSERT INTO app_settings (id, student_name, default_attendance_target, "
        "class_reminders_enabled, class_reminder_minutes_before) "
        "VALUES (1, 'Existing Student', 0.8, 0, 30)",
      );

      await verifier.migrateAndValidate(database, 16);

      final settings = await database.settingsDao.getSettings();
      expect(settings.studentName, 'Existing Student');
      expect(settings.defaultAttendanceTarget, 0.8);
      // Everything the student already chose is untouched.
      expect(settings.classRemindersEnabled, isFalse);
      expect(settings.classReminderMinutesBefore, 30);
      // The new rules arrive enabled, exactly as a fresh v16 install stores them.
      expect(settings.sundayOff, isTrue);
      expect(settings.secondSaturdayOff, isTrue);
      expect(settings.governmentHolidaysOff, isTrue);

      final tableSql =
          (await database
                  .customSelect(
                    "SELECT sql FROM sqlite_master WHERE type = 'table' "
                    "AND name = 'app_settings'",
                  )
                  .getSingle())
              .read<String>('sql');
      expect(tableSql, contains('sunday_off'));
      expect(tableSql, contains('second_saturday_off'));
      expect(tableSql, contains('government_holidays_off'));
      expect(
        tableSql,
        contains('CHECK (class_reminder_minutes_before BETWEEN 0 AND 10080)'),
        reason: 'the rebuild keeps the constraint v15 added',
      );
      expect(tableSql, contains('CHECK (id = 1)'));

      // Switching a rule off is a plain update, and a fresh row may not multiply.
      await database.customStatement(
        'UPDATE app_settings SET sunday_off = 0 WHERE id = 1',
      );
      expect((await database.settingsDao.getSettings()).sundayOff, isFalse);
      expect(await database.select(database.appSettings).get(), hasLength(1));
      expect(await database.passesIntegrityCheck(), isTrue);
      expect(await database.passesForeignKeyCheck(), isTrue);

      await database.close();
      schema.close();
    },
  );
}
