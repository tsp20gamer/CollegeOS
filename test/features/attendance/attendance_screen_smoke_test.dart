import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('attendance screen renders an empty linked calendar', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateUtils.dateOnly(DateTime.now());
    await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '${now.year}-${now.year + 1}',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        isActive: const Value(true),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          activeSemesterProvider.overrideWith(
            (ref) => Stream.value((
              id: 1,
              name: 'Semester 1',
              semesterNumber: 1,
              academicYear: '${now.year}-${now.year + 1}',
              startDate: now.subtract(const Duration(days: 1)),
              endDate: now.add(const Duration(days: 1)),
              isActive: true,
              createdAt: now.toUtc(),
              updatedAt: now.toUtc(),
            )),
          ),
          attendanceEngineProvider.overrideWith(
            (ref) => Stream.value(
              const AttendanceEngineSnapshot(
                subjects: [],
                timetable: [],
                attendance: [],
                overrides: [],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AttendanceScreen()),
        ),
      ),
    );
    for (var index = 0; index < 20; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('attendance_mode_toggle')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
