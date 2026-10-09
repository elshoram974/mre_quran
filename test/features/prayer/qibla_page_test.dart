import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/haptics/haptics.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/prayer/application/compass_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/domain/qibla.dart';
import 'package:mre_quran/features/prayer/presentation/qibla_compass.dart';
import 'package:mre_quran/features/prayer/presentation/qibla_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

final _cairo = PrayerPlace(30.04, 31.24);

/// A compass the test turns by hand.
class _FakeCompass implements CompassSource {
  final StreamController<double> controller = StreamController<double>();

  @override
  Stream<double> headings() => controller.stream;
}

/// A device with no compass sensor.
class _NoCompass implements CompassSource {
  @override
  Stream<double> headings() => Stream<double>.error('no sensor');
}

Future<void> _pump(
  WidgetTester tester,
  CompassSource compass, {
  PrayerPlace? place,
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
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
          FakeLocationSource(requestResult: _cairo),
        ),
        prayerRepositoryProvider.overrideWithValue(
          MemoryPrayerRepository()..place = place,
        ),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const QiblaPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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

    compass.controller.add((cairoQibla - 40) % 360);
    await tester.pumpAndSettle();
    expect(find.textContaining('در يمينًا'), findsOneWidget);
    expect(haptics.calls, isEmpty);

    compass.controller.add((cairoQibla + 40) % 360);
    await tester.pumpAndSettle();
    expect(find.textContaining('در يسارًا'), findsOneWidget);
  });

  testWidgets('says so and ticks once when the phone faces the Qibla', (
    tester,
  ) async {
    final compass = _FakeCompass();
    await _pump(tester, compass, place: _cairo);
    compass.controller.add(cairoQibla + 1);
    await tester.pumpAndSettle();
    expect(find.text('أنت تواجه القبلة'), findsOneWidget);
    expect(haptics.calls, ['step']);

    // Staying on it does not tick again; leaving and returning does.
    compass.controller.add(cairoQibla - 1);
    await tester.pumpAndSettle();
    expect(haptics.calls, ['step']);
    compass.controller.add(cairoQibla + 60);
    await tester.pumpAndSettle();
    expect(find.text('أنت تواجه القبلة'), findsNothing);
    compass.controller.add(cairoQibla);
    await tester.pumpAndSettle();
    expect(haptics.calls, ['step', 'step']);
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

  testWidgets('the dial is announced to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _FakeCompass(), place: _cairo);
    expect(find.bySemanticsLabel(RegExp('بوصلة القبلة')), findsOneWidget);
    handle.dispose();
  });

  for (final (name, size, scale) in [
    ('compact, large text', const Size(320, 640), 2.0),
    ('medium', const Size(700, 900), 1.0),
    ('expanded', const Size(1100, 800), 1.0),
  ]) {
    testWidgets('fits when $name', (tester) async {
      final compass = _FakeCompass();
      await _pump(tester, compass, place: _cairo, size: size, textScale: scale);
      compass.controller.add(cairoQibla - 20);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(QiblaCompass), findsOneWidget);
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
    compass.controller.add(cairoQibla - 30);
    await tester.pumpAndSettle();
    expect(find.textContaining('south-east'), findsWidgets);
    expect(find.textContaining('Turn right'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
