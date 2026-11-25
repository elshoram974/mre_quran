import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_actions_sheet.dart';
import 'package:mre_quran/features/mushaf/presentation/tafsir_sheet.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/application/tafsir_provider.dart';
import 'package:mre_quran/features/quran_text/data/kfgqpc_tafsir_parser.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/features/quran_text/domain/tafsir.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_settings_repository.dart';

ProviderContainer _container({double adhkarScale = 1}) => ProviderContainer(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      MemorySettingsRepository()
        ..settings = const AppSettings().copyWith(adhkarFontScale: adhkarScale),
    ),
    quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
    quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
    tafsirBytesProvider.overrideWithValue(
      () async => File(QuranTextSource.mushafAsset).readAsBytesSync(),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'an ayah of another reading gets the tafsir of the Hafs ayah(s) it is',
    () {
      late ProviderContainer container;
      setUp(() => container = _container());
      tearDown(() => container.dispose());

      Future<List<AyahRef>> hafsOf(MushafEdition edition, AyahRef ayah) =>
          container.read(hafsAyahsProvider((edition, ayah)).future);

      test(
        'Warsh: Al-Fatiha counts no basmala, Al Imran 1 is two Hafs ayahs',
        () async {
          expect(await hafsOf(MushafEditions.warsh, const AyahRef(1, 1)), [
            const AyahRef(1, 2),
          ]);
          expect(await hafsOf(MushafEditions.warsh, const AyahRef(1, 7)), [
            const AyahRef(1, 7),
          ]);
          expect(await hafsOf(MushafEditions.warsh, const AyahRef(3, 1)), [
            const AyahRef(3, 1),
            const AyahRef(3, 2),
          ]);
        },
      );

      test('Shu\'bah counts as Hafs, and Hafs is itself', () async {
        for (final edition in [MushafEditions.shubah, MushafEditions.hafs]) {
          expect(await hafsOf(edition, const AyahRef(3, 1)), [
            const AyahRef(3, 1),
          ]);
        }
      });

      test('every reading\'s map stays inside its surah and Hafs\'s ayahs', () {
        for (final name in ['warsh', 'qalon', 'douri']) {
          final map = parseHafsMap(
            File('assets/quran/riwayat/${name}_hafs.txt').readAsStringSync(),
          );
          expect(map, isNotEmpty, reason: name);
          for (final MapEntry(:key, :value) in map.entries) {
            expect(value, isNotEmpty, reason: '$name $key');
            expect(value.every((hafs) => hafs.surah == key.surah), isTrue);
          }
        }
      });
    },
  );

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
    for (final ayah in const [AyahRef(2, 256), AyahRef(2, 257)]) {
      await tester.runAsync(
        () => container.read(
          readingTafsirProvider((MushafEditions.hafs, ayah)).future,
        ),
      );
    }
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
    // In RTL the previous ayah is reached by swiping toward the start.
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('البقرة · آية ٢٥٦'), findsOneWidget);
    expect(find.textContaining('[256]', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a reading to explain, no tafsir is offered', (
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
                  tafsir: null,
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

  testWidgets('English tafsir swipes with large text on an expanded screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = _container();
    addTearDown(container.dispose);
    final text = await tester.runAsync(
      () => container.read(quranTextProvider.future),
    ) as QuranText;
    for (final ayah in const [AyahRef(2, 256), AyahRef(2, 257)]) {
      await tester.runAsync(
        () => container.read(
          readingTafsirProvider((MushafEditions.hafs, ayah)).future,
        ),
      );
    }
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: TafsirSheet(
              edition: MushafEditions.hafs,
              text: HafsAyahTexts(text, fontFamily: 'KfgqpcHafs'),
              initial: const AyahRef(2, 256),
              scroll: scroll,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('٢٥٧'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('the size of the words', () {
    Future<(ProviderContainer, ScrollController)> open(
      WidgetTester tester,
      double scale,
    ) async {
      // Tall, so the whole tafsir is built at the larger sizes too.
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = _container(adhkarScale: scale);
      addTearDown(container.dispose);
      final text = await tester.runAsync(
        () => container.read(quranTextProvider.future),
      ) as QuranText;
      await tester.runAsync(() async {
        await container.read(settingsProvider.future);
        await container.read(
          readingTafsirProvider((MushafEditions.hafs, const AyahRef(2, 256)))
              .future,
        );
      });
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            home: Scaffold(
              body: TafsirSheet(
                edition: MushafEditions.hafs,
                text: HafsAyahTexts(text, fontFamily: 'KfgqpcHafs'),
                initial: const AyahRef(2, 256),
                scroll: scroll,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (container, scroll);
    }

    double tafsirSize(WidgetTester tester) {
      final found = find.textContaining('[256]', findRichText: true);
      final rich = tester.widget<RichText>(found);
      return rich.text.style!.fontSize!;
    }

    testWidgets('the tafsir is set at the size chosen for the adhkar', (
      tester,
    ) async {
      await open(tester, 1.5);
      final theme = Theme.of(tester.element(find.byType(TafsirSheet)));
      expect(
        tafsirSize(tester),
        closeTo(theme.textTheme.bodyLarge!.fontSize! * 1.5, 0.01),
      );
    });

    testWidgets('two fingers change it, as in the adhkar, and it is kept', (
      tester,
    ) async {
      final (container, _) = await open(tester, 1);
      final before = tafsirSize(tester);
      final centre = tester.getCenter(find.byType(PageView));
      final a = await tester.startGesture(centre - const Offset(50, 0));
      final b = await tester.startGesture(centre + const Offset(50, 0));
      for (var step = 1; step <= 5; step++) {
        await a.moveTo(centre - Offset(50 + 12.0 * step, 0));
        await b.moveTo(centre + Offset(50 + 12.0 * step, 0));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pump();
      final after = tafsirSize(tester);
      expect(after, greaterThan(before));
      expect(
        container.read(settingsProvider).value!.adhkarFontScale,
        closeTo(after / before, 0.05),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
