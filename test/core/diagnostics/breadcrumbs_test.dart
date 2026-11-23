import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/crash/crash_reporter.dart';
import 'package:mre_quran/core/diagnostics/app_logger.dart';

class _Recorder implements CrashReporter {
  final List<String> logs = [];
  final List<(Object, StackTrace, String?, bool)> errors = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async => errors.add((error, stackTrace, reason, fatal));

  @override
  Future<void> log(String message) async => logs.add(message);

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

void main() {
  tearDown(AppLogger.detach);

  test('once attached, each diagnostic line goes with the next report', () {
    final reporter = _Recorder();
    AppLogger.debug('before');
    AppLogger.attach(reporter);
    AppLogger.debug('Printed pages still offline: SocketException');
    expect(reporter.logs, ['Printed pages still offline: SocketException']);
  });

  test('an error the app recovered from is reported whole, not fatal', () {
    final reporter = _Recorder();
    AppLogger.attach(reporter);
    final stack = StackTrace.current;
    AppLogger.recovered(StateError('closed'), stack, 'View built afresh');
    final (error, trace, reason, fatal) = reporter.errors.single;
    expect(error, isA<StateError>());
    expect(trace, stack);
    expect(reason, 'View built afresh');
    expect(fatal, isFalse);
    // And it leaves its breadcrumb.
    expect(reporter.logs.single, contains('View built afresh'));
  });
}
