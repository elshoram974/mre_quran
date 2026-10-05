import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/quran_app.dart';
import 'core/crash/crash_reporter.dart';
import 'core/diagnostics/app_logger.dart';
import 'firebase_options.dart';
import 'features/settings/application/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final crashReporter = FirebaseCrashReporter();
  await crashReporter.setCollectionEnabled(false);
  FlutterError.onError = (details) =>
      AppLogger.flutterError(crashReporter, details);
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    return AppLogger.uncaughtPlatformError(crashReporter, error, stackTrace);
  };
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      child: ProviderScope(
        overrides: [crashReporterProvider.overrideWithValue(crashReporter)],
        child: const QuranApp(),
      ),
    ),
  );
}
