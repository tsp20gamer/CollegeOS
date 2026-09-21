import 'dart:async';

import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_engine_repository.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bulk Calendar action and Classes edit stay synchronized', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateUtils.dateOnly(DateTime.now());
    final timestamp = now.toUtc();
    final repository = _MemoryAttendanceEngine(
      AttendanceEngineSnapshot(
        subjects: [
          _subject(1, 'Mathematics', 'MATH', timestamp),
          _subject(2, 'English', 'ENG', timestamp),
        ],
        timetable: [
          _slot(1, 1, now.weekday, 540, now),
          _slot(2, 2, now.weekday, 600, now),
        ],
        attendance: const [],
        overrides: const [],
      ),
      now: timestamp,
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceEngineRepositoryProvider.overrideWithValue(repository),
          activeSemesterProvider.overrideWith(
            (ref) => Stream.value((
              id: 1,
              name: 'Semester 1',
              semesterNumber: 1,
              academicYear: '${now.year}-${now.year + 1}',
              startDate: now.subtract(const Duration(days: 10)),
              endDate: now.add(const Duration(days: 120)),
              isActive: true,
              createdAt: timestamp,
              updatedAt: timestamp,
            )),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AttendanceScreen()),
        ),
      ),
    );
    await _pumpUntil(tester, find.byKey(const Key('mark_all_present')));

    await tester.tap(find.byKey(const Key('mark_all_present')));
    await _pumpUntil(tester, find.text('Present day'));
    expect(repository.current.attendance, hasLength(2));
    expect(
      repository.current.attendance.every(
        (item) => item.status == ClassAttendanceStatus.present,
      ),
      isTrue,
    );

    await tester.tap(find.text('Subject View'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Present'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(FilterChip, 'Absent').at(1));
    await _pumpUntil(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget is FilterChip &&
            widget.selected &&
            (widget.label as Text).data == 'Absent',
      ),
    );
    expect(
      repository.current.attendance
          .singleWhere((item) => item.subjectId == 2)
          .status,
      ClassAttendanceStatus.absent,
    );

    await tester.tap(find.text('Day View'));
    await tester.pumpAndSettle();
    await _pumpUntil(tester, find.text('Partial attendance'));

    await tester.tap(find.byKey(const Key('toggle_holiday')));
    await _pumpUntil(tester, find.text('Undo Holiday'));
    expect(repository.current.overrides, hasLength(1));
    expect(repository.current.attendance, hasLength(2));

    await tester.tap(find.byKey(const Key('toggle_holiday')));
    await _pumpUntil(tester, find.text('Partial attendance'));
    expect(repository.current.overrides, isEmpty);
    expect(repository.current.attendance, hasLength(2));

    await tester.tap(find.text('Subject View'));
    await tester.pumpAndSettle();
    await _pumpUntil(tester, find.text('Mark All Absent'));
    await tester.tap(find.byKey(const Key('mark_all_absent')));
    await tester.pumpAndSettle();
    expect(
      repository.current.attendance.every(
        (item) => item.status == ClassAttendanceStatus.absent,
      ),
      isTrue,
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Present').first);
    await tester.pumpAndSettle();
    expect(
      repository.current.attendance
          .singleWhere((item) => item.subjectId == 1)
          .status,
      ClassAttendanceStatus.present,
    );
    await tester.tap(find.text('Day View'));
    await tester.pumpAndSettle();
    await _pumpUntil(tester, find.text('Partial attendance'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final class _MemoryAttendanceEngine implements AttendanceEngineRepository {
  _MemoryAttendanceEngine(this.current, {required this.now});

  AttendanceEngineSnapshot current;
  final DateTime now;
  final _changes = StreamController<AttendanceEngineSnapshot>.broadcast();
  int _nextId = 1;

  @override
  Stream<AttendanceEngineSnapshot> watchForSemester(int semesterId) async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<AttendanceEngineSnapshot> loadForSemester(int semesterId) async =>
      current;

  @override
  Future<AttendanceUndo> markSession(
    ProjectedClassSession session,
    int semesterId,
    ClassAttendanceStatus status, {
    String note = '',
  }) async {
    final previous = current;
    _replace(session, semesterId, status, note: note, manual: true);
    _emit();
    return () async {
      current = previous;
      _emit();
      return true;
    };
  }

  @override
  Future<AttendanceUndo> markWholeDay(
    List<ProjectedClassSession> sessions,
    int semesterId,
    ClassAttendanceStatus status,
  ) async {
    final previous = current;
    for (final session in sessions) {
      _replace(session, semesterId, status, note: session.note, manual: false);
    }
    _emit();
    return () async {
      current = previous;
      _emit();
      return true;
    };
  }

  void _replace(
    ProjectedClassSession session,
    int semesterId,
    ClassAttendanceStatus status, {
    required String note,
    required bool manual,
  }) {
    final rows = [...current.attendance];
    final index = rows.indexWhere(
      (item) =>
          item.timetableEntryId == session.timetableEntryId &&
          DateUtils.isSameDay(item.date, session.date),
    );
    final id = index < 0 ? _nextId++ : rows[index].id;
    final row = (
      id: id,
      semesterId: semesterId,
      timetableEntryId: session.timetableEntryId,
      subjectId: session.subject.id,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
      status: status,
      note: note,
      manuallyModified: manual,
      createdAt: now,
      updatedAt: now,
    );
    if (index < 0) {
      rows.add(row);
    } else {
      rows[index] = row;
    }
    current = AttendanceEngineSnapshot(
      subjects: current.subjects,
      timetable: current.timetable,
      attendance: rows,
      overrides: current.overrides,
    );
  }

  @override
  Future<void> clearSession(int attendanceId) async {
    current = AttendanceEngineSnapshot(
      subjects: current.subjects,
      timetable: current.timetable,
      attendance: current.attendance
          .where((item) => item.id != attendanceId)
          .toList(),
      overrides: current.overrides,
    );
    _emit();
  }

  @override
  Future<void> setDayOverride({
    required int semesterId,
    required DateTime date,
    required CalendarDayOverrideType type,
    String note = '',
  }) async {
    current = AttendanceEngineSnapshot(
      subjects: current.subjects,
      timetable: current.timetable,
      attendance: current.attendance,
      overrides: [
        ...current.overrides.where(
          (item) => !DateUtils.isSameDay(item.date, date),
        ),
        (id: 1, semesterId: semesterId, date: date, type: type, note: note),
      ],
    );
    _emit();
  }

  @override
  Future<void> clearDayOverride(int semesterId, DateTime date) async {
    current = AttendanceEngineSnapshot(
      subjects: current.subjects,
      timetable: current.timetable,
      attendance: current.attendance,
      overrides: current.overrides
          .where((item) => !DateUtils.isSameDay(item.date, date))
          .toList(),
    );
    _emit();
  }

  void _emit() => _changes.add(current);
  Future<void> close() => _changes.close();
}

Subject _subject(int id, String name, String code, DateTime timestamp) => (
  id: id,
  semesterId: 1,
  name: name,
  shortCode: code,
  professor: '',
  room: '',
  attendanceTarget: 0.75,
  displayColor: 0xFF4758D6,
  isArchived: false,
  createdAt: timestamp,
  updatedAt: timestamp,
);

AttendanceTimetableSlot _slot(
  int id,
  int subjectId,
  int weekday,
  int start,
  DateTime now,
) => (
  id: id,
  semesterId: 1,
  subjectId: subjectId,
  weekday: weekday,
  startTime: start,
  endTime: start + 60,
  effectiveFrom: now.subtract(const Duration(days: 10)),
  effectiveUntil: null,
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}
