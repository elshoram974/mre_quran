import 'dart:async';

import 'package:flutter/foundation.dart';

import '../crash/crash_reporter.dart';

/// Central diagnostic output without personal data.
///
/// Once [attach]ed to the crash reporter, every [debug] line is also kept as
/// a breadcrumb: a crash report then carries what the app did just before it
/// (Crashlytics keeps the last ones with the next report). The lines name
/// kinds of failures and steps, never what the person read or where they are.
final class AppLogger {
  const AppLogger._();

  static CrashReporter? _reporter;

  /// Sends the breadcrumbs and recovered errors to [reporter].
  static void attach(CrashReporter reporter) => _reporter = reporter;

  /// Forgets the reporter. Tests call it.
  @visibleForTesting
  static void detach() => _reporter = null;

  static void debug(String message) {
    if (kDebugMode) debugPrint('[Mushafi] $message');
    final reporter = _reporter;
    if (reporter != null) unawaited(reporter.log(message));
  }

  /// Reports an error the app recovered from, with its whole stack and
  /// [reason]: it did no harm this time, but it should not have happened.
  static void recovered(Object error, StackTrace stackTrace, String reason) {
    debug('Recovered: $reason (${error.runtimeType})');
    // Outside release builds (debug and profile), the whole of it in the
    // device log, to find out why.
    if (!kReleaseMode) debugPrint('[Mushafi] $error\n$stackTrace');
    final reporter = _reporter;
    if (reporter == null) return;
    unawaited(reporter.recordError(error, stackTrace, reason: reason));
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
