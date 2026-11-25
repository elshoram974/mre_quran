import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/reminder_opener.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/features/reminders/presentation/reminders_page.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('an empty dhikr-widget tap opens the duas tab', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.reader.path,
      routes: [
        GoRoute(
          path: AppRoute.reader.path,
          builder: (_, _) => const Scaffold(body: Text('Reader')),
        ),
        GoRoute(
          path: AppRoute.duas.path,
          builder: (_, _) => const Scaffold(body: Text('Duas')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await openReminder(router, ReminderPayload.adhkarHome);
    await tester.pumpAndSettle();
    expect(find.text('Duas'), findsOneWidget);
  });

  testWidgets('a sheet left open goes before what the tap opens; a foreign '
      'payload leaves it', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.reader.path,
      routes: [
        GoRoute(
          path: AppRoute.reader.path,
          builder: (_, _) => const Scaffold(body: Text('Reader')),
        ),
        GoRoute(
          path: AppRoute.duas.path,
          builder: (_, _) => const Scaffold(body: Text('Duas')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final context = router.routerDelegate.navigatorKey.currentContext!;
    for (final name in ['First sheet', 'Second sheet']) {
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => Text(name),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Second sheet'), findsOneWidget);

    await openReminder(router, 'not:ours');
    await tester.pumpAndSettle();
    expect(find.text('Second sheet'), findsOneWidget);

    await openReminder(router, ReminderPayload.adhkarHome);
    await tester.pumpAndSettle();
    expect(find.text('First sheet'), findsNothing);
    expect(find.text('Second sheet'), findsNothing);
    expect(find.text('Duas'), findsOneWidget);
  });

  testWidgets('a prayer-widget tap opens the Adhan settings', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.reader.path,
      routes: [
        GoRoute(
          path: AppRoute.reader.path,
          builder: (_, _) => const Scaffold(body: Text('Reader')),
        ),
        GoRoute(
          path: AppRoute.adhan.path,
          builder: (_, _) => const Scaffold(body: Text('Adhan settings')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    unawaited(openReminder(router, ReminderPayload.adhanSettings));
    await tester.pumpAndSettle();

    expect(find.text('Adhan settings'), findsOneWidget);
  });

  group('a notification\'s settings button', () {
    GoRouter router() => GoRouter(
      initialLocation: AppRoute.reader.path,
      routes: [
        for (final (route, name) in [
          (AppRoute.reader, 'Reader'),
          (AppRoute.settings, 'Settings tab'),
          (AppRoute.prayerTimes, 'Prayer times'),
        ])
          GoRoute(
            path: route.path,
            builder: (_, _) => Scaffold(body: Text(name)),
          ),
        GoRoute(
          path: AppRoute.reminders.path,
          builder: (_, _) => const RemindersPage(),
        ),
      ],
    );

    testWidgets(
      'of a reminder opens the reminders page over the Settings tab',
      (tester) async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final routes = router();
        addTearDown(routes.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: routes,
              locale: const Locale('ar'),
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        unawaited(openReminder(routes, ReminderPayload.remindersSettings));
        await tester.pumpAndSettle();
        // The Settings tab stays under the page.
        expect(find.text('Settings tab', skipOffstage: false), findsOneWidget);
        // The reminders page: its title, and the reminders made by the person.
        expect(find.text('التذكيرات'), findsOneWidget);
        expect(find.text('تذكيراتي'), findsOneWidget);
      },
    );

    testWidgets('of a prayer alert opens the prayer times', (tester) async {
      final routes = router();
      addTearDown(routes.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
      await openReminder(routes, ReminderPayload.prayerSettings);
      await tester.pumpAndSettle();
      expect(find.text('Prayer times'), findsOneWidget);
    });

    test('the reminder before each prayer, and the iqama, have a voice of '
        'their own; no other channel does', () {
      final soon = ReminderChannel.values
          .where((channel) => channel.isPrayerSoon)
          .toList();
      // Fajr, Dhuhr, the Friday prayer, Asr, Maghrib and Isha.
      expect(soon, hasLength(6));
      expect(soon.map((channel) => channel.id).toSet(), hasLength(6));
      expect(soon.map((channel) => channel.sound).toSet(), hasLength(6));
      for (final channel in soon) {
        expect(channel.sound, startsWith('prayer_near_'));
        // A channel keeps the sound it was made with: the old id is not reused.
        expect(channel.id, isNot(ReminderChannel.legacyPrayerSoonId));
      }
      expect(ReminderChannel.iqama.sound, 'iqama_phrase');
      for (final channel in ReminderChannel.values) {
        if (!channel.isPrayerSoon && channel != ReminderChannel.iqama) {
          expect(channel.sound, isNull, reason: channel.name);
        }
      }
    });

    test('leads where each kind of notification is set', () {
      expect(ReminderChannel.prayer.settings, ReminderPayload.prayerSettings);
      expect(
        ReminderChannel.prayerSoonFajr.settings,
        ReminderPayload.prayerSettings,
      );
      expect(
        ReminderChannel.adhkar.settings,
        ReminderPayload.remindersSettings,
      );
      expect(
        ReminderChannel.fasting.settings,
        ReminderPayload.remindersSettings,
      );
      for (final channel in ReminderChannel.values) {
        expect(ReminderPayload.isSettings(channel.settings), isTrue);
      }
      expect(ReminderPayload.isSettings(ReminderPayload.prayerTimes), isFalse);
    });
  });
}
