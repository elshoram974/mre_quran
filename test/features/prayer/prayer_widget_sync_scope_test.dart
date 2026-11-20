import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_widget_sync_scope.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/memory_settings_repository.dart';

/// Prayer state that never finishes loading.
class _Loading extends PrayerNotifier {
  @override
  Future<PrayerState> build() => Completer<PrayerState>().future;
}

/// Prayer state that loaded with no place chosen.
class _NoPlace extends PrayerNotifier {
  @override
  Future<PrayerState> build() async =>
      const PrayerState(settings: PrayerSettings());
}

class _WithPlace extends PrayerNotifier {
  @override
  Future<PrayerState> build() async => PrayerState(
    settings: const PrayerSettings(),
    place: PrayerPlace(30.04, 31.24),
  );
}

void main() {
  /// Pumps the scope over [prayer] and returns what it sent to the widgets:
  /// one entry per update, null for "clear".
  Future<List<Object?>> sent(
    WidgetTester tester,
    PrayerNotifier Function() prayer, {
    AppSettings settings = const AppSettings(),
  }) async {
    final updates = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('net.mrecode.mre_quran/prayer_widget'),
      (call) async {
        updates.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('net.mrecode.mre_quran/prayer_widget'),
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository()..settings = settings,
          ),
          prayerProvider.overrideWith(prayer),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: PrayerWidgetSyncScope(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return updates;
  }

  testWidgets('while the app is still loading, the widgets keep their times', (
    tester,
  ) async {
    expect(await sent(tester, _Loading.new), isEmpty);
  });

  testWidgets('once loaded with no place, the widgets are cleared', (
    tester,
  ) async {
    expect(await sent(tester, _NoPlace.new), contains(null));
  });

  testWidgets('sends sunrise and both calendar dates for every widget day', (
    tester,
  ) async {
    final updates = await sent(tester, _WithPlace.new);
    final payload = updates.whereType<Map<Object?, Object?>>().last;
    final days = payload['days'] as List<Object?>;
    expect(days, hasLength(7));
    final today = days.first as Map<Object?, Object?>;
    final rows = today['rows'] as List<Object?>;
    expect(rows.map((row) => (row as Map<Object?, Object?>)['id']), [
      'fajr',
      'sunrise',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    ]);
    expect((today['dateLabel'] as String), isNotEmpty);
    expect((today['hijriLabel'] as String), isNotEmpty);
  });

  testWidgets('the widgets speak the app\'s language unless told another', (
    tester,
  ) async {
    final same = await sent(tester, _WithPlace.new);
    final arabic = same.whereType<Map<Object?, Object?>>().last;
    expect(arabic['rtl'], isTrue);
    expect(
      (arabic['labels'] as Map<Object?, Object?>)['next'],
      'الصلاة القادمة',
    );
  });

  testWidgets('a language chosen for the widgets is used for all of their '
      'words, dates, clock and direction', (tester) async {
    final updates = await sent(
      tester,
      _WithPlace.new,
      settings: const AppSettings(localeCode: 'ar', widgetLocaleCode: 'en'),
    );
    final payload = updates.whereType<Map<Object?, Object?>>().last;
    expect(payload['rtl'], isFalse);
    expect((payload['labels'] as Map<Object?, Object?>)['next'], 'Next prayer');
    final times = payload['times'] as List<Object?>;
    final names = [
      for (final time in times) (time as Map<Object?, Object?>)['name'],
    ];
    expect(names, containsAll(['Fajr', 'Dhuhr', 'Asr']));
    // The clock is English: AM or PM, not the Arabic ص and م.
    final first = (times.first as Map<Object?, Object?>)['time'] as String;
    expect(first, matches(RegExp(r'[AP]M$')));
    final day =
        (payload['days'] as List<Object?>).first as Map<Object?, Object?>;
    expect(day['dateLabel'] as String, matches(RegExp(r'[A-Za-z]')));
  });

  testWidgets('waits for Material localizations before syncing prayer times', (
    tester,
  ) async {
    final updates = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('net.mrecode.mre_quran/prayer_widget'),
      (call) async {
        updates.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('net.mrecode.mre_quran/prayer_widget'),
        null,
      ),
    );
    Widget app(List<LocalizationsDelegate<dynamic>> delegates) => ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue((
          settings: const AppSettings(),
        )),
        prayerProvider.overrideWith(_WithPlace.new),
      ],
      child: WidgetsApp(
        color: const Color(0xFFFFFFFF),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: delegates,
        builder: (_, _) => const PrayerWidgetSyncScope(child: SizedBox()),
      ),
    );
    await tester.pumpWidget(app(const [AppLocalizations.delegate]));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(updates, isEmpty);
    await tester.pumpWidget(app(appLocalizationsDelegates));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(updates.whereType<Map<Object?, Object?>>(), isNotEmpty);
  });
}
