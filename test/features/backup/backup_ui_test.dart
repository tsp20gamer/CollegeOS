import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/backup/data/backup_file_gateway.dart';
import 'package:college_os/features/backup/data/backup_service.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:college_os/features/backup/presentation/screens/data_backup_screen.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/settings/data/attendance_csv_exporter.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows restore preview and replaces data only after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = AppDatabase.forTesting(NativeDatabase.memory());
      await _setup(source, 'Backup College');
      final sourceStore = DriftBackupDatabaseStore(source);
      final backup = await CollegeOsBackupService(
        sourceStore,
        CollegeOsBackupCodec(),
        _MemoryEmergencyStore(),
        now: () => DateTime(2026, 8, 12, 15),
      ).create('1.0.0+1');
      await source.close();
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(target.close);
      await _setup(target, 'Current College');
      final gateway = _PickedFileGateway(backup);
      final attendanceGateway = _MemoryAttendanceCsvGateway();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(target),
            backupFileGatewayProvider.overrideWithValue(gateway),
            attendanceCsvFileGatewayProvider.overrideWithValue(
              attendanceGateway,
            ),
            emergencyBackupStoreProvider.overrideWithValue(
              _MemoryEmergencyStore(),
            ),
            appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
          ],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('home_dashboard_ready')),
      );
      await tester.tap(find.byKey(const Key('open_settings_button')));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpUntilFound(tester, find.text('College Information'));
      await tester.scrollUntilVisible(
        find.byKey(const Key('import_backup_tile')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.byKey(const Key('import_backup_tile')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('import_backup_tile')));
      await _pumpUntilFound(tester, find.text('Your data belongs to you'));
      await tester.tap(find.byKey(const Key('export_data')));
      await _pumpUntilFound(tester, find.text('Choose export'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('export_full_backup')), findsOneWidget);
      expect(find.byKey(const Key('export_attendance_report')), findsOneWidget);
      expect(
        find.text(
          'A full backup already includes attendance and every other CollegeOS record.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('export_attendance_report')));
      await _pumpUntilFound(
        tester,
        find.text('Attendance CSV saved successfully.'),
      );
      expect(attendanceGateway.savedFile, isNotNull);
      expect(attendanceGateway.savedFile!.fileName, endsWith('.csv'));
      await tester.scrollUntilVisible(
        find.byKey(const Key('automatic_local_backup_switch')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Automatic Local Backup'), findsOneWidget);
      expect(find.text('Keep Backups'), findsOneWidget);
      expect(
        find.text(
          'Local backups remain on this phone. Export a backup to protect your data when changing devices.',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('import_backup')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('import_backup')));
      await _pumpUntilFound(tester, find.text('Restore preview'));

      expect(find.text('Backup College'), findsOneWidget);
      expect(find.text('Semester 1'), findsOneWidget);
      expect(
        find.text('Existing CollegeOS data on this device will be replaced.'),
        findsOneWidget,
      );
      expect(
        (await target.settingsDao.getSettings()).collegeName,
        'Current College',
      );

      final restoreButton = find.byKey(
        const Key('restore_backup_from_preview'),
      );
      tester.widget<FilledButton>(restoreButton).onPressed!();
      await _pumpUntilFound(tester, find.text('Replace current data?'));
      expect(find.text('Replace current data?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_restore_backup')));
      // Home no longer shows the college banner, so the restored name is no
      // longer a Home probe: wait for Home to be ready and let the stored
      // settings below prove the restore replaced the data.
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('home_dashboard_ready')),
      );
      expect(
        (await target.settingsDao.getSettings()).collegeName,
        'Backup College',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

  testWidgets('opened .collegeos file immediately shows restore preview', (
    tester,
  ) async {
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    await _setup(source, 'Opened Backup College');
    final sourceStore = DriftBackupDatabaseStore(source);
    final sourceService = CollegeOsBackupService(
      sourceStore,
      CollegeOsBackupCodec(),
      _MemoryEmergencyStore(),
      now: () => DateTime(2026, 8, 12, 15),
    );
    final backup = await sourceService.create('1.0.0+1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(source),
          incomingBackupLoaderProvider.overrideWithValue(
            (_) async => backup.bytes,
          ),
          incomingBackupCleanupProvider.overrideWithValue((_) async {}),
        ],
        child: MaterialApp(
          home: DataBackupScreen(
            restoreOnly: true,
            incomingBackupPath: backup.fileName,
          ),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Restore preview'));

    expect(find.text('Opened Backup College'), findsOneWidget);
    Navigator.of(tester.element(find.text('Restore preview'))).pop(false);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final class _PickedFileGateway implements BackupFileGateway {
  const _PickedFileGateway(this.backup);
  final ExportedBackup backup;

  @override
  Future<PickedBackupFile?> pick() async =>
      PickedBackupFile(name: backup.fileName, bytes: backup.bytes);

  @override
  Future<bool> save(ExportedBackup backup) async => true;

  @override
  Future<void> share(ExportedBackup backup) async {}
}

final class _MemoryEmergencyStore implements EmergencyBackupStore {
  @override
  Future<void> clear() async {}

  @override
  Future<void> save(ExportedBackup backup) async {}
}

final class _MemoryAttendanceCsvGateway implements AttendanceCsvFileGateway {
  AttendanceCsvFile? savedFile;

  @override
  Future<bool> save(AttendanceCsvFile file) async {
    savedFile = file;
    return true;
  }
}

Future<void> _setup(AppDatabase database, String collegeName) async {
  await DriftOnboardingRepository(database).completeSetup(
    CollegeSetup(
      studentName: 'Test Student',
      collegeName: collegeName,
      course: 'B.Tech',
      branch: 'Computer Science',
      semesterNumber: 1,
      academicYear: '2026-2027',
      semesterStartDate: DateTime(2026, 8, 1),
      semesterEndDate: DateTime(2026, 12, 20),
      defaultAttendanceTarget: 0.75,
    ),
  );
  final semester = await database.semestersDao.findActive();
  await DriftSubjectRepository(database.subjectsDao).create((
    semesterId: semester!.id,
    name: 'Operating Systems',
    shortCode: 'OS',
    professor: 'Dr Rao',
    room: 'A-101',
    attendanceTarget: 0.75,
    displayColor: 0xFF2563EB,
  ));
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}
