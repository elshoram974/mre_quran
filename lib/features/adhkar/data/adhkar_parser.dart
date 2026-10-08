import 'dart:convert';

import '../domain/adhkar_collection.dart';
import '../domain/dhikr.dart';
import '../domain/quran_passage.dart';
import '../domain/reminder_setting.dart';

/// Raised when an adhkar data file or the manifest breaks the schema.
class AdhkarDataException implements Exception {
  /// Creates the exception with a short [message].
  const AdhkarDataException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'AdhkarDataException: $message';
}

/// One collection as declared in the manifest, before its entries are read.
class AdhkarCollectionSpec {
  /// Creates a spec.
  const AdhkarCollectionSpec({
    required this.id,
    required this.titles,
    required this.icon,
    required this.file,
    required this.sha256,
    required this.variants,
    this.group = AdhkarGroup.daily,
    this.sessionWindowMinutes,
    this.reminderMinutes,
  });

  /// Collection id.
  final String id;

  /// Title per language code.
  final Map<String, String> titles;

  /// Icon.
  final AdhkarIcon icon;

  /// File name inside `assets/adhkar/`.
  final String file;

  /// Expected SHA-256 of [file].
  final String sha256;

  /// Entry variants to take from [file].
  final Set<int> variants;

  /// Section of the tab the collection appears in.
  final AdhkarGroup group;

  /// Minutes counts are kept after the last tap, or null for a whole day.
  final int? sessionWindowMinutes;

  /// Default reminder time, if the collection has a reminder.
  final int? reminderMinutes;

  /// Builds the collection from the entries of its file.
  AdhkarCollection build(List<Dhikr> fileEntries) {
    final entries = [
      for (final entry in fileEntries)
        if (variants.contains(entry.variant)) entry,
    ];
    if (entries.isEmpty) {
      throw AdhkarDataException('Collection $id has no entries in $file');
    }
    return AdhkarCollection(
      id: id,
      titles: titles,
      icon: icon,
      entries: entries,
      group: group,
      sessionWindowMinutes: sessionWindowMinutes,
      reminderMinutes: reminderMinutes,
    );
  }
}

/// Reads the manifest and the entry files. Pure Dart so it can run off the
/// main isolate.
abstract final class AdhkarParser {
  /// Highest manifest schema this build understands.
  static const int supportedSchema = 1;

  /// Parses the manifest JSON into collection specs, in display order.
  static List<AdhkarCollectionSpec> parseManifest(String json) {
    final root = _map(jsonDecode(json), 'manifest');
    if (root['schema'] != supportedSchema) {
      throw AdhkarDataException(
        'Unsupported manifest schema ${root['schema']}',
      );
    }
    final raw = root['collections'];
    if (raw is! List<Object?> || raw.isEmpty) {
      throw const AdhkarDataException('Manifest has no collections');
    }
    final specs = [for (final item in raw) _spec(_map(item, 'collection'))];
    final ids = specs.map((spec) => spec.id).toSet();
    if (ids.length != specs.length) {
      throw const AdhkarDataException('Duplicate collection id');
    }
    return specs;
  }

  /// Parses one entry file. Every entry must carry its evidence.
  static List<Dhikr> parseEntries(String json) {
    final raw = jsonDecode(json);
    if (raw is! List<Object?>) {
      throw const AdhkarDataException('Entry file is not a list');
    }
    final entries = [for (final item in raw) _dhikr(_map(item, 'entry'))];
    final orders = entries.map((entry) => entry.order).toSet();
    if (orders.length != entries.length) {
      throw const AdhkarDataException('Duplicate entry order');
    }
    return entries;
  }

  static AdhkarCollectionSpec _spec(Map<String, Object?> json) {
    final id = _string(json, 'id');
    final titles = _map(json['title'], 'title of $id');
    if (titles['ar'] is! String) {
      throw AdhkarDataException('Collection $id needs an Arabic title');
    }
    final variants = json['variants'];
    if (variants is! List<Object?> || variants.any((v) => v is! int)) {
      throw AdhkarDataException('Collection $id needs integer variants');
    }
    final clock = json['reminderTime'];
    final minutes = ReminderSetting.parseClock(clock);
    if (clock != null && minutes == null) {
      throw AdhkarDataException('Collection $id has a bad reminderTime');
    }
    final window = json['sessionWindowMinutes'];
    if (window != null && (window is! int || window < 1)) {
      throw AdhkarDataException(
        'Collection $id has a bad sessionWindowMinutes',
      );
    }
    return AdhkarCollectionSpec(
      id: id,
      group: json['group'] == null
          ? AdhkarGroup.daily
          : AdhkarGroup.parse(json['group']),
      sessionWindowMinutes: window as int?,
      titles: {
        for (final entry in titles.entries)
          if (entry.value is String) entry.key: entry.value! as String,
      },
      icon: AdhkarIcon.parse(json['icon']),
      file: _string(json, 'file'),
      sha256: _string(json, 'sha256'),
      variants: variants.cast<int>().toSet(),
      reminderMinutes: minutes,
    );
  }

  static Dhikr _dhikr(Map<String, Object?> json) {
    final order = json['order'];
    final repeat = json['count'];
    final variant = json['type'];
    if (order is! int || repeat is! int || repeat < 1 || variant is! int) {
      throw AdhkarDataException('Entry $order has a bad order, count, or type');
    }
    final quran = _quran(json['quran'], order);
    final text = quran == null ? _string(json, 'content') : '';
    final source = _string(json, 'source');
    return Dhikr(
      order: order,
      text: text,
      repeat: repeat,
      repeatLabel: _optional(json['count_description']) ?? '',
      source: source,
      variant: variant,
      virtue: _optional(json['fadl']),
      hadithText: _optional(json['hadith_text']),
      vocabulary: _optional(json['explanation_of_hadith_vocabulary']),
      quran: quran,
    );
  }

  static QuranPassage? _quran(Object? value, int order) {
    if (value == null) return null;
    final json = _map(value, 'quran of entry $order');
    final ranges = json['ranges'];
    if (ranges is! List<Object?> || ranges.isEmpty) {
      throw AdhkarDataException('Entry $order has no ayah range');
    }
    final spans = <AyahSpan>[];
    for (final range in ranges) {
      final span = _map(range, 'range of entry $order');
      final surah = span['surah'];
      final from = span['from'];
      final to = span['to'];
      if (surah is! int ||
          from is! int ||
          to is! int ||
          surah < 1 ||
          surah > 114 ||
          from < 1 ||
          to < from) {
        throw AdhkarDataException('Entry $order has a bad ayah range');
      }
      spans.add(AyahSpan(surah: surah, from: from, to: to));
    }
    return QuranPassage(spans: spans, istiadha: json['istiadha'] == true);
  }

  static Map<String, Object?> _map(Object? value, String what) {
    if (value is Map<String, Object?>) return value;
    throw AdhkarDataException('Expected an object for $what');
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw AdhkarDataException('Missing "$key"');
  }

  static String? _optional(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;
}
