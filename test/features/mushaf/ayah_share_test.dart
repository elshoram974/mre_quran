import 'package:material_ui/material_ui.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/sharing/sharer.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_share_card.dart';
import 'package:mre_quran/features/mushaf/application/ayah_printer.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_share_sheet.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_range.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';
import 'package:pdf/pdf.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';

/// Records what would be handed to the system's share sheet.
class _RecordingSharer implements Sharer {
  final List<String> texts = [];
  final List<({List<SharedImage> images, String? text})> shares = [];

  @override
  Future<void> shareText(String text) async => texts.add(text);

  @override
  Future<void> shareImages(List<SharedImage> images, {String? text}) async =>
      shares.add((images: images, text: text));
}

class _RecordingPrinter implements AyahPrinter {
  final List<Uint8List> images = [];
  @override
  Future<void> printCards(List<Uint8List> cards) async => images.addAll(cards);
}

void main() {
  group('the order of the ayahs', () {
    // Al-Fatiha 7, Al-Baqarah 286, Al Imran 200.
    final order = AyahOrder(
      surahCount: 3,
      ayahCount: (surah) => const [7, 286, 200][surah - 1],
    );

    test('numbers every ayah in turn and finds it again', () {
      expect(order.total, 493);
      expect(order.indexOf(const AyahRef(1, 1)), 0);
      expect(order.indexOf(const AyahRef(2, 1)), 7);
      expect(order.at(7), const AyahRef(2, 1));
      expect(order.at(292), const AyahRef(2, 286));
      expect(order.at(293), const AyahRef(3, 1));
      expect(order.at(-5), const AyahRef(1, 1));
      expect(order.at(10000), const AyahRef(3, 200));
    });

    test('steps across the end of a surah', () {
      expect(order.step(const AyahRef(2, 286), 1), const AyahRef(3, 1));
      expect(order.step(const AyahRef(3, 1), -1), const AyahRef(2, 286));
    });

    test('a range across two surahs is cut at the surah end', () {
      const range = AyahRange(AyahRef(2, 285), AyahRef(3, 3));
      expect(order.length(range), 5);
      expect(order.runs(range), [
        (surah: 2, first: 285, last: 286),
        (surah: 3, first: 1, last: 3),
      ]);
      expect(range.contains(const AyahRef(2, 286)), isTrue);
      expect(range.contains(const AyahRef(3, 4)), isFalse);
      expect(range.contains(const AyahRef(1, 7)), isFalse);
    });

    test('moving one end keeps the range in order and inside its limit', () {
      const range = AyahRange(AyahRef(2, 255), AyahRef(2, 257));
      expect(
        order.moveEnd(range, const AyahRef(3, 2), limit: 50),
        const AyahRange(AyahRef(2, 255), AyahRef(3, 2)),
      );
      // Five at most: the start follows the end.
      expect(
        order.moveEnd(range, const AyahRef(3, 2), limit: 5),
        const AyahRange(AyahRef(2, 284), AyahRef(3, 2)),
      );
      // The start moved past the end: the end follows.
      expect(
        order.moveStart(range, const AyahRef(2, 260), limit: 5),
        const AyahRange(AyahRef(2, 260), AyahRef(2, 260)),
      );
      expect(
        order.moveStart(range, const AyahRef(2, 400), limit: 5).start,
        const AyahRef(2, 286),
      );
    });

    test('a range is between two ayahs whichever is pressed first', () {
      expect(
        AyahRange.between(const AyahRef(3, 2), const AyahRef(2, 286)),
        const AyahRange(AyahRef(2, 286), AyahRef(3, 2)),
      );
    });
  });

  group('sharing', () {
    late QuranText text;
    late _RecordingSharer sharer;
    late _RecordingPrinter printer;
    String? copied;

    Future<void> open(
      WidgetTester tester, {
      Locale locale = const Locale('ar'),
      AyahRange initial = const AyahRange.single(AyahRef(2, 255)),
      Size size = const Size(400, 860),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      sharer = _RecordingSharer();
      printer = _RecordingPrinter();
      final container = ProviderContainer(
        overrides: [
          quranMetadataSourceProvider.overrideWithValue(
            FakeQuranMetadataSource(),
          ),
          quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
          sharerProvider.overrideWithValue(sharer),
          ayahPrinterProvider.overrideWithValue(printer),
        ],
      );
      addTearDown(container.dispose);
      text = await tester.runAsync(
        () => container.read(quranTextProvider.future),
      ) as QuranText;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showAyahShare(
                    context,
                    HafsAyahTexts(text, fontFamily: 'KfgqpcHafs'),
                    initial,
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

    int shownAyahs(WidgetTester tester) => tester
        .widgetList<AyahShareCard>(find.byType(AyahShareCard))
        .fold(0, (sum, card) => sum + card.refs.length);

    testWidgets('opens on the ayah pressed, and the range can grow', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('مشاركة الآيات'), findsOneWidget);
      expect(shownAyahs(tester), 1);
      await tester.tap(find.byTooltip('الآية التالية').last);
      await tester.tap(find.byTooltip('الآية التالية').last);
      await tester.pump();
      expect(shownAyahs(tester), 3);
      expect(find.text('٢٥٧'), findsWidgets);
    });

    testWidgets('copy writes the ayahs with their numbers, surah and page', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byTooltip('الآية التالية').last);
      await tester.pump();
      await tester.tap(find.text('نسخ'));
      await tester.pump();
      // Every line starts with a right-to-left mark, so it reads from the
      // right wherever it is pasted.
      expect(
        copied,
        '\u200F﴿${text.uthmani(const AyahRef(2, 255))} (٢٥٥) '
        '${text.uthmani(const AyahRef(2, 256))} (٢٥٦)﴾\n'
        '\u200F[البقرة: ٢٥٥–٢٥٦ · صفحة ٤٢]',
      );
    });

    testWidgets('shares as text', (tester) async {
      await open(tester);
      await tester.tap(find.text('مشاركة كنص'));
      await tester.pump();
      expect(sharer.texts.single, startsWith('\u200F﴿'));
      expect(sharer.texts.single, endsWith('[البقرة: ٢٥٥ · صفحة ٤٢]'));
    });

    testWidgets('shares the card as a sharp PNG, with the text beside it', (
      tester,
    ) async {
      await open(tester);
      await tester.runAsync(() async {
        await tester.tap(find.text('مشاركة كصورة'));
        for (var i = 0; i < 20 && sharer.shares.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      final shared = sharer.shares.single;
      final image = shared.images.single;
      expect(image.name, 'quran-2-255-2-255.png');
      // A PNG, three pixels for each of the card's 360.
      expect(image.png.sublist(1, 4), 'PNG'.codeUnits);
      final width = ByteData.sublistView(image.png, 16, 20).getUint32(0);
      expect(width, 360 * 3);
      expect(shared.text, endsWith('[البقرة: ٢٥٥ · صفحة ٤٢]'));
    });

    testWidgets('prints the rendered verse and produces a multi-page PDF', (
      tester,
    ) async {
      await open(tester);
      await tester.runAsync(() async {
        await tester.tap(find.text('طباعة الآيات'));
        for (var i = 0; i < 100 && printer.images.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(printer.images, hasLength(1));
      expect(printer.images.single.sublist(1, 4), 'PNG'.codeUnits);
      final document = await buildAyahPrintPdf([
        printer.images.single,
        printer.images.single,
      ], PdfPageFormat.a4);
      expect(String.fromCharCodes(document.take(4)), '%PDF');
      expect(String.fromCharCodes(document), contains('/Count 2'));
    });

    testWidgets('the last ayahs of a surah and the first of the next are '
        'copied together, each surah in its own brackets', (tester) async {
      await open(
        tester,
        initial: const AyahRange(AyahRef(2, 285), AyahRef(3, 2)),
      );
      expect(shownAyahs(tester), 4);
      await tester.tap(find.text('نسخ'));
      await tester.pump();
      expect(
        copied,
        '\u200F﴿${text.uthmani(const AyahRef(2, 285))} (٢٨٥) '
        '${text.uthmani(const AyahRef(2, 286))} (٢٨٦)﴾\n'
        '\u200F[البقرة: ٢٨٥–٢٨٦ · صفحة ٤٩]\n'
        // Al Imran is shared from its first ayah: its basmala comes first.
        '\u200F${text.basmala}\n'
        '\u200F﴿${text.uthmani(const AyahRef(3, 1))} (١) '
        '${text.uthmani(const AyahRef(3, 2))} (٢)﴾\n'
        '\u200F[آل عمران: ١–٢ · صفحة ٥٠]',
      );
    });

    testWidgets('stepping the end past a surah goes on into the next', (
      tester,
    ) async {
      await open(tester, initial: const AyahRange.single(AyahRef(2, 286)));
      await tester.tap(find.byTooltip('الآية التالية').last);
      await tester.pump();
      expect(shownAyahs(tester), 2);
      expect(find.textContaining('آل عمران'), findsWidgets);
    });

    testWidgets('a long choice is cut into several pictures, all sent', (
      tester,
    ) async {
      await open(
        tester,
        initial: const AyahRange(AyahRef(2, 1), AyahRef(2, 20)),
      );
      final cards = tester.widgetList<AyahShareCard>(
        find.byType(AyahShareCard, skipOffstage: false),
      );
      expect(cards.length, greaterThan(1));
      expect(cards.first.parts, cards.length);
      // Every ayah is on exactly one picture, in order.
      expect(
        [for (final card in cards) ...card.refs],
        [for (var ayah = 1; ayah <= 20; ayah++) AyahRef(2, ayah)],
      );
    });

    for (final (name, size, scale) in [
      ('a phone on its side', const Size(844, 390), 1.0),
      ('the largest text', const Size(390, 844), 2.0),
    ]) {
      testWidgets('fits $name: everything scrolls, the actions stay', (
        tester,
      ) async {
        await open(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(find.text('مشاركة كصورة'), findsOneWidget);
      });
    }

    testWidgets('the card shows the surah, the ayah and its page, and writes '
        'the ayahs right to left in English too', (tester) async {
      await open(tester, locale: const Locale('en'));
      final card = find.byType(AyahShareCard);
      expect(
        find.descendant(of: card, matching: find.textContaining('Page')),
        findsOneWidget,
      );
      final verse = tester.widget<Directionality>(
        find.descendant(of: card, matching: find.byType(Directionality)).first,
      );
      expect(verse.textDirection, TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });
  });
}
