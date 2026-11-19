import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Boundary for crash reporting: on unless the person turns it off.
abstract interface class CrashReporter {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> log(String message);
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal,
  });
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);
}

/// Safe default for previews and tests that do not initialize Firebase.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}
}

/// Firebase-backed crash reporter.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  /// Debug builds never report: their crashes are the developer's, seen
  /// in the console, and would bury the real ones.
  ///
  /// Every method here is `async`, so a plugin that is not ready (it throws
  /// before it returns a future, as Crashlytics does when its native side
  /// has not reported yet) fails the returned future, never the caller: a
  /// caller that is `main` would otherwise end before `runApp`.
  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled && !kDebugMode);

  @override
  Future<void> log(String message) async => _crashlytics.log(message);

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async =>
      _crashlytics.recordFlutterFatalError(details);

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async =>
      _crashlytics.recordError(error, stackTrace, reason: reason, fatal: fatal);
}
