import 'package:meta/meta.dart';

import 'adhkar_collection.dart';
import 'dhikr.dart';

/// What the person has said today. Counts start again each local day.
@immutable
class AdhkarProgress {
  /// Creates progress for [day] (`yyyy-MM-dd`, local) holding [counts].
  const AdhkarProgress({
    required this.day,
    this.counts = const {},
    this.touched = const {},
  });

  /// Reads progress saved by [toJson]. Returns an empty value for [day]
  /// when nothing was saved, the data is unreadable, or it is from another day.
  factory AdhkarProgress.fromJson(Object? json, {required String day}) {
    if (json is! Map<String, Object?> || json['day'] != day) {
      return AdhkarProgress(day: day);
    }
    final raw = json['counts'];
    if (raw is! Map<String, Object?>) return AdhkarProgress(day: day);
    final stamps = json['touched'];
    return AdhkarProgress(
      day: day,
      counts: {
        for (final entry in raw.entries)
          if (entry.value case final int count when count > 0) entry.key: count,
      },
      touched: {
        if (stamps is Map<String, Object?>)
          for (final entry in stamps.entries)
            if (entry.value case final int at) entry.key: at,
      },
    );
  }

  /// Local day as `yyyy-MM-dd`.
  final String day;

  /// Times said per entry, keyed by [key]. Missing means zero.
  final Map<String, int> counts;

  /// When each collection was last counted, in milliseconds since the epoch.
  final Map<String, int> touched;

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
  AdhkarProgress increment(
    AdhkarCollection collection,
    Dhikr dhikr, {
    required DateTime now,
  }) {
    final current = countOf(collection, dhikr);
    if (current >= dhikr.repeat) return this;
    return AdhkarProgress(
      day: day,
      counts: {...counts, key(collection, dhikr): current + 1},
      touched: {...touched, collection.id: now.millisecondsSinceEpoch},
    );
  }

  /// One repeat less of [dhikr], never below zero.
  AdhkarProgress decrement(
    AdhkarCollection collection,
    Dhikr dhikr, {
    required DateTime now,
  }) {
    final current = countOf(collection, dhikr);
    if (current == 0) return this;
    final next = {...counts};
    if (current == 1) {
      next.remove(key(collection, dhikr));
    } else {
      next[key(collection, dhikr)] = current - 1;
    }
    return AdhkarProgress(
      day: day,
      counts: next,
      touched: {...touched, collection.id: now.millisecondsSinceEpoch},
    );
  }

  /// Progress with every count of [collection] cleared.
  AdhkarProgress reset(AdhkarCollection collection) => AdhkarProgress(
    day: day,
    counts: {
      for (final entry in counts.entries)
        if (!entry.key.startsWith('${collection.id}:')) entry.key: entry.value,
    },
    touched: {
      for (final entry in touched.entries)
        if (entry.key != collection.id) entry.key: entry.value,
    },
  );

  /// Whether [collection] keeps counts for a prayer-length window and the
  /// person was counting in it within that window of [now].
  bool isSessionActive(AdhkarCollection collection, DateTime now) {
    final window = collection.sessionWindowMinutes;
    final at = touched[collection.id];
    if (window == null || at == null) return false;
    return now.millisecondsSinceEpoch - at <= window * 60 * 1000;
  }

  /// Progress with the counts of every windowed collection whose window has
  /// passed cleared, so a new prayer starts from zero.
  AdhkarProgress settle(Iterable<AdhkarCollection> collections, DateTime now) {
    var settled = this;
    for (final collection in collections) {
      if (collection.sessionWindowMinutes == null) continue;
      final hasCounts = counts.keys.any(
        (key) => key.startsWith('${collection.id}:'),
      );
      if (hasCounts && !isSessionActive(collection, now)) {
        settled = settled.reset(collection);
      }
    }
    return settled;
  }

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'day': day,
    'counts': counts,
    'touched': touched,
  };
}
