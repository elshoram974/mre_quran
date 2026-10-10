import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../domain/prayer_times.dart';

/// Searches a typed place name with the device's geocoding service.
abstract interface class PlaceSearchSource {
  /// Returns matching coordinates, or an empty list when none are available.
  Future<List<PrayerPlace>> search(String query, Locale locale);
}

/// Android and iOS implementation backed by their native geocoding service.
class PlatformPlaceSearchSource implements PlaceSearchSource {
  /// Creates a platform-backed search source.
  const PlatformPlaceSearchSource();

  @override
  Future<List<PrayerPlace>> search(String query, Locale locale) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final locations = await Geocoding().locationFromAddress(
        trimmed,
        locale: locale,
      );
      return locations
          .map((location) => PrayerPlace(location.latitude, location.longitude))
          .toSet()
          .toList(growable: false);
    } on Object catch (error) {
      AppLogger.debug('Place search failed: ${error.runtimeType}');
      return const [];
    }
  }
}
