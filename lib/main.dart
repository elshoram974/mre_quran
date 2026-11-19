import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/quran_app.dart';
import 'core/assets/app_assets.dart';
import 'core/crash/crash_reporter.dart';
import 'core/diagnostics/app_logger.dart';
import 'core/haptics/haptics.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'core/theme/app_tokens.dart';
import 'firebase_options.dart';
import 'features/settings/application/settings_provider.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/domain/app_settings.dart';
import 'features/startup/application/launch_hold.dart';
import 'features/startup/application/startup_providers.dart';
import 'features/startup/data/startup_trace.dart';
import 'features/startup/data/last_tab_repository.dart';
import 'core/notifications/reminder_scheduler_provider.dart';

/// Each launch's steps, kept natively, so one that stays on the launch
/// screen can be reported by the next.
final StartupTrace _trace = StartupTrace.platform();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _trace.mark('dart:main');
  // Android 15+ always draws edge to edge; earlier versions do the same so
  // the app looks and lays out alike everywhere.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  final preferences = SharedPreferencesAsync();
  // Independent start-up work runs in parallel so the first frame waits only
  // for the slowest item, not the sum of all of them.
  // Shader warm-up has no bearing on whether the destination can open.
  unawaited(_optionalStartup('glass', LiquidGlassWidgets.initialize()));
  final (firebase, storedSettings, lastTab, reminderScheduler) = await (
    _optionalStartup(
      'Firebase',
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ),
    _optionalStartup('settings', LocalSettingsRepository(preferences).load()),
    _optionalStartup('last tab', LocalLastTabRepository(preferences).load()),
    LocalReminderScheduler.create(),
  ).wait;
  _trace.mark('dart:services');
  final settings = storedSettings ?? const AppSettings();
  Haptics.enabled = settings.hapticsEnabled;
  unawaited(Haptics.syncWidgetSetting(settings.hapticsEnabled));
  final CrashReporter crashReporter = firebase == null
      ? const NoopCrashReporter()
      : FirebaseCrashReporter();
  if (storedSettings != null) {
    unawaited(
      _optionalStartup(
        'crash collection',
        crashReporter.setCollectionEnabled(settings.crashReportsEnabled),
      ),
    );
  }
  FlutterError.onError = (details) =>
      AppLogger.flutterError(crashReporter, details);
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    return AppLogger.uncaughtPlatformError(crashReporter, error, stackTrace);
  };
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Amiri Quran',
    ], await rootBundle.loadString(AppAssets.amiriQuranLicense));
    yield LicenseEntryWithLineBreaks(const [
      'Morning and Evening Adhkar database (Seen Arabic)',
    ], await rootBundle.loadString(AppAssets.adhkarLicense));
  });
  // The native launch screen stays until the first screen is ready
  // (LaunchGate), and never longer than its limit.
  final launchHold = LaunchHold.hold(
    most: AppTokens.launchMost,
    onRelease: (reason) => _trace.mark('release:$reason'),
  );
  final initialLocation = resolveInitialLocation(
    settings.startupBehavior,
    lastTab,
  );
  _trace.mark('dart:runApp');
  unawaited(_reportStalledLaunch(crashReporter));
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      child: ProviderScope(
        overrides: [
          crashReporterProvider.overrideWithValue(crashReporter),
          reminderSchedulerProvider.overrideWithValue(reminderScheduler),
          initialLocationProvider.overrideWithValue(initialLocation),
          initialSettingsProvider.overrideWithValue((settings: storedSettings)),
          launchHoldProvider.overrideWithValue(launchHold),
        ],
        child: const QuranApp(),
      ),
    ),
  );
}

/// An unavailable platform service must not strand the native launch window.
Future<T?> _optionalStartup<T>(String service, Future<T> task) async {
  try {
    return await task.timeout(const Duration(seconds: 2));
  } on Object catch (error) {
    AppLogger.debug('Startup $service unavailable: ${error.runtimeType}');
    _trace.mark('unavailable:$service');
    return null;
  }
}

/// Once this launch's first frame is on screen, notes it, and reports an
/// earlier launch that never got there, with where it stopped.
Future<void> _reportStalledLaunch(CrashReporter reporter) async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  _trace.mark('dart:firstFrame');
  final stalled = _trace.takeStalled();
  if (stalled != null) AppLogger.launchStalled(reporter, stalled);
}
