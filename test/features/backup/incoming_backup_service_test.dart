import 'package:college_os/features/backup/application/incoming_backup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('collegeos.test/incoming_backup');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('emits a pending backup supplied by Android at startup', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'takePendingBackup');
          return r'C:\cache\CollegeOS_Backup.collegeos';
        });
    final service = IncomingBackupService(channel: channel);
    addTearDown(service.dispose);

    final event = service.events.first;
    await service.initialize();

    expect(
      await event,
      isA<IncomingBackupFile>().having(
        (value) => value.path,
        'path',
        r'C:\cache\CollegeOS_Backup.collegeos',
      ),
    );
  });

  test(
    'initialization is harmless when the Android channel is absent',
    () async {
      final service = IncomingBackupService(channel: channel);

      await service.initialize();
      await service.initialize();

      final completion = expectLater(service.events, emitsDone);
      await service.dispose();
      await completion;
    },
  );
}
