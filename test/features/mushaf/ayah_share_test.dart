import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/sharing/sharer.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_share_card.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_share_sheet.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_span.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';

/// Records what would be handed to the system's share sheet.
class _RecordingSharer implements Sharer {
  final List<String> texts = [];
  final List<({Uint8List png, String name, String? text})> images = [];

  @override
  Future<void> shareText(String text) async => texts.add(text);

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String name,
    String? text,
  }) async => images.add((png: png, name: name, text: text));
}

void main() {
  group('a span of ayahs', () {
    const span = AyahSpan(surah: 2, first: 255, last: 257);

    test('lists its ayahs in order', () {
      expect(span.length, 3);
      expect(span.refs, [
        const AyahRef(2, 255),
        const AyahRef(2, 256),
        const AyahRef(2, 257),
      ]);
    });

    test('stays inside its surah and its limit, the other end following', () {
      AyahSpan move({int? first, int? last}) =>
          span.adjusted(first: first, last: last, surahLength: 286, limit: 5);
      expect(move(last: 259), const AyahSpan(surah: 2, first: 255, last: 259));
      // Five at most: the start follows the end.
      expect(move(last: 262), const AyahSpan(surah: 2, first: 258, last: 262));
      // The start moved past the end: the end follows.
      expect(move(first: 260), const AyahSpan(surah: 2, first: 260, last: 260));
      expect(move(first: 0).first, 1);
      expect(move(last: 300).last, 286);
    });
  });

  group('sharing', () {
    late QuranText text;
    late _RecordingSharer sharer;
    String? copied;

    Future<void> open(
      WidgetTester tester, {
      Locale locale = const Locale('ar'),
    }) async {
      tester.view.physicalSize = const Size(400, 860);
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
      final container = ProviderContainer(
        overrides: [
          quranMetadataSourceProvider.overrideWithValue(
            FakeQuranMetadataSource(),
          ),
          quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
          sharerProvider.overrideWithValue(sharer),
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
                    const AyahRef(2, 255),
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

    int shownAyahs(WidgetTester tester) =>
        tester.widget<AyahShareCard>(find.byType(AyahShareCard)).span.length;

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
      expect(
        copied,
        '﴿${text.uthmani(const AyahRef(2, 255))} (٢٥٥) '
        '${text.uthmani(const AyahRef(2, 256))} (٢٥٦)﴾\n'
        '[البقرة: ٢٥٥–٢٥٦ · صفحة ٤٢]',
      );
    });

    testWidgets('shares as text', (tester) async {
      await open(tester);
      await tester.tap(find.text('مشاركة كنص'));
      await tester.pump();
      expect(sharer.texts.single, startsWith('﴿'));
      expect(sharer.texts.single, endsWith('[البقرة: ٢٥٥ · صفحة ٤٢]'));
    });

    testWidgets('shares the card as a sharp PNG, with the text beside it', (
      tester,
    ) async {
      await open(tester);
      await tester.runAsync(() async {
        await tester.tap(find.text('مشاركة كصورة'));
        for (var i = 0; i < 20 && sharer.images.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      final shared = sharer.images.single;
      expect(shared.name, 'quran-2-255-255.png');
      // A PNG, three pixels for each of the card's 360.
      expect(shared.png.sublist(1, 4), 'PNG'.codeUnits);
      final width = ByteData.sublistView(shared.png, 16, 20).getUint32(0);
      expect(width, 360 * 3);
      expect(shared.text, endsWith('[البقرة: ٢٥٥ · صفحة ٤٢]'));
    });

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
