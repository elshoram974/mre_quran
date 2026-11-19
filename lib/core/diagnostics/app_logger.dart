import 'dart:async';

import 'package:flutter/foundation.dart';

import '../crash/crash_reporter.dart';

/// Central diagnostic output without personal data.
final class AppLogger {
  const AppLogger._();

  static void debug(String message) {
    if (kDebugMode) debugPrint('[Mushafi] $message');
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

  /// An earlier launch stayed on the launch screen and never showed its
  /// first frame. [trace] holds its steps (names and milliseconds only), so
  /// the report says where it stopped.
  static void launchStalled(CrashReporter reporter, String trace) {
    debug('An earlier launch stalled on the launch screen: $trace');
    unawaited(
      reporter.recordError(
        LaunchStalled(trace),
        StackTrace.current,
        reason: 'Launch stayed on the launch screen',
      ),
    );
  }
}

/// A launch that never showed its first frame, with its steps.
final class LaunchStalled implements Exception {
  /// Creates the report of [trace].
  const LaunchStalled(this.trace);

  /// The launch's steps: where it came from, then `step@milliseconds`.
  final String trace;

  @override
  String toString() => 'LaunchStalled: $trace';
}
