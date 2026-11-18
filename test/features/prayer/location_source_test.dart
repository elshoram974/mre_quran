import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mre_quran/features/prayer/data/location_source.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';

class _LocationPlatform extends GeolocatorPlatform {
  Position? cached;
  Position? current;
  LocationSettings? requestedSettings;
  bool failCurrent = false;

  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => cached;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    requestedSettings = locationSettings;
    if (failCurrent) throw StateError('location unavailable');
    return current!;
  }
}

Position _position(double latitude, DateTime at) => Position(
  latitude: latitude,
  longitude: 31.2357,
  timestamp: at,
  accuracy: 100,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late GeolocatorPlatform previous;
  late _LocationPlatform platform;
  setUp(() {
    previous = GeolocatorPlatform.instance;
    platform = _LocationPlatform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = previous);

  test(
    'an explicit location request prefers a fresh fix to an old village',
    () async {
      platform.cached = _position(
        29.9,
        DateTime.now().subtract(const Duration(days: 1)),
      );
      platform.current = _position(30.0444, DateTime.now());
      final place = await const GeolocatorLocationSource().request();
      expect(place, PrayerPlace(30.0444, 31.2357));
      expect(platform.requestedSettings?.accuracy, LocationAccuracy.high);
    },
  );

  test('does not fall back to a stale cached location on failure', () async {
    platform.cached = _position(
      29.9,
      DateTime.now().subtract(const Duration(days: 1)),
    );
    platform.failCurrent = true;
    expect(await const GeolocatorLocationSource().request(), isNull);
  });

  test('rejects an old fix even when returned as current', () async {
    platform.current = _position(
      29.9,
      DateTime.now().subtract(const Duration(hours: 1)),
    );
    expect(await const GeolocatorLocationSource().request(), isNull);
  });

  test('uses a recent cached fix if a fresh fix fails', () async {
    platform.cached = _position(
      30.04,
      DateTime.now().subtract(const Duration(minutes: 1)),
    );
    platform.failCurrent = true;
    expect(
      await const GeolocatorLocationSource().request(),
      PrayerPlace(30.04, 31.2357),
    );
  });
}
