import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/hints/hints.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/adhan/application/adhan_suggestion.dart';
import 'package:mre_quran/features/adhan/domain/adhan_settings.dart';
import 'package:mre_quran/features/adhan/presentation/adhan_suggestion_scope.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

class _Hints implements HintsRepository {
  @override
  Future<Set<AppHint>> dismissed() async => {};
  @override
  Future<void> dismiss(AppHint hint) async {}
}

class _Store implements AdhanSuggestionStore {
  DateTime? last;
  @override
  Future<DateTime?> lastShown() async => last;
  @override
  Future<void> markShown(DateTime when) async => last = when;
}

class _Prayer extends PrayerNotifier {
  @override
  Future<PrayerState> build() async =>
      const PrayerState(settings: PrayerSettings());
}

class _Adhan extends AdhanSettingsNotifier {
  @override
  Future<AdhanSettings> build() async => const AdhanSettings();
}

void main() {
  final now = DateTime(2026, 11, 18);
  test(
    'offers setup if alerts or adhan are off and the quiet period has elapsed',
    () {
      expect(
        shouldSuggestAdhan(
          alertsEnabled: false,
          adhanEnabled: true,
          now: now,
          lastShown: null,
        ),
        isTrue,
      );
      expect(
        shouldSuggestAdhan(
          alertsEnabled: true,
          adhanEnabled: false,
          now: now,
          lastShown: now.subtract(const Duration(days: 8)),
        ),
        isTrue,
      );
      expect(
        shouldSuggestAdhan(
          alertsEnabled: false,
          adhanEnabled: true,
          now: now,
          lastShown: now.subtract(const Duration(days: 6)),
        ),
        isFalse,
      );
      expect(
        shouldSuggestAdhan(
          alertsEnabled: true,
          adhanEnabled: true,
          now: now,
          lastShown: null,
        ),
        isFalse,
      );
    },
  );

  for (final (locale, title, action) in [
    ('ar', 'فعّل تنبيهات الصلاة والأذان', 'إعداد مواقيت الصلاة'),
    ('en', 'Set up prayer alerts and adhan', 'Set up prayer times'),
  ]) {
    testWidgets(
      'offers setup after startup in $locale and opens prayer settings',
      (tester) async {
        final store = _Store();
        final router = GoRouter(
          initialLocation: AppRoute.reader.path,
          routes: [
            GoRoute(
              path: AppRoute.reader.path,
              builder: (_, _) => const Scaffold(body: Text('Reader')),
            ),
            GoRoute(
              path: AppRoute.prayerTimes.path,
              builder: (_, _) => const Scaffold(body: Text('Prayer settings')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              routerProvider.overrideWithValue(router),
              startupReadyProvider.overrideWithValue(true),
              hintsRepositoryProvider.overrideWithValue(_Hints()),
              adhanSuggestionStoreProvider.overrideWithValue(store),
              prayerProvider.overrideWith(_Prayer.new),
              adhanSettingsProvider.overrideWith(_Adhan.new),
              clockProvider.overrideWithValue(() => now),
            ],
            child: MaterialApp.router(
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: appLocalizationsDelegates,
              routerConfig: router,
              builder: (_, child) => AdhanSuggestionScope(child: child!),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(store.last, now);
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(find.text('Prayer settings'), findsOneWidget);
      },
    );
  }
}
