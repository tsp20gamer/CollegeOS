import 'package:college_os/core/routing/navigation_shell.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_planner_screen.dart';
import 'package:college_os/features/attendance/presentation/screens/pending_attendance_screen.dart';
import 'package:college_os/features/attendance/presentation/screens/subject_attendance_screen.dart';
import 'package:college_os/features/backup/presentation/screens/data_backup_screen.dart';
import 'package:college_os/features/calendar/presentation/screens/academic_calendar_screen.dart';
import 'package:college_os/features/exams/presentation/screens/exams_marks_screen.dart';
import 'package:college_os/features/home/presentation/screens/home_screen.dart';
import 'package:college_os/features/help/presentation/screens/offline_help_screen.dart';
import 'package:college_os/features/marks/presentation/screens/subject_performance_screen.dart';
import 'package:college_os/features/notes/presentation/screens/notes_home_screen.dart';
import 'package:college_os/features/notes/presentation/screens/pdf_search_screen.dart';
import 'package:college_os/features/notes/presentation/screens/subject_notes_screen.dart';
import 'package:college_os/features/onboarding/application/onboarding_providers.dart';
import 'package:college_os/features/onboarding/presentation/screens/college_setup_screen.dart';
import 'package:college_os/features/onboarding/presentation/screens/startup_screen.dart';
import 'package:college_os/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:college_os/features/onboarding/presentation/screens/getting_started_screen.dart';
import 'package:college_os/features/reports/presentation/screens/reports_screen.dart';
import 'package:college_os/features/settings/presentation/screens/college_information_screen.dart';
import 'package:college_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:college_os/features/semesters/presentation/screens/semester_management_screen.dart';
import 'package:college_os/features/subjects/presentation/screens/subjects_screen.dart';
import 'package:college_os/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:college_os/features/timetable/presentation/screens/timetable_screen.dart';
import 'package:college_os/features/timetable/presentation/screens/timetable_exceptions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.onDispose(refresh.dispose);
  ref.listen(onboardingCompletedProvider, (_, _) => refresh.notify());

  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'rootNavigator'),
    initialLocation: RoutePaths.startup,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(onboardingCompletedProvider);
      final location = state.matchedLocation;

      if (status.isLoading) {
        return location == RoutePaths.startup ? null : RoutePaths.startup;
      }
      if (status.hasError) return null;

      final completed = status.value ?? false;
      final isSetupRoute =
          location == RoutePaths.welcome || location == RoutePaths.collegeSetup;
      final isRestoreRoute = location == RoutePaths.restoreBackup;

      if (!completed &&
          location != RoutePaths.startup &&
          !isSetupRoute &&
          !isRestoreRoute) {
        return RoutePaths.welcome;
      }
      if (completed && (location == RoutePaths.startup || isSetupRoute)) {
        return RoutePaths.home;
      }
      if (!completed && location == RoutePaths.startup) {
        return RoutePaths.welcome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.startup,
        name: RouteNames.startup,
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.collegeSetup,
        name: RouteNames.collegeSetup,
        builder: (context, state) => const CollegeSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.restoreBackup,
        name: RouteNames.restoreBackup,
        builder: (context, state) => DataBackupScreen(
          restoreOnly: true,
          incomingBackupPath: state.extra is String
              ? state.extra! as String
              : null,
        ),
      ),
      GoRoute(
        path: RoutePaths.gettingStarted,
        name: RouteNames.gettingStarted,
        builder: (context, state) => const GettingStartedScreen(),
      ),
      GoRoute(
        path: RoutePaths.subjectNotes,
        name: RouteNames.subjectNotes,
        builder: (context, state) => SubjectNotesScreen(
          subjectId:
              int.tryParse(state.pathParameters['subjectId'] ?? '') ?? -1,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.attendance,
                name: RouteNames.attendance,
                builder: (context, state) => const AttendanceScreen(),
                routes: [
                  GoRoute(
                    path: 'pending',
                    name: RouteNames.pendingAttendance,
                    builder: (context, state) =>
                        const PendingAttendanceScreen(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    name: RouteNames.attendanceAnalytics,
                    builder: (context, state) => const ReportsScreen(),
                  ),
                  GoRoute(
                    path: 'planner',
                    name: RouteNames.attendancePlanner,
                    builder: (context, state) =>
                        const AttendancePlannerScreen(),
                  ),
                  GoRoute(
                    path: 'subject/:subjectId',
                    name: RouteNames.attendanceSubject,
                    builder: (context, state) => SubjectAttendanceScreen(
                      subjectId:
                          int.tryParse(
                            state.pathParameters['subjectId'] ?? '',
                          ) ??
                          -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.timetable,
                name: RouteNames.timetable,
                builder: (context, state) => const TimetableScreen(),
                routes: [
                  GoRoute(
                    path: 'exceptions',
                    name: RouteNames.timetableExceptions,
                    builder: (context, state) =>
                        const TimetableExceptionsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.tasks,
                name: RouteNames.tasks,
                builder: (context, state) => TasksScreen(
                  openCreate: state.uri.queryParameters['new'] == 'true',
                  focusTaskId: int.tryParse(
                    state.uri.queryParameters['taskId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.notes,
                name: RouteNames.notes,
                builder: (context, state) => const NotesHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    name: RouteNames.notesSearch,
                    builder: (context, state) => const PdfSearchScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Settings is deliberately not a destination. Every tab header exposes it
      // as an action, and it pushes over the shell so it keeps a back button
      // while remaining reachable from anywhere in one tap.
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'subjects',
            name: RouteNames.subjects,
            builder: (context, state) => const SubjectsScreen(),
          ),
          GoRoute(
            path: 'exams-marks',
            name: RouteNames.examsMarks,
            builder: (context, state) => ExamsMarksScreen(
              focusExamId: int.tryParse(
                state.uri.queryParameters['examId'] ?? '',
              ),
            ),
            routes: [
              GoRoute(
                path: 'subject/:subjectId',
                name: RouteNames.subjectPerformance,
                builder: (context, state) => SubjectPerformanceScreen(
                  subjectId:
                      int.tryParse(state.pathParameters['subjectId'] ?? '') ??
                      -1,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'college-information',
            name: RouteNames.collegeInformation,
            builder: (context, state) => const CollegeInformationScreen(),
          ),
          GoRoute(
            path: 'semesters',
            name: RouteNames.semesters,
            builder: (context, state) => const SemesterManagementScreen(),
          ),
          GoRoute(
            path: 'data-backup',
            name: RouteNames.dataBackup,
            builder: (context, state) => const DataBackupScreen(),
          ),
          GoRoute(
            path: 'academic-calendar',
            name: RouteNames.academicCalendar,
            builder: (context, state) => const AcademicCalendarScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: RouteNames.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'help',
            name: RouteNames.help,
            builder: (context, state) => const OfflineHelpScreen(),
          ),
        ],
      ),
    ],
  );
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
