import 'dart:async';

import 'package:flutter/foundation.dart';

import '../crash/crash_reporter.dart';

/// Central diagnostic output without personal data.
final class AppLogger {
  const AppLogger._();

  static void debug(String message) {
    if (kDebugMode) debugPrint('[MRE Quran] $message');
  }

  static void flutterError(
    CrashReporter reporter,
    FlutterErrorDetails details,
  ) {
    FlutterError.presentError(details);
    debug('Flutter error: ${details.exceptionAsString()}');
    unawaited(reporter.recordFlutterFatalError(details));
  }

  static bool uncaughtPlatformError(
    CrashReporter reporter,
    Object error,
    StackTrace stackTrace,
  ) {
    debug('Uncaught platform error: $error');
    unawaited(
      reporter.recordError(
        error,
        stackTrace,
        reason: 'Uncaught platform error',
        fatal: true,
      ),
    );
    return true;
  }
}
