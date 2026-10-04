import 'package:college_os/app/bootstrap.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

Future<void> main() async {
  FlutterForegroundTask.initCommunicationPort();
  await bootstrap();
}
