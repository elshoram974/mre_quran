import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics/haptics.dart';
import '../domain/adhkar_collection.dart';
import '../domain/dhikr.dart';
import 'adhkar_providers.dart';

/// What one tap on a counter did.
enum CountOutcome {
  /// Nothing: the dhikr was already done.
  ignored,

  /// One more repeat.
  counted,

  /// The last repeat of this dhikr.
  finishedDhikr,

  /// The last repeat of the last dhikr: the whole list is done.
  finishedList,
}

/// Counts one repeat of [entry] and gives the feedback for it.
///
/// The feeling comes the moment the finger lands, before anything is saved: a
/// light tick for a repeat, a firmer pulse when the dhikr is done and the next
/// is due, a double pulse when the whole list is done. Both the list page and
/// the steps sheet count through here, so they behave alike.
Future<CountOutcome> countDhikr(
  WidgetRef ref,
  AdhkarCollection collection,
  Dhikr entry,
) async {
  final count = ref.read(dhikrCountProvider((collection, entry)));
  if (count >= entry.repeat) return CountOutcome.ignored;
  final finishes = count + 1 >= entry.repeat;
  final lastOne =
      finishes &&
      collection.entries.every(
        (other) =>
            other == entry ||
            ref.read(dhikrCountProvider((collection, other))) >= other.repeat,
      );
  final outcome = lastOne
      ? CountOutcome.finishedList
      : finishes
      ? CountOutcome.finishedDhikr
      : CountOutcome.counted;
  unawaited(switch (outcome) {
    CountOutcome.finishedList => Haptics.celebrate(),
    CountOutcome.finishedDhikr => Haptics.step(),
    _ => Haptics.tick(),
  });
  await ref.read(adhkarProgressProvider.notifier).increment(collection, entry);
  return outcome;
}
