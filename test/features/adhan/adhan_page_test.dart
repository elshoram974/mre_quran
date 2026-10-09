import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/adhan/data/adhan_platform.dart';
import 'package:mre_quran/features/adhan/data/voice_store.dart';
import 'package:mre_quran/features/adhan/presentation/adhan_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhan_fixtures.dart';
import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

class _Harness {
  _Harness(this.platform, this.adhan, this.store, this.scheduler);

  final FakeAdhanPlatform platform;
  final MemoryAdhanRepository adhan;
  final FakeVoiceStore store;
  final FakeReminderScheduler scheduler;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool supported = true,
  bool exact = true,
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  Set<String> saved = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = _Harness(
    FakeAdhanPlatform(supported: supported),
    MemoryAdhanRepository(),
    FakeVoiceStore(saved: saved),
    FakeReminderScheduler()..exactAllowed = exact,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adhanPlatformProvider.overrideWithValue(harness.platform),
        adhanRepositoryProvider.overrideWithValue(harness.adhan),
        adhanCatalogSourceProvider.overrideWithValue(FakeAdhanCatalog()),
        voiceStoreProvider.overrideWithValue(harness.store),
        reminderSchedulerProvider.overrideWithValue(harness.scheduler),
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
        home: const AdhanPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

/// Scrolls until [finder] is on screen, as a person would.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// The card of the voice titled [title].
Finder _card(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Card));

Finder _inCard(String title, Finder inner) =>
    find.descendant(of: _card(title), matching: inner);

void main() {
  testWidgets(
    'shows the alert choices and the voices, the bundled one in use',
    (tester) async {
      await _pump(tester);
      expect(find.text('تشغيل الأذان وقت الصلاة'), findsOneWidget);
      expect(find.text('إيقاف الأذان عند قلب الهاتف'), findsOneWidget);
      expect(find.text('الأذان الافتراضي'), findsOneWidget);
      expect(find.text('قيد الاستخدام'), findsOneWidget);
      await _reveal(tester, find.text('أذان المسجد الحرام'));
      expect(find.textContaining('تنزيل'), findsWidgets);
    },
  );

  testWidgets('the switches are saved, and flipping needs the adhan on', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.text('إيقاف الأذان عند قلب الهاتف'));
    await tester.pumpAndSettle();
    expect(h.adhan.settings.stopWhenFlipped, isFalse);

    await tester.tap(find.text('تشغيل الأذان وقت الصلاة'));
    await tester.pumpAndSettle();
    expect(h.adhan.settings.playAdhan, isFalse);
    final flip = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'إيقاف الأذان عند قلب الهاتف'),
    );
    expect(flip.onChanged, isNull);
  });

  testWidgets(
    'a voice can be heard before it is downloaded, then from the phone',
    (tester) async {
      final h = await _pump(tester);
      // The bundled voice.
      await tester.tap(_inCard('الأذان الافتراضي', find.text('استماع')));
      await tester.pumpAndSettle();
      expect(h.platform.previews.last, isA<BundledPreview>());
      expect(find.text('إيقاف الاستماع'), findsOneWidget);

      // Listening to another replaces it; this one streams.
      await _reveal(tester, find.text('أذان المسجد النبوي'));
      await tester.tap(_inCard('أذان المسجد النبوي', find.text('استماع')));
      await tester.pumpAndSettle();
      final stream = h.platform.previews.last as StreamPreview;
      expect(stream.url, kMadinahVoice.url);
      expect(stream.userAgent, HttpVoiceFetcher.userAgent);

      // Stopping, and the end of the recording, put the label back.
      await tester.tap(find.text('إيقاف الاستماع'));
      await tester.pumpAndSettle();
      expect(h.platform.stops, greaterThan(0));
      expect(find.text('إيقاف الاستماع'), findsNothing);
      await tester.tap(_inCard('أذان المسجد النبوي', find.text('استماع')));
      await tester.pumpAndSettle();
      h.platform.ended.add(null);
      await tester.pumpAndSettle();
      expect(find.text('إيقاف الاستماع'), findsNothing);
    },
  );

  testWidgets('a saved voice is played from its file', (tester) async {
    final h = await _pump(tester, saved: {'madinah'});
    await _reveal(tester, find.text('أذان المسجد النبوي'));
    await tester.tap(_inCard('أذان المسجد النبوي', find.text('استماع')));
    await tester.pumpAndSettle();
    expect(h.platform.previews.last, isA<FilePreview>());
  });

  testWidgets('download, use, and delete take the voice through its life', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _reveal(tester, find.text('أذان المسجد النبوي'));
    await tester.tap(
      _inCard('أذان المسجد النبوي', find.textContaining('تنزيل (')),
    );
    await tester.pumpAndSettle();
    expect(h.store.saved, {'madinah'});

    await tester.tap(
      _inCard('أذان المسجد النبوي', find.text('استخدام هذا الصوت')),
    );
    await tester.pumpAndSettle();
    expect(h.adhan.settings.voiceId, 'madinah');
    expect(
      _inCard('أذان المسجد النبوي', find.text('قيد الاستخدام')),
      findsOneWidget,
    );

    await tester.tap(_inCard('أذان المسجد النبوي', find.text('حذف التنزيل')));
    await tester.pumpAndSettle();
    expect(h.store.saved, isEmpty);
    expect(
      h.adhan.settings.voiceId,
      'default',
      reason: 'back to the bundled voice',
    );
  });

  testWidgets('says why a download failed', (tester) async {
    final h = await _pump(tester);
    h.store.failWith = VoiceDownloadFailure.network;
    await _reveal(tester, find.text('أذان المسجد النبوي'));
    await tester.tap(
      _inCard('أذان المسجد النبوي', find.textContaining('تنزيل (')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر التنزيل'), findsOneWidget);

    h.store.failWith = VoiceDownloadFailure.integrity;
    await tester.tap(
      _inCard('أذان المسجد النبوي', find.textContaining('تنزيل (')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('ليس هو المتوقع'), findsOneWidget);
    expect(h.store.saved, isEmpty);
  });

  testWidgets('a download in progress can be cancelled', (tester) async {
    final h = await _pump(tester);
    h.store.gate = Completer<void>();
    await _reveal(tester, find.text('أذان المسجد النبوي'));
    await tester.tap(
      _inCard('أذان المسجد النبوي', find.textContaining('تنزيل (')),
    );
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(_inCard('أذان المسجد النبوي', find.text('إلغاء')));
    h.store.gate!.complete();
    await tester.pumpAndSettle();
    expect(h.store.saved, isEmpty);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('تعذّر التنزيل'), findsNothing);
  });

  testWidgets('the source and licence of a voice open in a sheet', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(
      _inCard('الأذان الافتراضي', find.byTooltip('المصدر والترخيص')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('CC0 1.0'), findsOneWidget);
    expect(find.textContaining('Someone'), findsOneWidget);
    expect(find.textContaining('https://example.test/default'), findsOneWidget);
  });

  testWidgets('"try the alert" starts it now with the chosen settings', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.text('جرّب التنبيه الآن'));
    await tester.pumpAndSettle();
    expect(h.platform.tests, hasLength(1));
    expect(h.platform.tests.single.title, 'تجربة: حان وقت الصلاة');
    expect(h.platform.config!.stopLabel, 'إيقاف الأذان');
  });

  testWidgets('without exact alarms it says so and offers to allow them', (
    tester,
  ) async {
    final h = await _pump(tester, exact: false);
    expect(find.textContaining('يؤخّر أندرويد'), findsOneWidget);
    await tester.tap(find.text('السماح بالتوقيت الدقيق'));
    await tester.pumpAndSettle();
    expect(h.scheduler.exactRequests, 1);
  });

  testWidgets(
    'a phone that cannot play the adhan says so and shows no voices',
    (tester) async {
      await _pump(tester, supported: false);
      expect(find.textContaining('متاح على أندرويد'), findsOneWidget);
      expect(find.text('الأذان الافتراضي'), findsNothing);
    },
  );

  for (final (name, size, scale) in [
    ('compact, large text', const Size(320, 640), 2.0),
    ('medium', const Size(700, 900), 1.0),
    ('expanded', const Size(1100, 800), 1.0),
  ]) {
    testWidgets('fits when $name', (tester) async {
      await _pump(tester, size: size, textScale: scale);
      await _reveal(tester, find.text('أذان المسجد الحرام'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English LTR in dark mode', (tester) async {
    await _pump(tester, locale: 'en', theme: AppTheme.dark);
    expect(find.text('Play the adhan at prayer time'), findsOneWidget);
    expect(find.text('Default adhan'), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    await _reveal(tester, find.text('Grand Mosque'));
    expect(find.textContaining('Download'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
