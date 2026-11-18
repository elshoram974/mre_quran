import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_actions_sheet.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/application/tafsir_provider.dart';
import 'package:mre_quran/features/quran_text/data/kfgqpc_tafsir_parser.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/features/quran_text/domain/tafsir.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';

ProviderContainer _container() => ProviderContainer(
  overrides: [
    quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
    quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
    tafsirBytesProvider.overrideWithValue(
      () async => File(QuranTextSource.mushafAsset).readAsBytesSync(),
    ),
  ],
);

void main() {
  test('a tafsir is split into its words and the Quran it quotes', () {
    final tafsir = Tafsir.parse(
      "[1] أبتدئ <span class='aya'>ﵡ ٱللَّهِﵠ</span> علم على الرب",
    );
    expect(tafsir.parts, [
      (text: '[1] أبتدئ ', quran: false),
      (text: 'ﵡ ٱللَّهِﵠ', quran: true),
      (text: ' علم على الرب', quran: false),
    ]);
    expect(tafsir.plain, '[1] أبتدئ ﵡ ٱللَّهِﵠ علم على الرب');
  });

  test('the bundled file gives one tafsir for every ayah, in order', () {
    final all = KfgqpcTafsirParser.parse(
      File(QuranTextSource.mushafAsset).readAsStringSync(),
      ayahCount: 6236,
    );
    expect(all, hasLength(6236));
    expect(all.first, startsWith('[1] '));
    expect(all[262], startsWith('[256] '), reason: '2:256');
    expect(all.last, startsWith('[6] '), reason: '114:6');
  });

  test('a file with a row short of its tafsir is refused', () {
    expect(
      () => KfgqpcTafsirParser.parse('header\n1\t2', ayahCount: 1),
      throwsFormatException,
    );
  });

  test(
    'the tafsir of an ayah is read, checked and found by its place',
    () async {
      final container = _container();
      addTearDown(container.dispose);
      final tafsir = await container.read(
        ayahTafsirProvider(const AyahRef(2, 256)).future,
      );
      expect(tafsir.plain, startsWith('[256] '));
    },
  );

  testWidgets('the ayah actions open the tafsir, under the ayah, and step on', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = _container();
    addTearDown(container.dispose);
    final text = await tester.runAsync(
      () => container.read(quranTextProvider.future),
    ) as QuranText;
    // Read on another isolate, in real time.
    await tester.runAsync(
      () => container.read(ayahTafsirProvider(const AyahRef(2, 256)).future),
    );
    await tester.runAsync(
      () => container.read(ayahTafsirProvider(const AyahRef(2, 257)).future),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAyahActions(
                  context,
                  HafsAyahTexts(text, fontFamily: 'KfgqpcHafs'),
                  const AyahRef(2, 256),
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
    await tester.tap(find.text('التفسير'));
    await tester.pumpAndSettle();
    expect(find.text('التفسير الميسر'), findsOneWidget);
    expect(find.textContaining('البقرة · آية ٢٥٦'), findsOneWidget);
    expect(find.textContaining('[256]', findRichText: true), findsOneWidget);

    await tester.tap(find.byTooltip('الآية التالية'));
    await tester.pumpAndSettle();
    expect(find.textContaining('البقرة · آية ٢٥٧'), findsOneWidget);
    expect(find.textContaining('[257]', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('another reading offers no tafsir: it explains the Hafs text', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    final text = await tester.runAsync(
      () => container.read(quranTextProvider.future),
    ) as QuranText;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAyahActions(
                  context,
                  HafsAyahTexts(text, fontFamily: 'KfgqpcHafs'),
                  const AyahRef(2, 256),
                  tafsir: false,
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
    expect(find.text('التفسير'), findsNothing);
  });
}
