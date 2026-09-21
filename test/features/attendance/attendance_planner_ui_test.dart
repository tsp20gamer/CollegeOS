import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_planner_screen.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'planner updates a projection and remains usable with large text',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1500);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceSubjectsProvider.overrideWith(
              (ref) => AsyncData([
                SubjectAttendanceResult(
                  subject: _subject,
                  metrics: AttendanceCalculator.calculate(
                    presentCount: 8,
                    absentCount: 2,
                    cancelledCount: 0,
                    target: .75,
                  ),
                  history: const [],
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 600),
                textScaler: TextScaler.linear(1.4),
                disableAnimations: true,
              ),
              child: const AttendancePlannerScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Planner'), findsOneWidget);
      expect(find.text('80.0%'), findsWidgets);
      final increaseMissed = find.byKey(
        const ValueKey('planner_increase_Classes missed'),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -360));
      await tester.pump();
      await tester.ensureVisible(increaseMissed);
      tester.widget<IconButton>(increaseMissed).onPressed!();
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, 360));
      await tester.pump();
      expect(find.text('75.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final Subject _subject = (
  id: 1,
  semesterId: 1,
  name: 'A very long subject name for accessibility testing',
  shortCode: 'LONG',
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF4F8CFF,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
