import 'dart:io';

import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/data/drift_daily_attendance_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sets, replaces, queries, and removes one record per date', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftDailyAttendanceRepository(
      database.dailyAttendanceDao,
    );
    final date = DateTime(2026, 8, 12, 23, 45);

    await repository.setStatus(
      date: date,
      status: DailyAttendanceStatus.present,
      note: 'Full day',
    );
    await repository.setStatus(
      date: DateTime(2026, 8, 12, 1),
      status: DailyAttendanceStatus.absent,
      note: 'Corrected',
    );

    final rows = await repository.watchAll().first;
    expect(rows, hasLength(1));
    expect(rows.single.date, DateTime(2026, 8, 12));
    expect(rows.single.status, DailyAttendanceStatus.absent);
    expect(rows.single.note, 'Corrected');

    await repository.remove(date);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('range query orders calendar days chronologically', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftDailyAttendanceRepository(
      database.dailyAttendanceDao,
    );
    for (final day in [15, 10, 12]) {
      await repository.setStatus(
        date: DateTime(2026, 8, day),
        status: day == 12
            ? DailyAttendanceStatus.absent
            : DailyAttendanceStatus.present,
      );
    }

    final range = await repository
        .watchRange(DateTime(2026, 8, 11), DateTime(2026, 8, 15))
        .first;
    expect(range.map((record) => record.date.day), [12, 15]);
  });

  test('daily attendance survives database close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'college_os_daily_attendance_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(
      '${directory.path}${Platform.pathSeparator}college.sqlite',
    );
    var database = AppDatabase.forTesting(NativeDatabase(file));
    await DriftDailyAttendanceRepository(database.dailyAttendanceDao).setStatus(
      date: DateTime(2026, 8, 12),
      status: DailyAttendanceStatus.present,
    );
    await database.close();

    database = AppDatabase.forTesting(NativeDatabase(file));
    final restored = await DriftDailyAttendanceRepository(
      database.dailyAttendanceDao,
    ).watchAll().first;
    expect(restored.single.status, DailyAttendanceStatus.present);
    await database.close();
  });
}
