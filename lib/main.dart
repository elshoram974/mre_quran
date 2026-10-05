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
import 'firebase_options.dart';
import 'features/settings/application/settings_provider.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/startup/application/startup_providers.dart';
import 'features/startup/data/last_tab_repository.dart';

Future<void> main() async {
  // Device Preview replaces the binding, so it is skipped outside debug.
  if (kDebugMode) DevicePreview.enable();
  WidgetsFlutterBinding.ensureInitialized();
  syncPreviewPlatform();
  final preferences = SharedPreferencesAsync();
  // Independent start-up work runs in parallel so the first frame waits only
  // for the slowest item, not the sum of all of them.
  final (_, settings, lastTab, _) = await (
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    LocalSettingsRepository(preferences).load(),
    LocalLastTabRepository(preferences).load(),
    LiquidGlassWidgets.initialize(),
  ).wait;
  // Crashlytics exists only after Firebase is initialised above.
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
          initialLocationProvider.overrideWithValue(initialLocation),
          initialSettingsProvider.overrideWithValue((settings: settings)),
        ],
        child: const QuranApp(),
      ),
    ),
  );
}
