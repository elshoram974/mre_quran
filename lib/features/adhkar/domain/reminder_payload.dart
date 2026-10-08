/// The text carried by a reminder notification so a tap can open its list.
abstract final class ReminderPayload {
  static const String _prefix = 'adhkar:';

  /// Payload that opens the collection [collectionId].
  static String forCollection(String collectionId) => '$_prefix$collectionId';

  /// The collection id inside [payload], or null for a foreign payload.
  static String? collectionId(String payload) {
    if (!payload.startsWith(_prefix) || payload.length == _prefix.length) {
      return null;
    }
    return payload.substring(_prefix.length);
  }

  /// A notification id for [collectionId] that stays the same between runs
  /// (FNV-1a, kept in 31 bits because Android ids are signed 32-bit).
  static int notificationId(String collectionId) {
    var hash = 0x811c9dc5;
    for (final unit in collectionId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
