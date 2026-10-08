import 'package:meta/meta.dart';

import 'dhikr.dart';

/// Icon names a manifest may use. Presentation maps each to a glyph.
enum AdhkarIcon {
  /// Morning.
  sunrise,

  /// Evening.
  sunset,

  /// Sleep.
  sleep,

  /// Waking.
  wake,

  /// Around the prayer.
  prayer,

  /// Used when a manifest names an icon the app does not know.
  generic;

  /// Reads a manifest icon name, falling back to [generic].
  static AdhkarIcon parse(Object? name) => AdhkarIcon.values.firstWhere(
    (icon) => icon.name == name,
    orElse: () => generic,
  );
}

/// Where a collection sits on the adhkar tab.
enum AdhkarGroup {
  /// Said at a fixed time of day: morning, evening, sleep, waking.
  daily,

  /// Said around the prayer.
  prayer,

  /// Duas for a situation.
  duas;

  /// Reads a manifest group name, falling back to [duas].
  static AdhkarGroup parse(Object? name) => AdhkarGroup.values.firstWhere(
    (group) => group.name == name,
    orElse: () => duas,
  );
}

/// A named list of adhkar the person works through in one sitting.
@immutable
class AdhkarCollection {
  /// Creates a collection.
  const AdhkarCollection({
    required this.id,
    required this.titles,
    required this.icon,
    required this.entries,
    this.group = AdhkarGroup.daily,
    this.sessionWindowMinutes,
    this.reminderMinutes,
  });

  /// Stable id used in routes, progress, and reminders. Never reuse one.
  final String id;

  /// Title per language code. Always has an Arabic entry.
  final Map<String, String> titles;

  /// Icon shown on the collection card.
  final AdhkarIcon icon;

  /// The adhkar, in reading order.
  final List<Dhikr> entries;

  /// Which section of the tab it appears in.
  final AdhkarGroup group;

  /// For adhkar said once per prayer: how long after the last tap the counts
  /// are kept before the next prayer starts them again. Null means they last
  /// the whole day.
  final int? sessionWindowMinutes;

  /// Default reminder time as minutes after midnight, or null when the
  /// collection offers no reminder.
  final int? reminderMinutes;

  /// Title in [languageCode], or Arabic when that language has none.
  String title(String languageCode) => titles[languageCode] ?? titles['ar']!;

  /// Total number of repeats needed to finish the collection.
  int get totalRepeats => entries.fold(0, (sum, entry) => sum + entry.repeat);
}

/// Every collection the app ships, in display order.
@immutable
class AdhkarCatalog {
  /// Creates a catalog.
  const AdhkarCatalog(this.collections);

  /// The collections.
  final List<AdhkarCollection> collections;

  /// The collection with [id], or null.
  AdhkarCollection? byId(String id) {
    for (final collection in collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }
}

/// Picks the collection to offer first.
extension AdhkarSuggestion on AdhkarCatalog {
  /// The collection whose default reminder time is closest to [minutesNow]
  /// (minutes after midnight, wrapping at midnight), so the morning list leads
  /// in the morning and the evening list leads later in the day. Falls back to
  /// the first collection when none has a time. Null for an empty catalog.
  AdhkarCollection? suggestedAt(int minutesNow) {
    AdhkarCollection? best;
    var bestDistance = 1 << 30;
    for (final collection in collections) {
      final at = collection.reminderMinutes;
      if (at == null) continue;
      final gap = (at - minutesNow).abs();
      final distance = gap > 720 ? 1440 - gap : gap;
      if (distance < bestDistance) {
        best = collection;
        bestDistance = distance;
      }
    }
    return best ?? (collections.isEmpty ? null : collections.first);
  }
}
