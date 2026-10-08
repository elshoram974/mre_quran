import 'package:meta/meta.dart';

import 'adhkar_collection.dart';
import 'dhikr.dart';

/// What the person has said today. Counts start again each local day.
@immutable
class AdhkarProgress {
  /// Creates progress for [day] (`yyyy-MM-dd`, local) holding [counts].
  const AdhkarProgress({required this.day, this.counts = const {}});

  /// Reads progress saved by [toJson]. Returns an empty value for [day]
  /// when nothing was saved, the data is unreadable, or it is from another day.
  factory AdhkarProgress.fromJson(Object? json, {required String day}) {
    if (json is! Map<String, Object?> || json['day'] != day) {
      return AdhkarProgress(day: day);
    }
    final raw = json['counts'];
    if (raw is! Map<String, Object?>) return AdhkarProgress(day: day);
    return AdhkarProgress(
      day: day,
      counts: {
        for (final entry in raw.entries)
          if (entry.value case final int count when count > 0) entry.key: count,
      },
    );
  }

  /// Local day as `yyyy-MM-dd`.
  final String day;

  /// Times said per entry, keyed by [key]. Missing means zero.
  final Map<String, int> counts;

  /// Storage key of [dhikr] inside [collection].
  static String key(AdhkarCollection collection, Dhikr dhikr) =>
      '${collection.id}:${dhikr.order}';

  /// Formats [date] as the day key.
  static String dayOf(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  /// Times [dhikr] was said today.
  int countOf(AdhkarCollection collection, Dhikr dhikr) =>
      counts[key(collection, dhikr)] ?? 0;

  /// Whether [dhikr] reached its repeat count.
  bool isDone(AdhkarCollection collection, Dhikr dhikr) =>
      countOf(collection, dhikr) >= dhikr.repeat;

  /// How many entries of [collection] are finished.
  int doneEntries(AdhkarCollection collection) =>
      collection.entries.where((entry) => isDone(collection, entry)).length;

  /// Repeats said in [collection], each entry capped at its repeat count.
  int doneRepeats(AdhkarCollection collection) => collection.entries.fold(
    0,
    (sum, entry) => sum + countOf(collection, entry).clamp(0, entry.repeat),
  );

  /// Whether every entry of [collection] is finished.
  bool isComplete(AdhkarCollection collection) =>
      collection.entries.isNotEmpty &&
      doneEntries(collection) == collection.entries.length;

  /// One more repeat of [dhikr], never above its repeat count.
  AdhkarProgress increment(AdhkarCollection collection, Dhikr dhikr) {
    final current = countOf(collection, dhikr);
    if (current >= dhikr.repeat) return this;
    return AdhkarProgress(
      day: day,
      counts: {...counts, key(collection, dhikr): current + 1},
    );
  }

  /// One repeat less of [dhikr], never below zero.
  AdhkarProgress decrement(AdhkarCollection collection, Dhikr dhikr) {
    final current = countOf(collection, dhikr);
    if (current == 0) return this;
    final next = {...counts};
    if (current == 1) {
      next.remove(key(collection, dhikr));
    } else {
      next[key(collection, dhikr)] = current - 1;
    }
    return AdhkarProgress(day: day, counts: next);
  }

  /// Progress with every count of [collection] cleared.
  AdhkarProgress reset(AdhkarCollection collection) => AdhkarProgress(
    day: day,
    counts: {
      for (final entry in counts.entries)
        if (!entry.key.startsWith('${collection.id}:')) entry.key: entry.value,
    },
  );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {'day': day, 'counts': counts};
}
