import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_actions_sheet.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
    ThemeData? theme,
    Size size = const Size(390, 844),
    double textScale = 1,
    VoidCallback? onSelectMore,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      ],
    );
    addTearDown(container.dispose);
    final text = await tester.runAsync(
      () => container.read(quranTextProvider.future),
    ) as QuranText;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAyahActions(
                  context,
                  HafsAyahTexts(text, fontFamily: 'KfgqpcHafs'),
                  // Ayat al-Kursi: far longer than one line.
                  const AyahRef(2, 255),
                  onSelectMore: onSelectMore,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the pressed ayah floats above the sheet, on one line', (
    tester,
  ) async {
    await open(tester);
    final preview = find.byType(AyahPreview);
    expect(preview, findsOneWidget);
    final verse = tester.widget<RichText>(
      find.descendant(of: preview, matching: find.byType(RichText)).first,
    );
    expect(verse.maxLines, 1);
    expect(verse.overflow, TextOverflow.fade);
    final direction = tester.widget<Directionality>(
      find.descendant(of: preview, matching: find.byType(Directionality)).first,
    );
    expect(direction.textDirection, TextDirection.rtl);
    // Above the sheet, outside it.
    expect(
      tester.getRect(preview).bottom,
      lessThan(tester.getRect(find.byType(ListTile).first).top),
    );
    expect(find.textContaining('البقرة'), findsWidgets);
  });

  testWidgets('choosing more ayahs closes the sheet and starts the choice', (
    tester,
  ) async {
    var started = 0;
    await open(tester, onSelectMore: () => started++);
    await tester.tap(find.text('تحديد أكثر من آية'));
    await tester.pumpAndSettle();
    expect(started, 1);
    expect(find.byType(AyahPreview), findsNothing);
  });

  for (final (name, locale, theme, size, scale) in [
    ('English', const Locale('en'), null, const Size(390, 844), 1.0),
    ('dark', const Locale('ar'), AppTheme.dark, const Size(390, 844), 1.0),
    ('large text', const Locale('ar'), null, const Size(390, 844), 2.0),
    ('compact', const Locale('ar'), null, const Size(320, 568), 1.0),
    (
      'a phone on its side',
      const Locale('ar'),
      null,
      const Size(844, 390),
      1.0,
    ),
    ('expanded', const Locale('ar'), null, const Size(1280, 800), 1.0),
  ]) {
    testWidgets('lays out without overflow: $name', (tester) async {
      await open(
        tester,
        locale: locale,
        theme: theme,
        size: size,
        textScale: scale,
        onSelectMore: () {},
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AyahPreview), findsOneWidget);
    });
  }
}
