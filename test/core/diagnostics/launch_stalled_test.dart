import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/crash/crash_reporter.dart';
import 'package:mre_quran/core/diagnostics/app_logger.dart';

class _Recorder implements CrashReporter {
  final List<(Object, String?, bool)> errors = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async => errors.add((error, reason, fatal));

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

void main() {
  test('a stalled launch is reported, not fatal, with where it stopped', () {
    final reporter = _Recorder();
    const trace = 'android 36 from icon: engine@40 start@90 resume@120';
    AppLogger.launchStalled(reporter, trace);
    expect(reporter.errors, hasLength(1));
    final (error, reason, fatal) = reporter.errors.single;
    expect(error, isA<LaunchStalled>());
    expect((error as LaunchStalled).trace, trace);
    expect(error.toString(), contains('resume@120'));
    expect(reason, isNotNull);
    expect(fatal, isFalse);
  });
}
