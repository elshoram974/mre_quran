import 'package:geolocator/geolocator.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../domain/prayer_times.dart';

/// What stands in the way of reading the location.
enum LocationProblem {
  /// Nothing: it can be read.
  none,

  /// Location is switched off on the phone.
  serviceOff,

  /// The person has not allowed it, and can be asked again.
  denied,

  /// It is blocked for good: only the phone's settings can allow it.
  blocked,
}

/// Finds where the device is, only roughly, to work out prayer times.
abstract interface class LocationSource {
  /// Why [request] cannot find the place now. [LocationProblem.none] when
  /// nothing stands in the way. Never asks for anything.
  Future<LocationProblem> problem();

  /// Opens the phone's settings, where [problem] is put right.
  Future<void> openSettings(LocationProblem problem);

  /// Asks for permission if it is needed, then returns a rounded place.
  /// Returns null when the person says no, or location is off. Call it only
  /// from an action the person took.
  Future<PrayerPlace?> request();

  /// Returns a rounded place only when permission is already given. Never asks.
  Future<PrayerPlace?> quiet();
}

/// [LocationSource] over `geolocator`, respecting the person's accuracy choice.
///
/// No background location, no foreground service: one reading, when the app is
/// open. The position is rounded to four decimals and never leaves the
/// device.
class GeolocatorLocationSource implements LocationSource {
  /// Creates the source.
  const GeolocatorLocationSource();

  @override
  Future<PrayerPlace?> request() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return await _read(permission, preferFresh: true);
    } on Object catch (error) {
      AppLogger.debug('Location request failed: ${error.runtimeType}');
      return null;
    }
  }

  @override
  Future<LocationProblem> problem() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationProblem.serviceOff;
      }
      return switch (await Geolocator.checkPermission()) {
        LocationPermission.denied => LocationProblem.denied,
        LocationPermission.deniedForever => LocationProblem.blocked,
        _ => LocationProblem.none,
      };
    } on Object catch (error) {
      AppLogger.debug('Location check failed: ${error.runtimeType}');
      return LocationProblem.none;
    }
  }

  @override
  Future<void> openSettings(LocationProblem problem) async {
    try {
      if (problem == LocationProblem.serviceOff) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } on Object catch (error) {
      AppLogger.debug('Settings did not open: ${error.runtimeType}');
    }
  }

  @override
  Future<PrayerPlace?> quiet() async {
    try {
      return await _read(
        await Geolocator.checkPermission(),
        preferFresh: false,
      );
    } on Object catch (error) {
      AppLogger.debug('Location read failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<PrayerPlace?> _read(
    LocationPermission permission, {
    required bool preferFresh,
  }) async {
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    Position? cached;
    try {
      cached = await Geolocator.getLastKnownPosition();
    } on Object {
      // A missing cache must not prevent a fresh request.
    }
    final cacheAge = cached == null
        ? null
        : DateTime.now().difference(cached.timestamp);
    final usableCache =
        cacheAge != null &&
            !cacheAge.isNegative &&
            cacheAge <= const Duration(minutes: 5)
        ? cached
        : null;
    if (!preferFresh && usableCache != null) {
      return PrayerPlace(usableCache.latitude, usableCache.longitude);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: preferFresh
              ? LocationAccuracy.high
              : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      final age = DateTime.now().difference(position.timestamp);
      if (!age.isNegative && age <= const Duration(minutes: 5)) {
        return PrayerPlace(position.latitude, position.longitude);
      }
      return usableCache == null
          ? null
          : PrayerPlace(usableCache.latitude, usableCache.longitude);
    } on Object {
      return usableCache == null
          ? null
          : PrayerPlace(usableCache.latitude, usableCache.longitude);
    }
  }
}
