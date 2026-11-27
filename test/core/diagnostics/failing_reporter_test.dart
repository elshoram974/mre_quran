import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/crash/crash_reporter.dart';
import 'package:mre_quran/core/diagnostics/app_logger.dart';

/// A reporter as Crashlytics is when its start-up values never arrived:
/// every call fails.
class _Failing implements CrashReporter {
  int calls = 0;

  Future<void> _fail() async {
    calls++;
    throw StateError("type 'Null' is not a subtype of type 'bool'");
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) => _fail();

  @override
  Future<void> log(String message) => _fail();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) => _fail();

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) => _fail();
}

/// A reporter that throws before it returns a future.
class _Throwing extends _Failing {
  @override
  Future<void> log(String message) =>
      throw StateError('throws on the call itself');

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) => throw StateError('throws on the call itself');
}

/// Runs [body] as `main` runs the app: each uncaught error goes to
/// [AppLogger.uncaughtPlatformError], as `PlatformDispatcher.onError` sends
/// it, and what that handler starts belongs to the same zone, as in the root
/// zone of the app. Returns how many uncaught errors there were, stopping at
/// 50 so that a loop shows as a number instead of a hang.
Future<int> _uncaughtErrors(CrashReporter reporter, void Function() body) {
  var uncaught = 0;
  final done = Completer<int>();
  late final Zone zone;
  runZonedGuarded(
    () {
      zone = Zone.current;
      AppLogger.attach(reporter);
      body();
      // After every microtask the body left, and the ones those left.
      Timer(const Duration(milliseconds: 50), () => done.complete(uncaught));
    },
    (error, stackTrace) {
      if (++uncaught > 50) return;
      zone.run(
        () => AppLogger.uncaughtPlatformError(reporter, error, stackTrace),
      );
    },
  );
  return done.future;
}

void main() {
  tearDown(AppLogger.detach);

  test('a reporter that fails on every call is never reported back to '
      'itself, so it cannot keep the app busy for ever', () async {
    // The launch that stayed on the launch screen: one failed start-up step
    // is logged, the log fails, the failure comes back as an uncaught error,
    // which is logged and reported, both fail, and so on.
    final reporter = _Failing();
    final uncaught = await _uncaughtErrors(
      reporter,
      () => AppLogger.debug('Startup crash collection unavailable: TypeError'),
    );
    expect(uncaught, 0);
    expect(reporter.calls, 1);
  });

  test('every kind of report swallows its reporter failing', () async {
    final reporter = _Failing();
    final uncaught = await _uncaughtErrors(reporter, () {
      AppLogger.recovered(StateError('closed'), StackTrace.empty, 'reason');
      AppLogger.uncaughtPlatformError(reporter, 'e', StackTrace.empty);
      AppLogger.launchStalled(reporter, 'android 31 from icon: start@1');
    });
    expect(uncaught, 0);
    // A breadcrumb and a record for each of the three.
    expect(reporter.calls, 6);
  });

  test('a reporter that throws before it returns a future does not throw '
      'into the caller', () async {
    // A throw into the caller would reach the zone's handler and be counted.
    final reporter = _Throwing();
    final uncaught = await _uncaughtErrors(reporter, () {
      AppLogger.debug('line');
      AppLogger.uncaughtPlatformError(reporter, 'e', StackTrace.empty);
    });
    expect(uncaught, 0);
  });
}
