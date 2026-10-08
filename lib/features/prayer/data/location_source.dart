import 'package:geolocator/geolocator.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../domain/prayer_reminders.dart';

/// Finds where the device is, only roughly, to work out prayer times.
abstract interface class LocationSource {
  /// Asks for permission if it is needed, then returns a rounded place.
  /// Returns null when the person says no, or location is off. Call it only
  /// from an action the person took.
  Future<PrayerPlace?> request();

  /// Returns a rounded place only when permission is already given. Never asks.
  Future<PrayerPlace?> quiet();
}

/// [LocationSource] over `geolocator`, with approximate accuracy only.
///
/// No background location, no foreground service: one reading, when the app is
/// open. The position is rounded to about a kilometre and never leaves the
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
      return await _read(permission);
    } on Object catch (error) {
      AppLogger.debug('Location request failed: ${error.runtimeType}');
      return null;
    }
  }

  @override
  Future<PrayerPlace?> quiet() async {
    try {
      return await _read(await Geolocator.checkPermission());
    } on Object catch (error) {
      AppLogger.debug('Location read failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<PrayerPlace?> _read(LocationPermission permission) async {
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    final position =
        await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          ),
        );
    return PrayerPlace(position.latitude, position.longitude);
  }
}
