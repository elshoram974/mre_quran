/// The text carried by a notification so a tap can open the right screen.
abstract final class ReminderPayload {
  static const String _prefix = 'adhkar:';

  /// Payload that opens the prayer times.
  static const String prayerTimes = 'prayer:times';

  /// Opens the adhkar home when a widget has no suggested list yet.
  static const String adhkarHome = 'adhkar-home';

  /// Payload from the home-screen prayer widget that opens Adhan settings.
  static const String adhanSettings = 'adhan:settings';

  /// Payload that opens the adhkar collection [collectionId].
  static String forCollection(String collectionId) => '$_prefix$collectionId';

  static const String _surahPrefix = 'surah:';

  /// Payload that opens the Mushaf at the beginning of surah [surah].
  static String forSurah(int surah) => '$_surahPrefix$surah';

  /// The surah (1 to 114) inside [payload], or null for any other payload.
  static int? surah(String payload) {
    if (!payload.startsWith(_surahPrefix)) return null;
    final number = int.tryParse(payload.substring(_surahPrefix.length));
    return number != null && number >= 1 && number <= 114 ? number : null;
  }

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
