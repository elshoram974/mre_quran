import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/haptics/haptics.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/theme/app_tokens.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/core/widgets/app_shimmer.dart';
import 'package:mre_quran/features/prayer/application/compass_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/data/location_source.dart';
import 'package:mre_quran/features/prayer/data/prayer_repository.dart';
import 'package:mre_quran/features/prayer/domain/magnetic_field.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/domain/qibla.dart';
import 'package:mre_quran/features/prayer/presentation/qibla_compass.dart';
import 'package:mre_quran/features/prayer/presentation/qibla_page.dart';
import 'package:mre_quran/features/settings/application/digits_provider.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

final _cairo = PrayerPlace(30.04, 31.24);

/// The day the tests run on, and the Earth's magnetic field in Cairo that
/// day: magnetic north is nearly five degrees east of true north there.
final _today = DateTime.utc(2026, 11, 27);
final _cairoField = magneticField(
  latitude: _cairo.latitude,
  longitude: _cairo.longitude,
  year: decimalYear(_today),
);

/// A phone lying level, and one leaning with its right edge up.
const _level = PhoneTilt(angle: 2, dx: 0.02, dy: -0.02, level: true);
const _tilted = PhoneTilt(angle: 40, dx: 0.64, dy: 0, level: false);

/// A compass the test turns, and tilts, by hand.
class _FakeCompass implements CompassSource {
  final StreamController<CompassReading> controller =
      StreamController<CompassReading>();

  /// Points the top of the phone at [heading], counted from true north as the
  /// page shows it: in Cairo, where the tests stand, the sensors then read it
  /// from magnetic north. With no [tilt] it is a phone that cannot tell how
  /// it is held.
  void turn(double heading, {PhoneTilt? tilt}) =>
      reads(_cairoField.magneticFromTrue(heading), tilt: tilt);

  /// Makes the sensors read [magnetic], degrees from magnetic north.
  void reads(double magnetic, {PhoneTilt? tilt}) =>
      controller.add(CompassReading(heading: magnetic, tilt: tilt));

  @override
  Stream<CompassReading> readings() => controller.stream;
}

/// A device with no compass sensor.
class _NoCompass implements CompassSource {
  @override
  Stream<CompassReading> readings() =>
      Stream<CompassReading>.error('no sensor');
}

/// Keeps the page loading until the test opens [gate].
class _SlowRepository extends MemoryPrayerRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<PrayerSettings> loadSettings() async {
    await gate.future;
    return settings;
  }
}

/// A location that is still being read until the test opens [gate].
class _SlowLocation extends FakeLocationSource {
  _SlowLocation() : super(requestResult: _cairo);

  final Completer<void> gate = Completer<void>();

  @override
  Future<PrayerPlace?> request() async {
    await gate.future;
    return super.request();
  }
}

/// Pumps the page. A page kept loading never settles (its bar's loader
/// turns), so those tests pass `settle: false` and pump by hand.
Future<void> _pump(
  WidgetTester tester,
  CompassSource compass, {
  PrayerPlace? place,
  PrayerRepository? repository,
  LocationSource? location,
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  bool reduceMotion = false,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        compassSourceProvider.overrideWithValue(compass),
        locationSourceProvider.overrideWithValue(
          location ?? FakeLocationSource(requestResult: _cairo),
        ),
        prayerRepositoryProvider.overrideWithValue(
          repository ?? (MemoryPrayerRepository()..place = place),
        ),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        clockProvider.overrideWithValue(() => _today),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: const QiblaPage(),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// The page's own guard over its content: what it holds is dimmed and deaf
/// to touches while the page is inert.
IgnorePointer _guard(WidgetTester tester) => tester.widget<IgnorePointer>(
  find.byWidgetPredicate(
    (widget) => widget is IgnorePointer && widget.child is AnimatedOpacity,
  ),
);

double _dimming(WidgetTester tester) =>
    (_guard(tester).child! as AnimatedOpacity).opacity;

QiblaCompass _compass(WidgetTester tester) =>
    tester.widget<QiblaCompass>(find.byType(QiblaCompass));

/// The dial as drawn, with the size its entrance gives it.
final Finder _drawing = find.descendant(
  of: find.byType(QiblaCompass),
  matching: find.byType(CustomPaint),
);

/// The colour the dial is painted at [offset] from its centre, in the
/// phone's own directions: x to its right edge, y to its bottom edge.
Future<Color> _dialColour(WidgetTester tester, Offset offset) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find
        .ancestor(
          of: find.byType(QiblaCompass),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final at =
      boundary.globalToLocal(tester.getCenter(find.byType(QiblaCompass))) +
      offset;
  late final Color colour;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    final i = (at.dy.round() * image.width + at.dx.round()) * 4;
    colour = Color.fromARGB(
      bytes!.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
    image.dispose();
  });
  return colour;
}

/// Matches a painted colour, give or take the rounding of a channel.
Matcher _paints(Color expected) => predicate<Color>(
  (colour) =>
      (colour.r - expected.r).abs() < 0.02 &&
      (colour.g - expected.g).abs() < 0.02 &&
      (colour.b - expected.b).abs() < 0.02,
  'paints $expected',
);

void main() {
  final cairoQibla = qiblaBearing(_cairo);

  late RecordingHaptics haptics;
  late HapticsBackend previous;
  setUp(() {
    previous = Haptics.backend;
    haptics = RecordingHaptics();
    Haptics.backend = haptics;
  });
  tearDown(() => Haptics.backend = previous);

  testWidgets('asks for the location when there is no place yet', (
    tester,
  ) async {
    await _pump(tester, _FakeCompass());
    expect(find.text('اعرف مواقيت الصلاة'), findsOneWidget);
    expect(find.byType(QiblaCompass), findsNothing);
    await tester.tap(find.text('استخدم موقعي'));
    await tester.pumpAndSettle();
    expect(find.byType(QiblaCompass), findsOneWidget);
  });

  testWidgets('shows the Qibla angle and which way to turn', (tester) async {
    final compass = _FakeCompass();
    await _pump(tester, compass, place: _cairo);
    // Cairo's Qibla is about 136° (south-east).
    expect(find.textContaining('الجنوب الشرقي'), findsWidgets);

    compass.turn((cairoQibla - 40) % 360);
    await tester.pumpAndSettle();
    expect(find.textContaining('در يمينًا'), findsOneWidget);
    expect(haptics.calls, isEmpty);

    compass.turn((cairoQibla + 40) % 360);
    await tester.pumpAndSettle();
    expect(find.textContaining('در يسارًا'), findsOneWidget);
  });

  testWidgets('Arabic calibration hint uses the western figure 8', (
    tester,
  ) async {
    await _pump(tester, _FakeCompass(), place: _cairo);
    expect(find.textContaining('رقم 8'), findsOneWidget);
    expect(find.textContaining('رقم ٨'), findsNothing);
  });

  testWidgets('says so when the phone faces the Qibla, without vibrating', (
    tester,
  ) async {
    final compass = _FakeCompass();
    await _pump(tester, compass, place: _cairo);
    compass.turn(cairoQibla + 1);
    await tester.pumpAndSettle();
    expect(find.text('أنت تواجه القبلة'), findsOneWidget);
    // Vibration is kept for counting adhkar and for reminders.
    expect(haptics.calls, isEmpty);
    compass.turn(cairoQibla + 60);
    await tester.pumpAndSettle();
    expect(find.text('أنت تواجه القبلة'), findsNothing);
  });

  testWidgets('a device without a compass gets the fixed dial and a note', (
    tester,
  ) async {
    await _pump(tester, _NoCompass(), place: _cairo);
    expect(find.byType(QiblaCompass), findsOneWidget);
    expect(find.textContaining('لا يوجد في هذا الجهاز حساس'), findsOneWidget);
    expect(find.textContaining('در يمينًا'), findsNothing);
    expect(find.textContaining('در يسارًا'), findsNothing);
    expect(haptics.calls, isEmpty);
  });

  group('true north', () {
    testWidgets('facing the Qibla is judged from true north, not from the '
        'needle\'s north', (tester) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo);
      // In Cairo the needle's north is nearly five degrees east of true
      // north, more than the page forgives. A phone whose compass reads the
      // Qibla's own bearing has gone that far past it.
      expect(_cairoField.declination, greaterThan(qiblaTolerance));
      compass.reads(cairoQibla, tilt: _level);
      await tester.pumpAndSettle();
      expect(
        _compass(tester).heading,
        closeTo(cairoQibla + _cairoField.declination, 0.001),
      );
      expect(_compass(tester).aligned, isFalse);
      expect(find.text('أنت تواجه القبلة'), findsNothing);
      expect(find.textContaining('در يسارًا'), findsOneWidget);

      // The one that faces it reads the bearing less the declination.
      compass.reads(cairoQibla - _cairoField.declination, tilt: _level);
      await tester.pumpAndSettle();
      expect(_compass(tester).heading, closeTo(cairoQibla, 0.001));
      expect(_compass(tester).aligned, isTrue);
      expect(find.text('أنت تواجه القبلة'), findsOneWidget);
    });

    for (final (locale, north, onCompass) in [
      ('ar', 'من الشمال الحقيقي', 'وعلى البوصلة المغناطيسية تقع القبلة عند'),
      ('en', 'from true north', 'On a magnetic compass the Qibla is at'),
    ]) {
      testWidgets('without a compass the note also gives the bearing a hand '
          'compass reads ($locale)', (tester) async {
        await _pump(tester, _NoCompass(), place: _cairo, locale: locale);
        // 136° on the dial, from true north; about 131° on a needle.
        final magnetic = _cairoField.magneticFromTrue(cairoQibla).round();
        expect(magnetic, lessThan(cairoQibla.round() - qiblaTolerance));
        expect(find.textContaining(north), findsOneWidget);
        expect(
          find.textContaining(
            '$onCompass ${formatDigits(magnetic, arabic: true)}°',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the dial is announced to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _FakeCompass(), place: _cairo);
    expect(find.bySemanticsLabel(RegExp('بوصلة القبلة')), findsOneWidget);
    handle.dispose();
  });

  group('while the place loads', () {
    testWidgets('the page is drawn in full, inert, and its bar says loading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repository = _SlowRepository()..place = _cairo;
      await _pump(
        tester,
        _FakeCompass(),
        repository: repository,
        settle: false,
      );
      // The real page, not a skeleton: the dial with north up and no marker
      // yet, and the hints, all dimmed and deaf to touches.
      expect(find.byType(AppShimmer), findsNothing);
      expect(_compass(tester).qibla, isNull);
      expect(_compass(tester).heading, isNull);
      expect(find.textContaining('أمسك الهاتف أفقيًا'), findsOneWidget);
      expect(find.textContaining('رقم 8'), findsOneWidget);
      expect(_guard(tester).ignoring, isTrue);
      expect(_dimming(tester), AppTokens.inertOpacity);
      // Nothing untrue is said: no bearing yet, in words or to a screen
      // reader.
      expect(find.textContaining('الجنوب الشرقي'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('بوصلة القبلة')), findsNothing);

      // A wait worth mentioning: the bar says so, aloud too.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pump(AppTokens.loaderDelay);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('جارٍ التحميل…'), findsOneWidget);

      repository.gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_compass(tester).qibla, closeTo(cairoQibla, 0.001));
      expect(find.textContaining('الجنوب الشرقي'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('بوصلة القبلة')), findsOneWidget);
      expect(_guard(tester).ignoring, isFalse);
      expect(_dimming(tester), 1);
      handle.dispose();
    });

    // The test font is far wider than a real one: on a phone's width it
    // breaks the bearing over two lines, which no shipped font does.
    for (final (name, size) in [
      ('a medium window', const Size(700, 900)),
      ('a wide window', const Size(1100, 800)),
    ]) {
      testWidgets('nothing moves when the place and the first reading arrive '
          'on $name', (tester) async {
        final compass = _FakeCompass();
        final repository = _SlowRepository()..place = _cairo;
        await _pump(
          tester,
          compass,
          repository: repository,
          size: size,
          settle: false,
        );
        await tester.pump(AppTokens.loaderDelay);
        Rect dial() => tester.getRect(find.byType(QiblaCompass));
        Rect hint() => tester.getRect(find.textContaining('رقم 8'));
        Rect title() => tester.getRect(find.text('القبلة'));
        final dialBefore = dial();
        final hintBefore = hint();
        final titleBefore = title();

        repository.gate.complete();
        await tester.pumpAndSettle();
        expect(dial(), dialBefore);
        expect(hint(), hintBefore);
        expect(title(), titleBefore, reason: 'the loader moved the title');

        compass.turn(cairoQibla - 40);
        await tester.pumpAndSettle();
        expect(find.textContaining('در يمينًا'), findsOneWidget);
        expect(dial(), dialBefore);
        expect(hint(), hintBefore);
      });
    }

    testWidgets('the compass bounces in once, and never again', (tester) async {
      final compass = _FakeCompass();
      final repository = _SlowRepository()..place = _cairo;
      await _pump(tester, compass, repository: repository, settle: false);
      final full = tester.getSize(_drawing).width;
      double drawn() => tester.getRect(_drawing).width;
      // It starts small, passes its size, and comes back to it.
      expect(drawn(), closeTo(full * AppTokens.entranceScale, 0.01));
      var widest = 0.0;
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        widest = math.max(widest, drawn());
      }
      expect(widest, greaterThan(full));
      expect(drawn(), closeTo(full, 0.01));

      // The place arriving and the readings that follow leave it be.
      repository.gate.complete();
      await tester.pump();
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(drawn(), closeTo(full, 0.01));
      }
      compass.turn(cairoQibla - 40);
      await tester.pump();
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(drawn(), closeTo(full, 0.01));
      }
      await tester.pumpAndSettle();
    });

    testWidgets('with animations off the compass is simply there', (
      tester,
    ) async {
      final repository = _SlowRepository()..place = _cairo;
      await _pump(
        tester,
        _FakeCompass(),
        repository: repository,
        reduceMotion: true,
        settle: false,
      );
      final full = tester.getSize(_drawing).width;
      expect(tester.getRect(_drawing).width, closeTo(full, 0.01));
      // And the page comes alive at once, with no fade.
      repository.gate.complete();
      await tester.pump();
      await tester.pump();
      expect(_dimming(tester), 1);
      expect(find.textContaining('الجنوب الشرقي'), findsWidgets);
      expect(tester.getRect(_drawing).width, closeTo(full, 0.01));
      await tester.pumpAndSettle();
    });

    testWidgets('without a saved place it fades to the request for one', (
      tester,
    ) async {
      final repository = _SlowRepository();
      await _pump(
        tester,
        _FakeCompass(),
        repository: repository,
        settle: false,
      );
      expect(find.byType(QiblaCompass), findsOneWidget);
      expect(find.text('اعرف مواقيت الصلاة'), findsNothing);

      repository.gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // A cross-fade, not a cut: for a moment both are there.
      expect(find.byType(QiblaCompass), findsOneWidget);
      expect(find.text('اعرف مواقيت الصلاة'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(QiblaCompass), findsNothing);
      expect(find.text('اعرف مواقيت الصلاة'), findsOneWidget);
    });

    testWidgets('the bar says loading while the location asked for is read', (
      tester,
    ) async {
      final location = _SlowLocation();
      await _pump(tester, _FakeCompass(), location: location);
      await tester.tap(find.text('استخدم موقعي'));
      await tester.pump();
      await tester.pump(AppTokens.loaderDelay);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('اعرف مواقيت الصلاة'), findsOneWidget);

      location.gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(QiblaCompass), findsOneWidget);
    });

    testWidgets('on iOS the glass bar turns a spinner, and nothing breaks', (
      tester,
    ) async {
      final repository = _SlowRepository()..place = _cairo;
      await _pump(
        tester,
        _FakeCompass(),
        repository: repository,
        theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
        settle: false,
      );
      await tester.pump(AppTokens.loaderDelay);
      expect(find.byType(GlassProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_compass(tester).qibla, isNull);
      expect(tester.takeException(), isNull);

      repository.gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(GlassProgressIndicator), findsNothing);
      expect(_compass(tester).qibla, closeTo(cairoQibla, 0.001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('English LTR in dark mode, large text on a small phone', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repository = _SlowRepository()..place = _cairo;
      await _pump(
        tester,
        _FakeCompass(),
        repository: repository,
        locale: 'en',
        theme: AppTheme.dark,
        size: const Size(320, 640),
        textScale: 2,
        settle: false,
      );
      await tester.pump(AppTokens.loaderDelay);
      expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
      expect(find.textContaining('Hold the phone flat'), findsOneWidget);
      expect(tester.takeException(), isNull);
      repository.gate.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('south-east'), findsWidgets);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });

  for (final (name, size, scale) in [
    ('compact, large text', const Size(320, 640), 2.0),
    ('medium', const Size(700, 900), 1.0),
    ('expanded', const Size(1100, 800), 1.0),
  ]) {
    testWidgets('fits when $name', (tester) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo, size: size, textScale: scale);
      compass.turn(cairoQibla - 20);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(QiblaCompass), findsOneWidget);
      // With the level too, tilted and then level and facing the Qibla.
      compass.turn(cairoQibla + 1, tilt: _tilted);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      compass.turn(cairoQibla + 1, tilt: _level);
      await tester.pumpAndSettle();
      expect(_compass(tester).aligned, isTrue);
      // The hint is below the fold with large text on a small phone.
      await tester.scrollUntilVisible(
        find.textContaining('الهاتف مستوٍ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('الهاتف مستوٍ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English LTR in dark mode', (tester) async {
    final compass = _FakeCompass();
    await _pump(
      tester,
      compass,
      place: _cairo,
      locale: 'en',
      theme: AppTheme.dark,
    );
    compass.turn(cairoQibla - 30);
    await tester.pumpAndSettle();
    expect(find.textContaining('south-east'), findsWidgets);
    expect(find.textContaining('Turn right'), findsOneWidget);
    expect(tester.takeException(), isNull);

    compass.turn(cairoQibla + 1, tilt: _tilted);
    await tester.pumpAndSettle();
    expect(
      find.text('Hold the phone flat to confirm the direction'),
      findsOneWidget,
    );
    compass.turn(cairoQibla + 1, tilt: _level);
    await tester.pumpAndSettle();
    expect(find.text('You are facing the Qibla'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.textContaining('The phone is level'))
          .style
          ?.color,
      AppTheme.dark.colorScheme.primary,
    );
    expect(tester.takeException(), isNull);
  });

  group('the level', () {
    const flatAdvice = 'أمسك الهاتف أفقيًا وبعيدًا';
    const holdFlat = 'أمسك الهاتف أفقيًا لتأكيد الاتجاه';
    final scheme = AppTheme.light.colorScheme;

    testWidgets('a phone that cannot tell its tilt keeps the plain hint and '
        'the plain hub', (tester) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo);
      compass.turn((cairoQibla + 180) % 360);
      await tester.pumpAndSettle();
      expect(_compass(tester).tilt, isNull);
      expect(find.textContaining(flatAdvice), findsOneWidget);
      expect(find.textContaining('الهاتف مستوٍ'), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      // The hub is the accent dot it always was, on the dial's face.
      expect(await _dialColour(tester, Offset.zero), _paints(scheme.primary));
      expect(
        await _dialColour(tester, const Offset(20, 0)),
        _paints(scheme.surfaceContainerHigh),
      );
    });

    testWidgets('level: the hint confirms it in the accent with a tick, and '
        'the directions go on', (tester) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo);
      compass.turn((cairoQibla + 180) % 360, tilt: _level);
      await tester.pumpAndSettle();
      expect(_compass(tester).tilt, _level);
      expect(find.textContaining(flatAdvice), findsNothing);
      expect(
        tester.widget<Text>(find.textContaining('الهاتف مستوٍ')).style?.color,
        scheme.primary,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('در يمينًا'), findsOneWidget);
      // The bubble rests in the middle, in the accent, in its own well.
      expect(await _dialColour(tester, Offset.zero), _paints(scheme.primary));
      expect(
        await _dialColour(tester, const Offset(24, 0)),
        _paints(scheme.surface),
      );
    });

    for (final locale in ['ar', 'en']) {
      testWidgets('tilted: the bubble goes to the raised side of the phone '
          'whichever way the text runs ($locale)', (tester) async {
        final compass = _FakeCompass();
        await _pump(tester, compass, place: _cairo, locale: locale);
        // The right edge of the phone is the higher one.
        compass.turn((cairoQibla + 180) % 360, tilt: _tilted);
        await tester.pumpAndSettle();
        expect(
          await _dialColour(tester, const Offset(20, 0)),
          _paints(scheme.onSurfaceVariant),
        );
        expect(
          await _dialColour(tester, const Offset(-20, 0)),
          _paints(scheme.surface),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tilted: it asks to hold the phone flat, and the directions '
        'go on', (tester) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo);
      compass.turn(cairoQibla - 40, tilt: _tilted);
      await tester.pumpAndSettle();
      expect(_compass(tester).tilt, _tilted);
      expect(find.textContaining(flatAdvice), findsOneWidget);
      expect(find.textContaining('الهاتف مستوٍ'), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.textContaining('در يمينًا'), findsOneWidget);
      compass.turn(cairoQibla + 40, tilt: _tilted);
      await tester.pumpAndSettle();
      expect(find.textContaining('در يسارًا'), findsOneWidget);
    });

    testWidgets('facing the Qibla is only claimed of a level phone', (
      tester,
    ) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo);
      compass.turn(cairoQibla + 1, tilt: _tilted);
      await tester.pumpAndSettle();
      expect(find.text('أنت تواجه القبلة'), findsNothing);
      expect(find.text(holdFlat), findsOneWidget);
      expect(_compass(tester).aligned, isFalse);

      compass.turn(cairoQibla + 1, tilt: _level);
      await tester.pumpAndSettle();
      expect(find.text('أنت تواجه القبلة'), findsOneWidget);
      expect(find.text(holdFlat), findsNothing);
      expect(_compass(tester).aligned, isTrue);
      expect(haptics.calls, isEmpty);

      // Leaning again takes the claim back.
      compass.turn(cairoQibla + 1, tilt: _tilted);
      await tester.pumpAndSettle();
      expect(find.text('أنت تواجه القبلة'), findsNothing);
      expect(_compass(tester).aligned, isFalse);
    });

    testWidgets('screen readers are told when the phone becomes level, and '
        'when it stops', (tester) async {
      final handle = tester.ensureSemantics();
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo);
      // Before the phone says how it is held, the hint is plain advice.
      expect(
        tester.getSemantics(find.textContaining(flatAdvice)),
        isNot(isSemantics(isLiveRegion: true)),
      );
      compass.turn(cairoQibla - 40, tilt: _tilted);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.textContaining(flatAdvice)),
        isSemantics(isLiveRegion: true),
      );
      compass.turn(cairoQibla - 40, tilt: _level);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.textContaining('الهاتف مستوٍ')),
        isSemantics(isLiveRegion: true),
      );
      // The line under the dial speaks when it asks for a flat phone.
      compass.turn(cairoQibla + 1, tilt: _tilted);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text(holdFlat)),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('with animations off the level shows its state at once', (
      tester,
    ) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo, reduceMotion: true);
      compass.turn((cairoQibla + 180) % 360, tilt: _level);
      await tester.pump();
      await tester.pump();
      expect(await _dialColour(tester, Offset.zero), _paints(scheme.primary));
      expect(
        await _dialColour(tester, const Offset(24, 0)),
        _paints(scheme.surface),
      );
    });

    testWidgets('a device without a compass has no level', (tester) async {
      await _pump(tester, _NoCompass(), place: _cairo);
      expect(_compass(tester).tilt, isNull);
      expect(find.textContaining('لا يوجد في هذا الجهاز حساس'), findsOneWidget);
      expect(find.textContaining('الهاتف مستوٍ'), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });
  });
}
