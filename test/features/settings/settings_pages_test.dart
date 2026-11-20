import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/config/store_links.dart';
import 'package:mre_quran/core/links/link_opener.dart';
import 'package:mre_quran/core/sharing/sharer.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/features/settings/presentation/offline_settings_page.dart';
import 'package:mre_quran/features/settings/presentation/privacy_settings_page.dart';
import 'package:mre_quran/features/settings/presentation/settings_page.dart';
import 'package:mre_quran/features/settings/presentation/view_settings_page.dart';
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
  List<StoreLink> stores = const [],
  Sharer? sharer,
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
        storeLinksProvider.overrideWithValue(stores),
        if (sharer != null) sharerProvider.overrideWithValue(sharer),
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
          'العرض',
          'الأذان',
          'التذكيرات',
          'المصحف دون اتصال',
          'أدوات الشاشة الرئيسية',
          'الخصوصية',
        ],
      ),
      (
        'en',
        [
          'Display',
          'Adhan',
          'Reminders',
          'Offline Mushaf',
          'Home-screen widgets',
          'Privacy',
        ],
      ),
    ]) {
      testWidgets('names what can be set in $locale, with the view on its '
          'own', (tester) async {
        await _pump(tester, const SettingsPage(), locale: locale);
        // Nothing is set on this page: it only leads to what is.
        expect(find.byType(Switch), findsNothing);
        for (final title in tiles) {
          await _reveal(tester, find.text(title));
          expect(find.text(title), findsOneWidget);
        }
      });
    }

    testWidgets('the view, the adhan, the offline pages, the widgets and '
        'privacy each open a page of their own', (tester) async {
      final visited = <String>[];
      await _pump(tester, const SettingsPage(), visited: visited);
      final paths = {
        'العرض': AppRoute.settingsView.path,
        'الأذان': AppRoute.adhan.path,
        'المصحف دون اتصال': AppRoute.settingsOffline.path,
        'أدوات الشاشة الرئيسية': AppRoute.widgets.path,
        'الخصوصية': AppRoute.settingsPrivacy.path,
      };
      for (final entry in paths.entries) {
        await _reveal(tester, find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(visited.last, entry.value);
        router(tester).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the contact and about tiles stay at the end', (tester) async {
      await _pump(tester, const SettingsPage());
      await _reveal(tester, find.text('تواصل معنا'));
      expect(find.text('واتساب'), findsOneWidget);
      await _reveal(tester, find.textContaining('الإصدار'));
    });

    testWidgets('sharing the app is offered when a store has it, and sends '
        'every store\'s link', (tester) async {
      final sharer = _RecordingSharer();
      await _pump(
        tester,
        const SettingsPage(),
        stores: const [
          StoreLink('Google Play', 'https://play.google.com/store/apps/x'),
          StoreLink('App Store', 'https://apps.apple.com/app/x'),
        ],
        sharer: sharer,
      );
      await _reveal(tester, find.text('شارك التطبيق'));
      await tester.tap(find.text('شارك التطبيق'));
      await tester.pumpAndSettle();
      final text = sharer.texts.single;
      expect(text, contains('مصحفي'));
      expect(
        text,
        contains('Google Play: https://play.google.com/store/apps/x'),
      );
      expect(text, contains('App Store: https://apps.apple.com/app/x'));
      expect(text, isNot(contains('AppGallery')));
    });

    testWidgets('with no store address there is nothing to share, so no '
        'tile', (tester) async {
      await _pump(tester, const SettingsPage());
      await _reveal(tester, find.textContaining('الإصدار'));
      expect(find.text('شارك التطبيق'), findsNothing);
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

  group('the view page', () {
    testWidgets('has a slider for the Mushaf text and one for the adhkar '
        'text, and each keeps its own size', (tester) async {
      final repository = await _pump(tester, const ViewSettingsPage());
      await _reveal(tester, find.text('حجم خط المصحف'));
      expect(find.text('حجم خط الأذكار والدليل'), findsOneWidget);
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2));
      // Drag the adhkar slider to its far end (the larger size).
      await tester.drag(sliders.last, const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(repository.settings.adhkarFontScale, greaterThan(1.3));
      expect(repository.settings.readerFontScale, 1);
      await tester.drag(sliders.first, const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(repository.settings.readerFontScale, lessThan(1));
    });

    testWidgets('changes the language and the digits', (tester) async {
      final repository = await _pump(tester, const ViewSettingsPage());
      await _reveal(tester, find.text('اللغة'));
      await tester.tap(find.text('اللغة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(repository.settings.localeCode, 'en');
      await _reveal(tester, find.text('الأرقام العربية'));
      await tester.tap(find.text('الأرقام العربية'));
      await tester.pumpAndSettle();
      expect(repository.settings.useArabicDigits, isFalse);
    });

    testWidgets('opens on the Mushaf, and the person can choose the last '
        'tab', (tester) async {
      final repository = await _pump(tester, const ViewSettingsPage());
      await _reveal(tester, find.text('عند فتح التطبيق'));
      await tester.tap(find.text('عند فتح التطبيق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('آخر تبويب').last);
      await tester.pumpAndSettle();
      expect(repository.settings.startupBehavior, StartupBehavior.lastTab);
    });

    testWidgets('turns the page turn and the reduced motion on', (
      tester,
    ) async {
      final repository = await _pump(tester, const ViewSettingsPage());
      await _reveal(tester, find.text('تقليب واقعي للصفحات'));
      await tester.tap(find.text('تقليب واقعي للصفحات'));
      await tester.pumpAndSettle();
      expect(repository.settings.realisticPageTurn, isTrue);
      await _reveal(tester, find.text('تقليل الحركة'));
      await tester.tap(find.text('تقليل الحركة'));
      await tester.pumpAndSettle();
      expect(repository.settings.reduceMotion, isTrue);
    });

    testWidgets('keeps what has nothing to do with the view away', (
      tester,
    ) async {
      await _pump(tester, const ViewSettingsPage());
      expect(find.text('تقارير الأعطال'), findsNothing);
      expect(find.text('التذكيرات'), findsNothing);
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
      'view': const ViewSettingsPage(),
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

class _RecordingSharer implements Sharer {
  final List<String> texts = [];

  @override
  Future<void> shareText(String text) async => texts.add(text);

  @override
  Future<void> shareImages(List<SharedImage> images, {String? text}) async {}
}
