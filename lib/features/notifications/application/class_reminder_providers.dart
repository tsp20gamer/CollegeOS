import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/notifications/domain/class_reminder_plan.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The desired class-reminder projection, or `null` while an input is unknown.
///
/// `null` means "leave the class namespace alone for now": the timetable, the
/// active semester and the attendance snapshot all load asynchronously, and
/// treating "still loading" as an empty list would cancel alarms that are still
/// correct. An empty list is only produced when the student genuinely has no
/// class reminders, or has switched notifications off.
final pendingClassRemindersProvider =
    Provider<List<CollegeOsNotification>?>((ref) {
      final settings = ref.watch(collegeSettingsProvider).value;
      if (settings?.notificationsEnabled != true) return const [];
      final snapshot = ref.watch(attendanceEngineProvider).value;
      final semester = ref.watch(activeSemesterProvider).value;
      final entries = ref.watch(timetableEntriesProvider).value;
      final now = ref.watch(localMinuteProvider).value;
      if (snapshot == null ||
          semester == null ||
          entries == null ||
          now == null) {
        return null;
      }
      return ClassReminderPlan.next(
        snapshot: snapshot,
        semester: semester,
        entries: entries,
        now: now,
      );
    });
