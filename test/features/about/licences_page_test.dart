import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/about/presentation/licences_page.dart';
import 'package:mre_quran/features/adhan/data/adhan_catalog.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

void main() {
  final voices = parseAdhanCatalog(
    File('assets/adhan/voices.json').readAsStringSync(),
  );

  Future<void> pump(
    WidgetTester tester, {
    String locale = 'ar',
    ThemeData? theme,
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const LicencesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names every source, every adhan recording with its source '
      'and licence, and the libraries', (tester) async {
    // Tall enough to build every card at once.
    await pump(tester, size: const Size(390, 9000));
    final all = [
      for (final text in tester.widgetList<Text>(
        find.byType(Text, skipOffstage: false),
      ))
        text.data ?? '',
    ].join('\n');
    for (final words in [
      'tanzil.net',
      'qurancomplex.gov.sa',
      'quran.ws',
      'quran-data-kfgqpc',
      'Seen-Arabic',
      'hadith-api',
      'adhan',
      'Material Icons',
    ]) {
      expect(all, contains(words), reason: words);
    }
    for (final voice in voices) {
      expect(all, contains(voice.title('ar')), reason: voice.id);
      expect(all, contains(voice.sourceUrl), reason: voice.id);
    }
    expect(all, contains('الشعراوي'));
    expect(all, contains('الإذن قيد الطلب'));
    expect(find.text('تراخيص المكتبات البرمجية'), findsOneWidget);
    // Every entry carries its terms on a tag.
    expect(find.text('CC BY 3.0'), findsOneWidget);
    expect(find.text('بشروط الناشر'), findsWidgets);
    expect(find.text('OFL 1.1'), findsNWidgets(2));
  });

  for (final (name, locale, theme, scale) in [
    ('English', 'en', null, 1.0),
    ('dark', 'ar', AppTheme.dark, 1.0),
    ('large text', 'ar', null, 2.0),
  ]) {
    testWidgets('lays out without overflow: $name', (tester) async {
      await pump(tester, locale: locale, theme: theme, textScale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
