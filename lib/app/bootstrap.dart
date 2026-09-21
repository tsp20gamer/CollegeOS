import 'package:college_os/app/app.dart';
import 'package:college_os/app/app_error_handling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppErrorHandling();
  runApp(const ProviderScope(child: CollegeOsApp()));
}
