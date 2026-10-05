import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';

/// An ayah the reader saved.
@immutable
class Bookmark {
  /// Creates a bookmark of [ref] made at [createdAt].
  const Bookmark({required this.ref, required this.createdAt});

  /// Reads a bookmark saved by [toJson]. Returns null for anything unreadable.
  static Bookmark? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final surah = json['s'];
    final ayah = json['a'];
    final at = json['t'];
    if (surah is! int || ayah is! int || at is! int) return null;
    return Bookmark(
      ref: AyahRef(surah, ayah),
      createdAt: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
    );
  }

  /// The saved ayah.
  final AyahRef ref;

  /// When it was saved.
  final DateTime createdAt;

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    's': ref.surah,
    'a': ref.ayah,
    't': createdAt.millisecondsSinceEpoch,
  };
}
