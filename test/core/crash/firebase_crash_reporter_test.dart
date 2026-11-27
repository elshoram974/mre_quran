import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/crash/crash_reporter.dart';

/// Crashlytics as it is when its native side has not reported yet: each call
/// throws at once, before it returns a future.
class _NotReadyCrashlytics extends Fake implements FirebaseCrashlytics {
  @override
  bool get isCrashlyticsCollectionEnabled => true;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) =>
      throw StateError("type 'Null' is not a subtype of type 'bool'");

  @override
  Future<void> log(String message) => throw StateError('not ready');

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool? printDetails,
    bool fatal = false,
  }) => throw StateError('not ready');

  @override
  Future<void> recordFlutterFatalError(
    FlutterErrorDetails flutterErrorDetails,
  ) => throw StateError('not ready');
}

/// Crashlytics whose start-up values never reached Dart: reading any of them,
/// as every call does, throws.
class _WithoutStartUpValues extends Fake implements FirebaseCrashlytics {
  // As in the field: type 'Null' is not a subtype of type 'bool'.
  @override
  bool get isCrashlyticsCollectionEnabled => throw TypeError();
}

void main() {
  final reporter = FirebaseCrashReporter(crashlytics: _NotReadyCrashlytics());

  test('a Crashlytics without its start-up values is refused at once, so '
      'the app reports nothing instead of failing at every report', () {
    expect(
      () => FirebaseCrashReporter(crashlytics: _WithoutStartUpValues()),
      throwsA(isA<TypeError>()),
    );
  });

  test('a plugin that is not ready fails the future, not the caller', () async {
    // Called as an argument, as `main` does: a throw here would end `main`
    // before `runApp`.
    late Future<void> collection;
    expect(
      () => collection = reporter.setCollectionEnabled(true),
      returnsNormally,
    );
    await expectLater(collection, throwsStateError);

    late Future<void> log;
    expect(() => log = reporter.log('x'), returnsNormally);
    await expectLater(log, throwsStateError);

    late Future<void> error;
    expect(
      () => error = reporter.recordError('e', StackTrace.empty, fatal: true),
      returnsNormally,
    );
    await expectLater(error, throwsStateError);

    late Future<void> fatal;
    expect(
      () => fatal = reporter.recordFlutterFatalError(
        const FlutterErrorDetails(exception: 'e'),
      ),
      returnsNormally,
    );
    await expectLater(fatal, throwsStateError);
  });
}
