import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/app_shortcuts.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';
import 'package:quick_actions/quick_actions.dart';

/// Records what the app offers, and lets a test tap a shortcut.
class _FakeQuickActions implements QuickActions {
  QuickActionHandler? handler;
  List<ShortcutItem> items = [];

  @override
  Future<void> initialize(QuickActionHandler handler) async =>
      this.handler = handler;

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async =>
      this.items = items;

  @override
  Future<void> clearShortcutItems() async => items = [];
}

void main() {
  Future<(_FakeQuickActions, GoRouter)> pump(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
  }) async {
    final quick = _FakeQuickActions();
    final router = GoRouter(
      initialLocation: AppRoute.settings.path,
      routes: [
        for (final route in [
          AppRoute.reader,
          AppRoute.duas,
          AppRoute.settings,
          AppRoute.prayerTimes,
          AppRoute.qibla,
        ])
          GoRoute(path: route.path, builder: (_, _) => Text(route.name)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickActionsProvider.overrideWithValue(quick),
          routerProvider.overrideWithValue(router),
        ],
        child: MaterialApp.router(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          routerConfig: router,
          builder: (_, child) => AppShortcutsScope(child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (quick, router);
  }

  testWidgets('offers the adhan, the Qibla, the adhkar and the reader, '
      'named in the app language, each with its icon', (tester) async {
    final (quick, _) = await pump(tester);
    expect(quick.items.map((item) => item.type), [
      'prayerTimes',
      'qibla',
      'adhkar',
      'reader',
    ]);
    expect(quick.items.map((item) => item.localizedTitle), [
      'مواقيت الصلاة والأذان',
      'القبلة',
      'الأذكار والأدعية',
      'متابعة القراءة',
    ]);
    expect(
      quick.items.every((item) => item.icon!.startsWith('ic_shortcut_')),
      isTrue,
    );
  });

  testWidgets('names them in English when the app is in English', (
    tester,
  ) async {
    final (quick, _) = await pump(tester, locale: const Locale('en'));
    expect(quick.items.first.localizedTitle, 'Prayer times and adhan');
  });

  testWidgets('a tapped shortcut opens its screen', (tester) async {
    final (quick, _) = await pump(tester);
    for (final (type, screen) in [
      ('qibla', AppRoute.qibla.name),
      ('prayerTimes', AppRoute.prayerTimes.name),
      ('adhkar', AppRoute.duas.name),
      ('reader', AppRoute.reader.name),
    ]) {
      quick.handler!(type);
      await tester.pumpAndSettle();
      expect(find.text(screen), findsOneWidget, reason: type);
    }
    // Something that is not one of ours does nothing.
    quick.handler!('other');
    await tester.pumpAndSettle();
    expect(find.text(AppRoute.reader.name), findsOneWidget);
  });

  test('every shortcut has its icon on both platforms', () {
    for (final shortcut in AppShortcut.values) {
      for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(
          File(
            'android/app/src/main/res/drawable-$density/${shortcut.icon}.png',
          ).existsSync(),
          isTrue,
          reason: '${shortcut.icon} $density',
        );
      }
      expect(
        File(
          'ios/Runner/Assets.xcassets/${shortcut.icon}.imageset/Contents.json',
        ).existsSync(),
        isTrue,
        reason: shortcut.icon,
      );
    }
  });
}
