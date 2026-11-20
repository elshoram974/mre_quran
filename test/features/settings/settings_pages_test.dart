import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/links/link_opener.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/features/settings/presentation/alerts_settings_page.dart';
import 'package:mre_quran/features/settings/presentation/appearance_settings_page.dart';
import 'package:mre_quran/features/settings/presentation/offline_settings_page.dart';
import 'package:mre_quran/features/settings/presentation/privacy_settings_page.dart';
import 'package:mre_quran/features/settings/presentation/reading_settings_page.dart';
import 'package:mre_quran/features/settings/presentation/settings_page.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/memory_settings_repository.dart';

Future<MemorySettingsRepository> _pump(
  WidgetTester tester,
  Widget page, {
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  Uri? policy,
  List<String>? visited,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = MemorySettingsRepository()
    ..settings = AppSettings(localeCode: locale);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: page),
      ),
      // Whatever a tile opens is only noted here.
      GoRoute(
        path: '/:a',
        builder: (_, state) {
          visited?.add(state.uri.path);
          return const Scaffold(body: Text('opened'));
        },
      ),
      GoRoute(
        path: '/:a/:b',
        builder: (_, state) {
          visited?.add(state.uri.path);
          return const Scaffold(body: Text('opened'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        privacyPolicyProvider.overrideWithValue(policy),
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
  return repository;
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the list of settings', () {
    for (final (locale, tiles) in [
      (
        'ar',
        [
          'المظهر',
          'القراءة',
          'المصحف دون اتصال',
          'التنبيهات والاهتزاز',
          'أدوات الشاشة الرئيسية',
          'الخصوصية',
        ],
      ),
      (
        'en',
        [
          'Appearance',
          'Reading',
          'Offline Mushaf',
          'Alerts and feedback',
          'Home-screen widgets',
          'Privacy',
        ],
      ),
    ]) {
      testWidgets('names what can be set, and each opens a page of its own in '
          '$locale', (tester) async {
        final visited = <String>[];
        await _pump(
          tester,
          const SettingsPage(),
          locale: locale,
          visited: visited,
        );
        // Nothing is set on this page: it only leads to the pages that do.
        expect(find.byType(Switch), findsNothing);
        final paths = [
          AppRoute.settingsAppearance.path,
          AppRoute.settingsReading.path,
          AppRoute.settingsOffline.path,
          AppRoute.settingsAlerts.path,
          AppRoute.widgets.path,
          AppRoute.settingsPrivacy.path,
        ];
        for (final (index, title) in tiles.indexed) {
          await _reveal(tester, find.text(title));
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
          expect(visited.last, paths[index]);
          router(tester).pop();
          await tester.pumpAndSettle();
        }
      });
    }

    testWidgets('the contact and about tiles stay at the end', (tester) async {
      await _pump(tester, const SettingsPage());
      await _reveal(tester, find.text('تواصل معنا'));
      expect(find.text('واتساب'), findsOneWidget);
      await _reveal(tester, find.textContaining('الإصدار'));
    });

    for (final (name, size, scale) in [
      ('compact, large text', const Size(320, 640), 2.0),
      ('medium', const Size(700, 900), 1.0),
      ('expanded', const Size(1100, 800), 1.0),
    ]) {
      testWidgets('fits when $name', (tester) async {
        await _pump(
          tester,
          const SettingsPage(),
          size: size,
          textScale: scale,
          theme: AppTheme.dark,
        );
        await _reveal(tester, find.textContaining('الإصدار'));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the appearance page', () {
    testWidgets('changes the language and the digits', (tester) async {
      final repository = await _pump(tester, const AppearanceSettingsPage());
      await tester.tap(find.text('الأرقام العربية'));
      await tester.pumpAndSettle();
      expect(repository.settings.useArabicDigits, isFalse);
      await tester.tap(find.text('اللغة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(repository.settings.localeCode, 'en');
    });

    testWidgets('has what looks and moves, and nothing else', (tester) async {
      await _pump(tester, const AppearanceSettingsPage());
      expect(find.text('تقليل الحركة'), findsOneWidget);
      expect(find.text('الاهتزاز'), findsNothing);
      expect(find.text('عند فتح التطبيق'), findsNothing);
    });
  });

  group('the reading page', () {
    testWidgets('opens on the Mushaf, and the person can choose the last '
        'tab', (tester) async {
      final repository = await _pump(tester, const ReadingSettingsPage());
      expect(find.text('المصحف'), findsWidgets);
      await tester.tap(find.text('عند فتح التطبيق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('آخر تبويب').last);
      await tester.pumpAndSettle();
      expect(repository.settings.startupBehavior, StartupBehavior.lastTab);
    });

    testWidgets('turns the page turn on', (tester) async {
      final repository = await _pump(tester, const ReadingSettingsPage());
      await _reveal(tester, find.text('تقليب واقعي للصفحات'));
      await tester.tap(find.text('تقليب واقعي للصفحات'));
      await tester.pumpAndSettle();
      expect(repository.settings.realisticPageTurn, isTrue);
    });
  });

  group('the alerts page', () {
    testWidgets('gathers the prayer alerts, the adhan, the reminders and '
        'vibration', (tester) async {
      await _pump(tester, const AlertsSettingsPage());
      expect(find.text('مواقيت الصلاة'), findsOneWidget);
      expect(find.text('الأذان'), findsOneWidget);
      expect(find.text('التذكيرات'), findsOneWidget);
      await _reveal(tester, find.text('الاهتزاز'));
    });

    testWidgets('the adhan tile opens the adhan page', (tester) async {
      final visited = <String>[];
      await _pump(tester, const AlertsSettingsPage(), visited: visited);
      await tester.tap(find.text('الأذان'));
      await tester.pumpAndSettle();
      expect(visited.last, AppRoute.adhan.path);
    });
  });

  group('the privacy page', () {
    testWidgets('turns crash reports off, and offers the policy when there '
        'is one', (tester) async {
      final repository = await _pump(
        tester,
        const PrivacySettingsPage(),
        policy: Uri.parse('https://example.test/privacy'),
      );
      expect(repository.settings.crashReportsEnabled, isTrue);
      await tester.tap(find.text('تقارير الأعطال'));
      await tester.pumpAndSettle();
      expect(repository.settings.crashReportsEnabled, isFalse);
      expect(find.text('سياسة الخصوصية'), findsOneWidget);
    });

    testWidgets('without a policy address there is no policy tile', (
      tester,
    ) async {
      await _pump(tester, const PrivacySettingsPage());
      expect(find.text('سياسة الخصوصية'), findsNothing);
    });
  });

  group('every page fits', () {
    final pages = <String, Widget>{
      'appearance': const AppearanceSettingsPage(),
      'reading': const ReadingSettingsPage(),
      'alerts': const AlertsSettingsPage(),
      'privacy': const PrivacySettingsPage(),
      'offline': const OfflineSettingsPage(),
    };
    for (final entry in pages.entries) {
      for (final (name, locale, size, scale, theme) in [
        (
          'compact, large text',
          'ar',
          const Size(320, 640),
          2.0,
          AppTheme.light,
        ),
        ('English, dark', 'en', const Size(390, 844), 1.0, AppTheme.dark),
        ('expanded', 'en', const Size(1100, 800), 1.0, AppTheme.light),
      ]) {
        testWidgets('${entry.key}: $name', (tester) async {
          await _pump(
            tester,
            entry.value,
            locale: locale,
            size: size,
            textScale: scale,
            theme: theme,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

/// The router the page under test sits in.
GoRouter router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));
