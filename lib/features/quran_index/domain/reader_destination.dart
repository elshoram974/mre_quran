import 'package:flutter/foundation.dart';

import 'quran_metadata.dart';

/// Where the reader should go: a page, and optionally an ayah to highlight on
/// it. Returned by the index, search, and bookmarks.
@immutable
class ReaderDestination {
  /// Creates a destination on [page], highlighting [ayah] if given.
  const ReaderDestination({required this.page, this.ayah});

  /// Mushaf page, 1–604.
  final int page;

  /// Ayah to highlight, or null for none.
  final AyahRef? ayah;

  @override
  bool operator ==(Object other) =>
      other is ReaderDestination && other.page == page && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(page, ayah);

  @override
  String toString() => 'ReaderDestination(page: $page, ayah: $ayah)';
}
