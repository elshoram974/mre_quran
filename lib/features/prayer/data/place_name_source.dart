import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../domain/prayer_times.dart';

/// Finds what a place is called, from its coordinates.
abstract interface class PlaceNameSource {
  /// The name of [place] in [locale], such as "Cairo, Egypt", or null when it
  /// cannot be found (offline, or no geocoder on the phone).
  Future<String?> nameOf(PrayerPlace place, Locale locale);
}

/// Android and iOS implementation backed by their native geocoding service.
class PlatformPlaceNameSource implements PlaceNameSource {
  /// Creates a platform-backed source.
  const PlatformPlaceNameSource();

  @override
  Future<String?> nameOf(PrayerPlace place, Locale locale) async {
    try {
      final marks = await Geocoding()
          .placemarkFromCoordinates(
            place.latitude,
            place.longitude,
            locale: locale,
          )
          .timeout(const Duration(seconds: 8));
      for (final mark in marks) {
        final label = labelOf(mark);
        if (label != null) return label;
      }
      return null;
    } on Object catch (error) {
      AppLogger.debug('Place name failed: ${error.runtimeType}');
      return null;
    }
  }

  /// "City, Country" from [mark]: the nearest named area (the city, else its
  /// district or region) and the country. Null when it names neither.
  static String? labelOf(Placemark mark) {
    String? clean(String? value) {
      final text = value?.trim();
      return text == null || text.isEmpty ? null : text;
    }

    final area =
        clean(mark.locality) ??
        clean(mark.subAdministrativeArea) ??
        clean(mark.administrativeArea);
    final country = clean(mark.country);
    final parts = [?area, if (country != area) ?country];
    return parts.isEmpty ? null : parts.join(', ');
  }
}
