import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/pinch_zoom.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/prayer/application/place_search_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/data/place_name_source.dart';
import 'package:mre_quran/features/prayer/data/place_search_source.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_location_picker_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/adhan_fixtures.dart';
import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

/// A map that draws nothing and moves when a test says so, as a hand would.
class _FakeMaps extends GoogleMapsFlutterPlatform {
  final _started = StreamController<CameraMoveStartedEvent>.broadcast();
  final _moved = StreamController<CameraMoveEvent>.broadcast();
  final _idle = StreamController<CameraIdleEvent>.broadcast();
  int _mapId = -1;

  /// Pans the map until its middle is over [target], then lets go.
  void pan(LatLng target) {
    _started.add(CameraMoveStartedEvent(_mapId));
    _moved.add(
      CameraMoveEvent(_mapId, CameraPosition(target: target, zoom: 14)),
    );
    _idle.add(CameraIdleEvent(_mapId));
  }

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    // Built again at every change; the view is created once.
    if (_mapId != creationId) {
      _mapId = creationId;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onPlatformViewCreated(creationId),
      );
    }
    return const SizedBox.expand();
  }

  @override
  Future<void> init(int mapId) async {}

  @override
  Future<void> updateMapConfiguration(
    MapConfiguration configuration, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateMarkers(
    MarkerUpdates markerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolygons(
    PolygonUpdates polygonUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolylines(
    PolylineUpdates polylineUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateCircles(
    CircleUpdates circleUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateHeatmaps(
    HeatmapUpdates heatmapUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {}

  @override
  Future<void> updateClusterManagers(
    ClusterManagerUpdates clusterManagerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {}

  @override
  Future<void> moveCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {}

  @override
  void dispose({required int mapId}) {}

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) =>
      _started.stream;

  @override
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) => _moved.stream;

  @override
  Stream<CameraIdleEvent> onCameraIdle({required int mapId}) => _idle.stream;

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<PolygonTapEvent> onPolygonTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<CircleTapEvent> onCircleTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<PointOfInterestTapEvent> onPointOfInterestTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MapTapEvent> onTap({required int mapId}) => const Stream.empty();

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<GroundOverlayTapEvent> onGroundOverlayTap({required int mapId}) =>
      const Stream.empty();
}

class _Names implements PlaceNameSource {
  @override
  Future<String?> nameOf(PrayerPlace place, Locale locale) async =>
      place.latitude > 40 ? 'Istanbul, Türkiye' : 'القاهرة، مصر';
}

class _Search implements PlaceSearchSource {
  _Search(this.found);

  final List<PrayerPlace> found;

  @override
  Future<List<PrayerPlace>> search(String query, Locale locale) async => found;
}

final _cairo = PrayerPlace(30.04, 31.24);
final _istanbul = PrayerPlace(41.01, 28.97);

void main() {
  late _FakeMaps maps;
  late MemoryPrayerRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    maps = _FakeMaps();
    GoogleMapsFlutterPlatform.instance = maps;
    repository = MemoryPrayerRepository();
  });

  Future<void> open(
    WidgetTester tester, {
    String locale = 'ar',
    Size size = const Size(390, 844),
    double textScale = 1,
    ThemeData? theme,
    List<PrayerPlace> found = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/map'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (_, _) => const PrayerLocationPickerPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
          prayerRepositoryProvider.overrideWithValue(repository),
          adhanPlatformProvider.overrideWithValue(FakeAdhanPlatform()),
          locationSourceProvider.overrideWithValue(FakeLocationSource()),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 8, 9)),
          placeNameSourceProvider.overrideWithValue(_Names()),
          placeSearchSourceProvider.overrideWithValue(_Search(found)),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: Locale(locale),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme ?? AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'استخدم هذا الموقع'),
  );

  testWidgets('says what to do, that no place is chosen, and how to use the '
      'phone\'s own', (tester) async {
    await open(tester);
    expect(
      find.text('حرّك الخريطة حتى يشير رأس العلامة إلى مكانك'),
      findsOneWidget,
    );
    expect(find.text('لم تختر مكانًا بعد'), findsOneWidget);
    expect(find.text('الخريطة والبحث يحتاجان إلى الإنترنت.'), findsOneWidget);
    // The map has its own zoom: no text-size pinch is laid over it.
    expect(find.byType(PinchZoom), findsNothing);
    // A button with words, not only an icon.
    expect(find.text('استخدم موقعي الحالي'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('the pin is red and its tip is marked', (tester) async {
    await open(tester);
    final pin = tester.widget<Icon>(find.byIcon(Icons.location_pin));
    expect(pin.color, AppTheme.light.colorScheme.error);
  });

  testWidgets('moving the map chooses the place, names it, and saves it', (
    tester,
  ) async {
    await open(tester);
    maps.pan(const LatLng(30.04, 31.24));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('الإحداثيات'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
    // A moment after the map stops, the place has a name.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('الموقع: القاهرة، مصر'), findsOneWidget);
    await tester.tap(find.text('استخدم هذا الموقع'));
    await tester.pumpAndSettle();
    expect(repository.place?.latitude, 30.04);
    expect(repository.place?.name, 'القاهرة، مصر');
    // Back where it came from.
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a search that finds several places lists them by name', (
    tester,
  ) async {
    await open(tester, found: [_cairo, _istanbul]);
    await tester.enterText(find.byType(EditableText), 'x');
    await tester.tap(find.byTooltip('ابحث عن المكان'));
    await tester.pumpAndSettle();
    expect(find.text('القاهرة، مصر'), findsOneWidget);
    expect(find.text('Istanbul, Türkiye'), findsOneWidget);
    // The numbers stay under each name.
    expect(find.textContaining('الإحداثيات'), findsNWidgets(2));
    await tester.tap(find.text('Istanbul, Türkiye'));
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNotNull);
    expect(find.text('Istanbul, Türkiye'), findsNothing);
  });

  testWidgets('a search that finds nothing says so in red', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'x');
    await tester.tap(find.byTooltip('ابحث عن المكان'));
    await tester.pumpAndSettle();
    expect(find.text('لم نجد مكانًا بهذا الاسم.'), findsOneWidget);
  });

  for (final (name, locale, size, scale, theme) in [
    ('English, dark', 'en', const Size(390, 844), 1.0, AppTheme.dark),
    ('large text, compact', 'ar', const Size(320, 640), 2.0, AppTheme.light),
    ('a phone on its side', 'ar', const Size(844, 390), 1.0, AppTheme.light),
    ('expanded', 'en', const Size(1100, 800), 1.0, AppTheme.light),
  ]) {
    testWidgets('fits: $name', (tester) async {
      await open(
        tester,
        locale: locale,
        size: size,
        textScale: scale,
        theme: theme,
      );
      maps.pan(const LatLng(30.04, 31.24));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      // The panel scrolls rather than push the map away: save is reachable.
      final save = find.byType(FilledButton).last;
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
