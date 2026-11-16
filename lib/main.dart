import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/quran_app.dart';
import 'core/crash/crash_reporter.dart';
import 'core/dev/preview_platform_sync.dart';
import 'core/diagnostics/app_logger.dart';
import 'core/haptics/haptics.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'firebase_options.dart';
import 'features/settings/application/settings_provider.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/startup/application/startup_providers.dart';
import 'features/startup/data/last_tab_repository.dart';
import 'core/notifications/reminder_scheduler_provider.dart';

Future<void> main() async {
  // Device Preview replaces the binding, so it is skipped outside debug.
  if (kDebugMode) DevicePreview.enable();
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15+ always draws edge to edge; earlier versions do the same so
  // the app looks and lays out alike everywhere.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  syncPreviewPlatform();
  final preferences = SharedPreferencesAsync();
  // Independent start-up work runs in parallel so the first frame waits only
  // for the slowest item, not the sum of all of them.
  final (_, settings, lastTab, _, reminderScheduler) = await (
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    LocalSettingsRepository(preferences).load(),
    LocalLastTabRepository(preferences).load(),
    LiquidGlassWidgets.initialize(),
    LocalReminderScheduler.create(),
  ).wait;
  // Crashlytics exists only after Firebase is initialised above.
  Haptics.enabled = settings.hapticsEnabled;
  final crashReporter = FirebaseCrashReporter();
  await crashReporter.setCollectionEnabled(settings.crashReportsEnabled);
  FlutterError.onError = (details) =>
      AppLogger.flutterError(crashReporter, details);
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    return AppLogger.uncaughtPlatformError(crashReporter, error, stackTrace);
  };
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Amiri Quran',
    ], await rootBundle.loadString('assets/fonts/amiri_quran/OFL.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Morning and Evening Adhkar database (Seen Arabic)',
    ], await rootBundle.loadString('assets/adhkar/LICENSE.seen-arabic.txt'));
  });
  final initialLocation = resolveInitialLocation(
    settings.startupBehavior,
    lastTab,
  );
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      child: ProviderScope(
        overrides: [
          crashReporterProvider.overrideWithValue(crashReporter),
          reminderSchedulerProvider.overrideWithValue(reminderScheduler),
          initialLocationProvider.overrideWithValue(initialLocation),
          initialSettingsProvider.overrideWithValue((settings: settings)),
        ],
        child: const QuranApp(),
      ),
    ),
  );
}
