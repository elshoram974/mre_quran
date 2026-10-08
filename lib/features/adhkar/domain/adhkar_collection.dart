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

  /// Home, clothing, and food.
  home,

  /// Worry, hardship, and illness.
  worry,

  /// Funerals and loss.
  janaza,

  /// Wind, rain, and the moon.
  weather,

  /// Manners and dealings with people.
  social,

  /// Travel and pilgrimage.
  travel,

  /// Praise and seeking forgiveness.
  virtue,

  /// Used when a manifest names an icon the app does not know.
  generic;

  /// Reads a manifest icon name, falling back to [generic].
  static AdhkarIcon parse(Object? name) => AdhkarIcon.values.firstWhere(
    (icon) => icon.name == name,
    orElse: () => generic,
  );
}

/// A section of the Adhkar tab that holds related collections.
@immutable
class AdhkarGroup {
  /// Creates a group.
  const AdhkarGroup({
    required this.id,
    required this.titles,
    this.icon = AdhkarIcon.generic,
  });

  /// Stable id used in routes and in the manifest.
  final String id;

  /// Title per language code. Always has an Arabic entry.
  final Map<String, String> titles;

  /// Icon shown on the group card.
  final AdhkarIcon icon;

  /// Title in [languageCode], or Arabic when that language has none.
  String title(String languageCode) => titles[languageCode] ?? titles['ar']!;

  @override
  bool operator ==(Object other) => other is AdhkarGroup && other.id == id;

  @override
  int get hashCode => id.hashCode;
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
    required this.group,
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

  /// The section it appears in.
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
  /// Creates a catalog of [collections] in [groups].
  const AdhkarCatalog(this.collections, {this.groups = const []});

  /// The collections.
  final List<AdhkarCollection> collections;

  /// The groups, in display order. Only groups that hold a collection.
  final List<AdhkarGroup> groups;

  /// The collections of [group], in order.
  List<AdhkarCollection> collectionsIn(AdhkarGroup group) => [
    for (final collection in collections)
      if (collection.group == group) collection,
  ];

  /// The group with [id], or null.
  AdhkarGroup? groupById(String id) {
    for (final group in groups) {
      if (group.id == id) return group;
    }
    return null;
  }

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
