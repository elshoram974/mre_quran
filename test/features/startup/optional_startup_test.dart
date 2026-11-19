import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/startup/application/optional_startup.dart';

void main() {
  test('returns what the step returns', () async {
    expect(await optionalStartup('step', () async => 7), 7);
    expect(await optionalStartup('step', () => 8), 8);
  });

  test(
    'a step that throws before it returns a future is given up on',
    () async {
      // The case that left the launch screen up for good: a plugin that is not
      // ready throws on the call itself, not in a future, and was called where
      // nothing caught it.
      final unavailable = <String>[];
      final result = await optionalStartup<Object?>(
        'crash collection',
        () => throw StateError('not ready'),
        onUnavailable: unavailable.add,
      );
      expect(result, isNull);
      expect(unavailable, ['crash collection']);
    },
  );

  test('a step whose future fails is given up on', () async {
    final unavailable = <String>[];
    final result = await optionalStartup<int>(
      'settings',
      () => Future<int>.error(StateError('unreadable')),
      onUnavailable: unavailable.add,
    );
    expect(result, isNull);
    expect(unavailable, ['settings']);
  });

  test('a step that never finishes is given up on after its limit', () async {
    final unavailable = <String>[];
    final result = await optionalStartup<int>(
      'Firebase',
      () => Completer<int>().future,
      limit: const Duration(milliseconds: 20),
      onUnavailable: unavailable.add,
    );
    expect(result, isNull);
    expect(unavailable, ['Firebase']);
  });

  test('a step that finishes in time is not reported', () async {
    final unavailable = <String>[];
    final result = await optionalStartup<int>(
      'last tab',
      () => Future<int>.delayed(const Duration(milliseconds: 5), () => 3),
      limit: const Duration(seconds: 1),
      onUnavailable: unavailable.add,
    );
    expect(result, 3);
    expect(unavailable, isEmpty);
  });
}
