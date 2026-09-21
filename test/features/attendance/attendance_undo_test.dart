import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late AppDatabase db;
  late int semester;
  late int subject;
  late int slot;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    semester = await db.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester',
        semesterNumber: 1,
        academicYear: '2026-2027',
        isActive: const Value(true),
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 1),
      ),
    );
    subject = await db.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        semesterId: semester,
        name: 'Math',
        displayColor: 0xFF7367F0,
      ),
    );
    slot = await db.timetableDao.insertEntry(
      TimetableEntriesCompanion.insert(
        semesterId: semester,
        subjectId: subject,
        weekday: 1,
        startTime: 540,
        endTime: 600,
      ),
    );
  });
  tearDown(() => db.close());

  testWidgets(
    'app offers Undo after marking a day and restores unmarked storage',
    (tester) async {
      await db.settingsDao.save(
        const AppSettingsCompanion(onboardingCompleted: Value(true)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollegeOsApp)),
      );
      for (
        var i = 0;
        i < 30 && container.read(activeSemesterProvider).value == null;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final active = container.read(activeSemesterProvider).value!;
      await tester.pumpAndSettle();
      final snapshot = await container
          .read(attendanceEngineRepositoryProvider)
          .loadForSemester(active.id);
      final day = AttendanceScheduleEngine.day(
        snapshot: snapshot,
        semester: active,
        date: DateTime(2026, 8, 17),
      );
      final success = await container
          .read(attendanceCommandProvider.notifier)
          .markWholeDay(day, active.id, ClassAttendanceStatus.present);
      expect(success, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await db.select(db.scheduledClassAttendance).get(), isEmpty);
      expect(find.text('Attendance restored.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  ScheduledClassAttendanceCompanion mark(
    ClassAttendanceStatus status, {
    int? id,
    bool manual = false,
  }) => ScheduledClassAttendanceCompanion.insert(
    id: id == null ? const Value.absent() : Value(id),
    semesterId: semester,
    subjectId: subject,
    timetableEntryId: Value(manual ? null : slot),
    date: DateTime(2026, 8, 17),
    startTime: 540,
    endTime: 600,
    attendanceStatus: status,
    note: const Value('Keep my note'),
    manuallyModified: const Value(true),
  );

  test(
    'undo removes newly materialized rows and restores exact prior rows',
    () async {
      final undoNew = await db.attendanceEngineDao.upsertWithUndo([
        mark(ClassAttendanceStatus.present),
      ]);
      expect(
        (await db.select(db.scheduledClassAttendance).get())
            .single
            .attendanceStatus,
        ClassAttendanceStatus.present,
      );
      expect(await undoNew(), isTrue);
      expect(await db.select(db.scheduledClassAttendance).get(), isEmpty);
      expect(await undoNew(), isFalse);

      await db.attendanceEngineDao.upsertAttendance(
        mark(ClassAttendanceStatus.absent),
      );
      final original = await db.select(db.scheduledClassAttendance).getSingle();
      final undoEdit = await db.attendanceEngineDao.upsertWithUndo([
        mark(ClassAttendanceStatus.present),
      ]);
      expect(await undoEdit(), isTrue);
      expect(
        await db.select(db.scheduledClassAttendance).getSingle(),
        original,
      );
    },
  );

  test('undo refuses to overwrite a newer edit', () async {
    final undo = await db.attendanceEngineDao.upsertWithUndo([
      mark(ClassAttendanceStatus.present),
    ]);
    await db.attendanceEngineDao.upsertAttendance(
      mark(ClassAttendanceStatus.cancelled),
    );
    expect(await undo(), isFalse);
    expect(
      (await db.select(db.scheduledClassAttendance).getSingle())
          .attendanceStatus,
      ClassAttendanceStatus.cancelled,
    );
  });

  test(
    'historical manual record updates without duplication and can be undone',
    () async {
      final id = await db.attendanceEngineDao.upsertAttendance(
        mark(ClassAttendanceStatus.absent, manual: true),
      );
      final original = await db.select(db.scheduledClassAttendance).getSingle();
      final undo = await db.attendanceEngineDao.upsertWithUndo([
        mark(ClassAttendanceStatus.present, id: id, manual: true),
      ]);
      expect(await db.select(db.scheduledClassAttendance).get(), hasLength(1));
      expect(await undo(), isTrue);
      expect(
        await db.select(db.scheduledClassAttendance).getSingle(),
        original,
      );
    },
  );

  test('bulk undo is atomic when one row has changed', () async {
    final first = mark(ClassAttendanceStatus.present);
    final second = first.copyWith(date: Value(DateTime(2026, 8, 18)));
    final undo = await db.attendanceEngineDao.upsertWithUndo([first, second]);
    await db.attendanceEngineDao.upsertAttendance(
      second.copyWith(
        attendanceStatus: const Value(ClassAttendanceStatus.absent),
      ),
    );
    expect(await undo(), isFalse);
    expect(await db.select(db.scheduledClassAttendance).get(), hasLength(2));
  });
}
