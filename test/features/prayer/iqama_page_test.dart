import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/presentation/iqama_page.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_page.dart';

import '../../helpers/prayer_pages.dart';

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
  for (final MapEntry(:key, :value) in h.scheduler.once.entries)
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
      harness.scheduler.once.values
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
}
