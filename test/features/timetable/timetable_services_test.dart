import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimetableOverlapService', () {
    final entries = [
      _entry(id: 1, weekday: DateTime.monday, start: 9 * 60, end: 10 * 60),
      _entry(id: 2, weekday: DateTime.tuesday, start: 9 * 60, end: 10 * 60),
    ];

    test('detects partial, containing, and exact overlaps', () {
      for (final range in [
        (8 * 60 + 30, 9 * 60 + 1),
        (8 * 60, 11 * 60),
        (9 * 60, 10 * 60),
      ]) {
        expect(
          TimetableOverlapService.findOverlaps(
            entries: entries,
            weekday: DateTime.monday,
            startTime: range.$1,
            endTime: range.$2,
          ).map((entry) => entry.id),
          [1],
        );
      }
    });

    test('allows adjacent classes and classes on another day', () {
      expect(
        TimetableOverlapService.findOverlaps(
          entries: entries,
          weekday: DateTime.monday,
          startTime: 10 * 60,
          endTime: 11 * 60,
        ),
        isEmpty,
      );
      expect(
        TimetableOverlapService.findOverlaps(
          entries: entries,
          weekday: DateTime.wednesday,
          startTime: 9 * 60,
          endTime: 10 * 60,
        ),
        isEmpty,
      );
    });

    test('excludes the entry being edited', () {
      expect(
        TimetableOverlapService.findOverlaps(
          entries: entries,
          weekday: DateTime.monday,
          startTime: 9 * 60,
          endTime: 10 * 60,
          excludingId: 1,
        ),
        isEmpty,
      );
    });
  });

  group('NextClassService', () {
    final schedule = [
      _scheduled(
        id: 1,
        weekday: DateTime.wednesday,
        start: 9 * 60,
        end: 10 * 60,
      ),
      _scheduled(
        id: 2,
        weekday: DateTime.wednesday,
        start: 11 * 60,
        end: 12 * 60,
      ),
      _scheduled(id: 3, weekday: DateTime.thursday, start: 8 * 60, end: 9 * 60),
      _scheduled(id: 4, weekday: DateTime.monday, start: 10 * 60, end: 11 * 60),
    ];

    test('finds the current class and next class today', () {
      final result = NextClassService.calculate(
        schedule: schedule,
        now: DateTime(2026, 8, 12, 9, 30),
      );
      expect(result.currentClass?.entry.id, 1);
      expect(result.nextClass?.entry.id, 2);
      expect(result.daysUntilNext, 0);
      expect(result.nextIsToday, isTrue);
    });

    test('uses the first class on the next scheduled day', () {
      final result = NextClassService.calculate(
        schedule: schedule,
        now: DateTime(2026, 8, 12, 12, 30),
      );
      expect(result.currentClass, isNull);
      expect(result.nextClass?.entry.id, 3);
      expect(result.daysUntilNext, 1);
    });

    test('wraps from Saturday to Monday', () {
      final result = NextClassService.calculate(
        schedule: schedule,
        now: DateTime(2026, 8, 15, 18),
      );
      expect(result.nextClass?.entry.id, 4);
      expect(result.daysUntilNext, 2);
    });

    test('finds Monday from Sunday', () {
      final result = NextClassService.calculate(
        schedule: schedule,
        now: DateTime(2026, 8, 16, 12),
      );
      expect(result.nextClass?.entry.id, 4);
      expect(result.daysUntilNext, 1);
    });

    test('reports simultaneous overlapping current classes', () {
      final result = NextClassService.calculate(
        schedule: [
          ...schedule,
          _scheduled(
            id: 5,
            weekday: DateTime.wednesday,
            start: 9 * 60 + 15,
            end: 10 * 60 + 15,
          ),
        ],
        now: DateTime(2026, 8, 12, 9, 30),
      );
      expect(result.currentClasses.map((item) => item.entry.id), [5, 1]);
      expect(result.currentClass?.entry.id, 5);
    });

    test('returns an empty result for an empty schedule', () {
      final result = NextClassService.calculate(
        schedule: const [],
        now: DateTime(2026, 8, 12, 9),
      );
      expect(result.currentClass, isNull);
      expect(result.nextClass, isNull);
      expect(result.daysUntilNext, isNull);
    });
  });
}

TimetableEntry _entry({
  required int id,
  required int weekday,
  required int start,
  required int end,
}) => (
  id: id,
  semesterId: 1,
  subjectId: 1,
  weekday: weekday,
  startTime: start,
  endTime: end,
  room: 'A-1',
  note: '',
  reminderMinutesBefore: null,
);

ScheduledClass _scheduled({
  required int id,
  required int weekday,
  required int start,
  required int end,
}) => ScheduledClass(
  entry: _entry(id: id, weekday: weekday, start: start, end: end),
  subject: _subject,
);

final Subject _subject = (
  id: 1,
  semesterId: 1,
  name: 'Algorithms',
  shortCode: 'CS201',
  professor: 'Dr Rao',
  room: 'A-1',
  attendanceTarget: 0.75,
  displayColor: 0xFF2563EB,
  isArchived: false,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);
