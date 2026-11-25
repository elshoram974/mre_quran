import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_hero_card.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/presentation/iqama_page.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_card.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_page.dart';

import '../../helpers/prayer_pages.dart';
import '../../helpers/prayer_soon_fixtures.dart';

Future<PrayerPageHarness> _pump(
  WidgetTester tester, {
  PrayerSettings settings = const PrayerSettings(),
  bool allowNotifications = true,
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  Widget? home,
}) => pumpPrayerPage(
  tester,
  home: home ?? const IqamaPage(),
  settings: settings,
  allowNotifications: allowNotifications,
  locale: locale,
  size: size,
  textScale: textScale,
  theme: theme,
);

Iterable<int> _iqamas(PrayerPageHarness h) => [
  for (final MapEntry(:key, :value) in handedOver(h.scheduler, h.soon).entries)
    if (value.channel == ReminderChannel.iqama) key,
];

void main() {
  testWidgets('says what the iqama notice is, and starts with a switch off', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.textContaining('قد قامت الصلاة، قد قامت الصلاة'), findsWidgets);
    expect(find.text('تنبيه الإقامة'), findsOneWidget);
    // Nothing to set until it is on.
    expect(find.text('كم بعد الأذان؟'), findsNothing);
    expect(find.byTooltip('زيادة دقيقة'), findsNothing);
  });

  testWidgets('turning it on shows each prayer\'s iqama and schedules it', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await tester.tap(find.text('تنبيه الإقامة'));
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaReminder, isTrue);
    expect(_iqamas(harness), isNotEmpty);
    expect(find.text('كم بعد الأذان؟'), findsOneWidget);
    expect(find.byTooltip('زيادة دقيقة'), findsNWidgets(5));
    // Fajr, then Dhuhr: the usual gaps, in words and as a time.
    expect(find.text('بعد الأذان بـ ٢٠ دقيقة'), findsOneWidget);
    expect(find.text('بعد الأذان بـ ١٥ دقيقة'), findsNWidgets(3));
    expect(find.text('بعد الأذان بـ ١٠ دقائق'), findsOneWidget);
    expect(find.textContaining('الإقامة '), findsWidgets);
  });

  testWidgets('a step changes that prayer\'s gap, and all go back to the '
      'usual', (tester) async {
    final harness = await _pump(
      tester,
      settings: const PrayerSettings(iqamaReminder: true),
    );
    await tester.tap(find.byTooltip('زيادة دقيقة').first);
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaMinutes, {DailyPrayer.fajr: 21});
    expect(find.text('بعد الأذان بـ ٢١ دقيقة'), findsOneWidget);
    final lessAtMaghrib = find.byTooltip('تقليل دقيقة').at(3);
    await tester.ensureVisible(lessAtMaghrib);
    await tester.pumpAndSettle();
    await tester.tap(lessAtMaghrib);
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaAfter(DailyPrayer.maghrib), 9);

    await tester.ensureVisible(find.text('إعادة المعتاد لكل الصلوات'));
    await tester.tap(find.text('إعادة المعتاد لكل الصلوات'));
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaMinutes, isEmpty);
    expect(find.text('إعادة المعتاد لكل الصلوات'), findsNothing);
  });

  testWidgets('each prayer\'s iqama turns off by itself, and its notices go', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      settings: const PrayerSettings(iqamaReminder: true),
    );
    final fajr = handedOver(
      harness.scheduler,
      harness.soon,
    ).values.where((value) => value.channel == ReminderChannel.iqama).length;
    // The Fajr row's switch is the first after the main ones.
    await tester.tap(find.text('الفجر'));
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaOff, {DailyPrayer.fajr});
    expect(harness.repository.settings.iqamaFor(DailyPrayer.fajr), isFalse);
    expect(find.text('متوقفة لهذه الصلاة'), findsOneWidget);
    // Its stepper goes; the four others keep theirs.
    expect(find.byTooltip('زيادة دقيقة'), findsNWidgets(4));
    final left = handedOver(
      harness.scheduler,
      harness.soon,
    ).values.where((value) => value.channel == ReminderChannel.iqama).length;
    expect(left, lessThan(fajr));
    await tester.tap(find.text('الفجر'));
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaOff, isEmpty);
  });

  testWidgets('the gap stops at five minutes and an hour', (tester) async {
    await _pump(
      tester,
      settings: const PrayerSettings(
        iqamaReminder: true,
        iqamaMinutes: {DailyPrayer.fajr: 5, DailyPrayer.isha: 60},
      ),
    );
    IconButton button(Finder tooltip) => tester.widget<IconButton>(
      find.ancestor(of: tooltip, matching: find.byType(IconButton)).first,
    );
    expect(button(find.byTooltip('تقليل دقيقة').first).onPressed, isNull);
    expect(button(find.byTooltip('زيادة دقيقة').last).onPressed, isNull);
    expect(button(find.byTooltip('زيادة دقيقة').first).onPressed, isNotNull);
  });

  testWidgets('the sound can be turned off, which silences the notices', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      settings: const PrayerSettings(iqamaReminder: true),
    );
    await tester.tap(find.text('صوت التنبيه'));
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaSound, isFalse);
    expect(
      handedOver(harness.scheduler, harness.soon).values
          .where((value) => value.channel == ReminderChannel.iqama)
          .every((value) => value.silent),
      isTrue,
    );
  });

  testWidgets('without the notification permission it stays off, and says '
      'so in red', (tester) async {
    final harness = await _pump(tester, allowNotifications: false);
    await tester.tap(find.text('تنبيه الإقامة'));
    await tester.pumpAndSettle();
    expect(harness.repository.settings.iqamaReminder, isFalse);
    expect(find.textContaining('الإشعارات متوقفة'), findsOneWidget);
  });

  testWidgets('the prayer times page leads here', (tester) async {
    await _pump(tester, home: const Scaffold(body: PrayerTimesPage()));
    await revealOnPage(tester, find.text('الإقامة'));
    await tester.tap(find.text('الإقامة'));
    await tester.pumpAndSettle();
    expect(find.text('تنبيه الإقامة'), findsOneWidget);
  });

  testWidgets('the reminder before a prayer has a sound switch there', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      settings: const PrayerSettings(alerts: {DailyPrayer.fajr}),
      home: const Scaffold(body: PrayerTimesPage()),
    );
    await revealOnPage(tester, find.text('صوت التذكير'));
    await tester.tap(find.text('صوت التذكير'));
    await tester.pumpAndSettle();
    expect(harness.repository.settings.beforeSound, isFalse);
  });

  group('layout', () {
    for (final (name, size) in [
      ('compact', const Size(320, 640)),
      ('medium', const Size(700, 900)),
      ('expanded', const Size(1100, 800)),
    ]) {
      testWidgets('Arabic fits when $name', (tester) async {
        await _pump(
          tester,
          size: size,
          settings: const PrayerSettings(iqamaReminder: true),
        );
        await revealOnPage(tester, find.text('كم بعد الأذان؟'));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('English LTR in dark mode at text scale 2', (tester) async {
      await _pump(
        tester,
        locale: 'en',
        theme: AppTheme.dark,
        size: const Size(320, 640),
        textScale: 2,
        settings: const PrayerSettings(iqamaReminder: true),
      );
      await revealOnPage(tester, find.text('Iqama notice'));
      await revealOnPage(tester, find.text('How long after the adhan?'));
      expect(tester.takeException(), isNull);
    });
  });

  group('the countdown to the iqama in the app', () {
    final place = PrayerPlace(30.04, 31.24);
    // Dhuhr of Thursday 8 October 2026, and of Friday the 9th.
    final thursday = PrayerDay.compute(
      place,
      PrayerMethod.egyptian,
      DateTime(2026, 10, 8),
    );
    final friday = PrayerDay.compute(
      place,
      PrayerMethod.egyptian,
      DateTime(2026, 10, 9),
    );

    Future<PrayerPageHarness> prayerPage(
      WidgetTester tester,
      DateTime now, {
      bool iqama = true,
      Widget home = const Scaffold(body: PrayerTimesPage()),
    }) => pumpPrayerPage(
      tester,
      home: home,
      now: now,
      place: place,
      settings: PrayerSettings(iqamaReminder: iqama),
    );

    testWidgets('is not shown before the adhan, nor with the notice off', (
      tester,
    ) async {
      await prayerPage(
        tester,
        thursday.dhuhr.subtract(const Duration(minutes: 1)),
      );
      // Only the next prayer's card.
      expect(find.byType(AppHeroCard), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await prayerPage(
        tester,
        thursday.dhuhr.add(const Duration(minutes: 3)),
        iqama: false,
      );
      expect(find.byType(AppHeroCard), findsOneWidget);
    });

    testWidgets('from the adhan, it counts down to the iqama, and says when '
        'it comes', (tester) async {
      await prayerPage(tester, thursday.dhuhr.add(const Duration(minutes: 3)));
      // Fifteen minutes after the adhan, three gone: twelve left.
      expect(find.text('بعد ١٢:٠٠'), findsOneWidget);
      // Its card comes with the next prayer's, and says when the iqama is.
      expect(find.byType(AppHeroCard), findsNWidgets(2));
      expect(find.textContaining('الإقامة '), findsOneWidget);
      expect(find.text('الظهر'), findsWidgets);
    });

    testWidgets('names the Friday prayer as it is', (tester) async {
      await prayerPage(tester, friday.dhuhr.add(const Duration(minutes: 2)));
      // Fifteen minutes after the adhan, two gone.
      expect(find.text('بعد ١٣:٠٠'), findsOneWidget);
      expect(find.text('الجمعة'), findsWidgets);
    });

    testWidgets('the shortcut on the adhkar tab says it too, in minutes', (
      tester,
    ) async {
      await prayerPage(
        tester,
        thursday.dhuhr.add(const Duration(minutes: 3)),
        home: const Scaffold(body: PrayerTimesCard()),
      );
      expect(find.textContaining('الظهر · الإقامة بعد'), findsOneWidget);
    });
  });
}
