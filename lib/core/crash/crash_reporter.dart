import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Boundary for opt-in crash reporting.
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

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) =>
      _crashlytics.recordFlutterFatalError(details);

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) =>
      _crashlytics.recordError(error, stackTrace, reason: reason, fatal: fatal);
}
