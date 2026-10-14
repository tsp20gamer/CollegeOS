import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/routing/navigation_shell.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:college_os/features/subject_files/presentation/screens/pdf_viewer_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Opening a document from the Notes tab must not leave the floating dock on
/// top of it.
///
/// The viewer's PDF rendering is deliberately not exercised here: Syncfusion's
/// viewer does not settle under `flutter_test`, so this test covers where the
/// reader is pushed and what the shell draws around it. The right-edge page
/// scrubber has its own widget test.
void main() {
  late AppDatabase database;
  late Directory tempDir;
  late int fileId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp(
      'collegeos_document_reader',
    );
    await DriftOnboardingRepository(database).completeSetup(
      CollegeSetup(
        studentName: 'Alexandria Student',
        collegeName: 'City College of Engineering and Technology',
        course: 'Bachelor of Technology',
        branch: 'Computer Science and Engineering',
        semesterNumber: 5,
        academicYear: '2026-2027',
        semesterStartDate: DateTime(2026, 8, 1),
        semesterEndDate: DateTime(2026, 12, 20),
        defaultAttendanceTarget: 0.75,
      ),
    );
    final semester = (await database.semestersDao.findActive())!;
    final subjectId = await database
        .into(database.subjects)
        .insert(
          SubjectsCompanion.insert(
            semesterId: semester.id,
            name: 'Responsive Design Systems',
            displayColor: 0xFF4758D6,
          ),
        );
    fileId = await database.subjectFilesDao.insertFile(
      SubjectFilesCompanion.insert(
        subjectId: subjectId,
        semesterId: semester.id,
        title: const Value('UNIT III - ENERGY SOURCES'),
        fileName: 'unit3.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 2048,
        relativeFilePath: _pdfPath,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('opens a document above the shell, clear of the dock', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          subjectFileStorageServiceProvider.overrideWithValue(
            _TempDirStorage(tempDir),
          ),
        ],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('home_dashboard_ready')),
    );

    await tester.tap(find.byKey(const Key('nav_notes')));
    await _pumpFrames(tester);

    // The dock is on screen while browsing; that is where it belongs.
    expect(find.byType(CollegeNavigationBar), findsOneWidget);
    expect(find.byKey(const Key('navigation_bar_surface')), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('notes_file_$fileId')));
    await _pumpUntilFound(tester, find.byType(PdfViewerScreen));
    await _pumpFrames(tester);

    // The reader is a full screen of its own: the dock is not drawn over it,
    // and the title proves the document screen is the one on top.
    expect(find.text('UNIT III - ENERGY SOURCES'), findsOneWidget);
    expect(find.byType(CollegeNavigationBar), findsNothing);
    expect(find.byKey(const Key('navigation_bar_surface')), findsNothing);

    await tester.tap(find.byType(BackButton));
    await _pumpFrames(tester);

    // Back in the Notes tab, with the dock restored.
    expect(find.byType(PdfViewerScreen), findsNothing);
    expect(find.byType(CollegeNavigationBar), findsOneWidget);
    expect(find.byKey(const Key('navigation_bar_surface')), findsOneWidget);

    await _disposeApp(tester);
  });
}

const _pdfPath = 'subject_files/1/unit3.pdf';

/// Resolves stored documents against a temporary directory instead of the
/// device's application support directory.
class _TempDirStorage implements SubjectFileStorageService {
  _TempDirStorage(this.baseDir);

  final Directory baseDir;

  @override
  Future<File> resolveFile(String relativeFilePath) async =>
      File(p.join(baseDir.path, relativeFilePath));

  @override
  Future<void> deleteFile(String relativeFilePath) async {}

  @override
  Future<void> openOrShareFile(String relativeFilePath, String title) async {}

  @override
  Future<({String fileExtension, int fileSizeBytes, String relativeFilePath})>
  saveFile({
    required int subjectId,
    required String originalFileName,
    required Uint8List bytes,
  }) async => throw UnimplementedError();

  @override
  Future<({String fileExtension, int fileSizeBytes, String relativeFilePath})>
  saveFileFromPath({
    required int subjectId,
    required String originalFileName,
    required String sourceFilePath,
  }) async => throw UnimplementedError();
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDurations.medium);
  await tester.pump(AppDurations.medium);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}
