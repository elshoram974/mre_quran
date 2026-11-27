import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderClipRRect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/theme/app_tokens.dart';
import 'package:mre_quran/features/mushaf/application/reader_immersive_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';
import 'package:mre_quran/features/mushaf/presentation/reader_bar.dart';
import 'package:mre_quran/features/mushaf/presentation/reader_page_labels.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_pager.dart';
import 'package:mre_quran/features/mushaf/presentation/page_scrubber.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/presentation/index_tiles.dart';
import 'package:mre_quran/features/quran_index/presentation/quran_index_page.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';
import 'package:mre_quran/core/hints/hints.dart';

import '../../helpers/no_hints_repository.dart';
import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_bookmarks_repository.dart';
import '../../helpers/memory_reading_position_repository.dart';
import '../../helpers/memory_settings_repository.dart';

/// A page label chip by its tooltip. The chips use material_ui's Tooltip,
/// which `find.byTooltip` (Flutter's own Tooltip) does not match.
Finder _chip(String message) => find.byWidgetPredicate(
  (widget) => widget is Tooltip && widget.message == message,
);

Future<(ProviderContainer, MemoryReadingPositionRepository)> _pump(
  WidgetTester tester, {
  int? savedPage,
  String locale = 'ar',
  double width = 390,
  double height = 844,
  double textScale = 1,
  PageTurnStyle pageTurn = PageTurnStyle.auto,
  ReaderPageLayout layout = ReaderPageLayout.auto,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final positions = MemoryReadingPositionRepository()..page = savedPage;
  final container = ProviderContainer(
    overrides: [
      hintsRepositoryProvider.overrideWithValue(NoHintsRepository()),
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      bookmarksRepositoryProvider.overrideWithValue(
        MemoryBookmarksRepository(),
      ),
      readingPositionRepositoryProvider.overrideWithValue(positions),
      settingsRepositoryProvider.overrideWithValue(
        MemorySettingsRepository()
          ..settings = AppSettings(
            localeCode: locale,
            pageTurn: pageTurn,
            readerMode: ReaderMode.text,
            readerPageLayout: layout,
          ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData.fromView(tester.view)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: theme,
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const Scaffold(body: MushafPage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, positions);
}

void main() {
  testWidgets('opens at page 1 with the floating bars showing', (tester) async {
    await _pump(tester);
    expect(find.text('سورة الفاتحة'), findsWidgets, reason: 'banner');
    // The place pill of the floating controls: the page, its surah and juz.
    expect(find.text('صفحة ١').hitTestable(), findsOneWidget);
    expect(find.text('الفاتحة · الجزء ١').hitTestable(), findsOneWidget);
    expect(find.byType(PageScrubber), findsNothing);
    expect(find.bySemanticsLabel('ابحث في القرآن'), findsOneWidget);
    expect(find.byTooltip('إضافة علامة للصفحة'), findsOneWidget);
    // Display options and the surah index stay available in separate pills.
    expect(find.byTooltip('العرض').hitTestable(), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined).hitTestable(), findsWidgets);
    expect(find.byTooltip('إخفاء الأشرطة'), findsNothing);
    // The page's own labels step aside while the bars show.
    expect(find.text('الجزء ١').hitTestable(), findsNothing);
  });

  testWidgets('the surah pill opens the index', (tester) async {
    await _pump(tester, savedPage: 5);
    await tester.tap(find.byIcon(Icons.menu_book_outlined).hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.byType(QuranIndexPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the arrows keep their sides: back on the right, onward on the '
      'left, number in the middle', (tester) async {
    final (container, _) = await _pump(tester, savedPage: 5);
    container.read(readerImmersiveProvider.notifier).hide();
    await tester.pumpAndSettle();
    final back = tester.getCenter(_chip('الصفحة السابقة').hitTestable());
    final next = tester.getCenter(_chip('الصفحة التالية').hitTestable());
    final number = tester.getCenter(_chip('الانتقال إلى صفحة').hitTestable());
    expect(back.dx, greaterThan(number.dx));
    expect(next.dx, lessThan(number.dx));
    expect(number.dx, closeTo(195, 12));
  });

  testWidgets('hiding the bars leaves the page number and the arrow', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);
    await tester.tapAt(const Offset(195, 500));
    await tester.pumpAndSettle();
    expect(container.read(readerImmersiveProvider), isTrue);
    expect(find.text('الجزء ١').hitTestable(), findsOneWidget);
    // The page number is a chip; the banner's medallion also holds a one.
    expect(
      find
          .descendant(of: find.byType(ReaderChip), matching: find.text('١'))
          .hitTestable(),
      findsOneWidget,
    );
    expect(_chip('الصفحة التالية').hitTestable(), findsOneWidget);
    expect(find.bySemanticsLabel('ابحث في القرآن').hitTestable(), findsNothing);
  });

  testWidgets('the surah, juz, and page number are part of the page itself', (
    tester,
  ) async {
    await _pump(tester, savedPage: 5, pageTurn: PageTurnStyle.realistic);
    // Inside each page's own subtree, so the turning sheet carries them.
    // The neighbours are built but not painted until a turn needs them.
    for (final number in [4, 5, 6]) {
      final labels = find.descendant(
        of: find.byKey(ValueKey<int>(number), skipOffstage: false),
        matching: find.byType(ReaderPageLabels, skipOffstage: false),
      );
      expect(labels, findsOneWidget, reason: 'page $number');
    }
  });

  testWidgets('the chips never cover the text and stay on screen', (
    tester,
  ) async {
    final (container, _) = await _pump(tester, savedPage: 42);
    container.read(readerImmersiveProvider.notifier).hide();
    await tester.pumpAndSettle();
    final page = tester.getRect(
      find.byKey(const ValueKey<int>(42)).hitTestable(),
    );
    final chip = tester.getRect(find.text('الجزء ٣').hitTestable());
    final number = tester.getRect(find.text('٤٢').hitTestable());
    expect(chip.top, greaterThanOrEqualTo(page.top));
    expect(number.bottom, lessThanOrEqualTo(page.bottom));
  });

  group('every page names its juz and its hizb', () {
    /// The reader at [page] with its bars away, so the page's own labels
    /// show.
    Future<void> labels(
      WidgetTester tester,
      int page, {
      String locale = 'ar',
      double width = 390,
      double height = 844,
      double textScale = 1,
      ThemeData? theme,
    }) async {
      await tester.pumpWidget(const SizedBox());
      final (container, _) = await _pump(
        tester,
        savedPage: page,
        locale: locale,
        width: width,
        height: height,
        textScale: textScale,
        theme: theme,
      );
      container.read(readerImmersiveProvider.notifier).hide();
      await tester.pumpAndSettle();
    }

    /// The chips of the row above the page in sight that holds [label],
    /// from the left.
    List<Rect> chips(WidgetTester tester, String label) {
      final row = find.ancestor(
        of: find.text(label).hitTestable(),
        matching: find.byType(ReaderHeader),
      );
      final rects = [
        for (final chip
            in find
                .descendant(of: row, matching: find.byType(ReaderChip))
                .evaluate())
          tester.getRect(find.byWidget(chip.widget)),
      ]..sort((a, b) => a.left.compareTo(b.left));
      final bounds = tester.getRect(row);
      for (final rect in rects) {
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right));
      }
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].left, greaterThanOrEqualTo(rects[i - 1].right));
      }
      return rects;
    }

    testWidgets('worded as the margin of the Mushaf marks it', (tester) async {
      for (final (page, juz, hizb) in const [
        (1, 'الجزء ١', 'الحزب ١'),
        // The first quarter mark is part way down page 5.
        (5, 'الجزء ١', 'ربع الحزب ١'),
        // Hizb 2 begins part way down page 11.
        (11, 'الجزء ١', 'الحزب ٢'),
        // Half of hizb 2 begins at the very top of page 17.
        (17, 'الجزء ١', 'نصف الحزب ٢'),
        (42, 'الجزء ٣', 'الحزب ٥'),
        (604, 'الجزء ٣٠', 'ثلاثة أرباع الحزب ٦٠'),
      ]) {
        await labels(tester, page);
        expect(find.text(juz).hitTestable(), findsOneWidget, reason: '$page');
        expect(find.text(hizb).hitTestable(), findsOneWidget, reason: '$page');
        expect(tester.takeException(), isNull, reason: '$page');
      }
    });

    testWidgets('in Arabic the surah leads from the right, and the juz then '
        'the hizb end the row on the left', (tester) async {
      await labels(tester, 17);
      double at(Finder finder) => tester.getCenter(finder.hitTestable()).dx;
      final row = chips(tester, 'نصف الحزب ٢');
      // From the left: the hizb, the juz, the step to the next surah, the
      // surah.
      expect(row, hasLength(4));
      expect(at(find.text('نصف الحزب ٢')), closeTo(row[0].center.dx, 1));
      expect(at(find.text('الجزء ١')), closeTo(row[1].center.dx, 1));
      expect(at(_chip('السورة التالية')), closeTo(row[2].center.dx, 1));
      expect(
        tester
            .widget<Text>(find.text('نصف الحزب ٢').hitTestable())
            .textDirection,
        TextDirection.rtl,
      );
      // The row's two ends are at the page's edges.
      final page = tester.getRect(
        find.byKey(const ValueKey<int>(17)).hitTestable(),
      );
      expect(row.first.left - page.left, lessThan(AppTokens.gutterCompact));
      expect(page.right - row.last.right, lessThan(AppTokens.gutterCompact));
    });

    testWidgets('in English the words are English and read left to right, '
        'on the Mushaf\'s own sides', (tester) async {
      // The numbers keep the app's digit style, here the default
      // Arabic-Indic.
      for (final (page, hizb) in const [
        (5, '¼ Hizb ١'),
        (11, 'Hizb ٢'),
        (604, '¾ Hizb ٦٠'),
      ]) {
        await labels(tester, page, locale: 'en');
        expect(find.text(hizb).hitTestable(), findsOneWidget, reason: '$page');
      }
      await labels(tester, 17, locale: 'en');
      double at(String label) =>
          tester.getCenter(find.text(label).hitTestable()).dx;
      // The Mushaf runs right to left in every language, so the sides stay:
      // from the left, the hizb, the juz, the step onward, the surah.
      final row = chips(tester, '½ Hizb ٢');
      expect(row, hasLength(4));
      expect(at('½ Hizb ٢'), closeTo(row[0].center.dx, 1));
      expect(at('Juz ١'), closeTo(row[1].center.dx, 1));
      // The words themselves read left to right, so the fraction leads.
      for (final label in ['Juz ١', '½ Hizb ٢']) {
        expect(
          tester.widget<Text>(find.text(label).hitTestable()).textDirection,
          TextDirection.ltr,
          reason: label,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap on the hizb opens the index on its hizb list, at '
        'that hizb', (tester) async {
      await labels(tester, 11);
      await tester.tap(find.text('الحزب ٢').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(QuranIndexPage), findsOneWidget);
      final tabs = tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabs.controller!.index, 2);
      final row = find.ancestor(
        of: find.text('الحزب ٢'),
        matching: find.byType(IndexRow),
      );
      expect(tester.widget<IndexRow>(row.first).current, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the longest labels stay on the page, at every phone width '
        'and text size, in both languages', (tester) async {
      // Page 603: the last quarter of the last hizb, in the thirtieth juz.
      for (final width in [320.0, 360.0, 390.0]) {
        for (final textScale in [1.0, 2.0]) {
          for (final (locale, hizb) in const [
            ('ar', 'ثلاثة أرباع الحزب ٦٠'),
            ('en', '¾ Hizb ٦٠'),
          ]) {
            await labels(
              tester,
              603,
              locale: locale,
              width: width,
              textScale: textScale,
            );
            expect(chips(tester, hizb), hasLength(4));
            expect(
              tester.takeException(),
              isNull,
              reason: '$locale, $width wide, text at $textScale',
            );
          }
        }
      }
    });

    testWidgets('a medium window keeps one page, labelled the same', (
      tester,
    ) async {
      await labels(tester, 17, width: 700, height: 1000);
      expect(find.text('الجزء ١').hitTestable(), findsOneWidget);
      expect(chips(tester, 'نصف الحزب ٢'), hasLength(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('each page of a spread carries its own juz and hizb', (
      tester,
    ) async {
      // Pages 21 and 22 face each other, and the third hizb, with the second
      // juz, begins on page 22.
      await labels(tester, 21, width: 1194, height: 834);
      Finder on(int page, String label) => find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ReaderPageLabels && w.page == page,
        ),
        matching: find.text(label),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<int>(21)).hitTestable(),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<int>(22)).hitTestable(),
      );
      for (final label in ['الجزء ١', 'ثلاثة أرباع الحزب ٢']) {
        final chip = tester.getRect(on(21, label));
        expect(chip.left, greaterThanOrEqualTo(right.left), reason: label);
        expect(chip.right, lessThanOrEqualTo(right.right), reason: label);
      }
      for (final label in ['الجزء ٢', 'الحزب ٣']) {
        final chip = tester.getRect(on(22, label));
        expect(chip.left, greaterThanOrEqualTo(left.left), reason: label);
        expect(chip.right, lessThanOrEqualTo(left.right), reason: label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('in the dark theme the chips take the page\'s colours', (
      tester,
    ) async {
      await labels(tester, 17, theme: AppTheme.dark);
      final scheme = AppTheme.dark.colorScheme;
      for (final label in ['الجزء ١', 'نصف الحزب ٢']) {
        final pill = tester.widget<Material>(
          find
              .ancestor(
                of: find.text(label).hitTestable(),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(pill.color, scheme.secondaryContainer.withValues(alpha: 0.7));
        expect(
          tester.widget<Text>(find.text(label).hitTestable()).style?.color,
          scheme.onSecondaryContainer,
        );
      }
    });
  });

  testWidgets('the scrubber names the hizb too; the page pill keeps the '
      'surah and the juz', (tester) async {
    await _pump(tester, savedPage: 17);
    expect(find.text('البقرة · الجزء ١').hitTestable(), findsOneWidget);
    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PageScrubber),
        matching: find.text('البقرة · الجزء ١ · نصف الحزب ٢'),
      ),
      findsOneWidget,
    );
    // Closed again, the pill says what it said.
    await tester.tap(find.byTooltip('إغلاق شريط الصفحات'));
    await tester.pumpAndSettle();
    expect(find.text('البقرة · الجزء ١').hitTestable(), findsOneWidget);
  });

  testWidgets('the scrubber\'s line reads in English, dark, on a narrow '
      'screen at large text', (tester) async {
    await _pump(
      tester,
      savedPage: 604,
      locale: 'en',
      width: 320,
      textScale: 2,
      theme: AppTheme.dark,
    );
    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PageScrubber),
        matching: find.text('الإخلاص · Juz ٣٠ · ¾ Hizb ٦٠'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the arrows step to the next page and the next surah', (
    tester,
  ) async {
    final (container, positions) = await _pump(tester, savedPage: 5);
    container.read(readerImmersiveProvider.notifier).hide();
    await tester.pumpAndSettle();
    await tester.tap(_chip('الصفحة التالية').hitTestable());
    await tester.pumpAndSettle();
    expect(positions.page, 6);
    await tester.tap(_chip('الصفحة السابقة').hitTestable());
    await tester.pumpAndSettle();
    expect(positions.page, 5);
    await tester.tap(_chip('الصفحة التالية').hitTestable());
    await tester.pumpAndSettle();
    container.read(readerImmersiveProvider.notifier).hide();
    await tester.pumpAndSettle();
    await tester.tap(_chip('السورة التالية').hitTestable());
    await tester.pumpAndSettle();
    // Al-Baqarah is followed by Al Imran, which starts on page 50.
    expect(positions.page, 50);
  });

  testWidgets('the number button accepts a typed page and goes to it', (
    tester,
  ) async {
    final (_, positions) = await _pump(tester, savedPage: 10);
    // The place pill opens the scrubber, whose number button asks for a page.
    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pumpAndSettle();
    expect(find.byType(PageScrubber), findsOneWidget);
    await tester.tap(find.byTooltip('الانتقال إلى صفحة').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('صفحة ١٠ من ٦٠٤'), findsOneWidget);
    final input = find.byType(TextField).first;
    await tester.enterText(input, '600');
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتقال'));
    await tester.pumpAndSettle();
    expect(positions.page, greaterThan(550));
  });

  testWidgets('the scrubber closes by its button and with the bars', (
    tester,
  ) async {
    final (container, _) = await _pump(tester, savedPage: 10);
    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق شريط الصفحات'));
    await tester.pumpAndSettle();
    expect(find.byType(PageScrubber), findsNothing);
    expect(find.byType(ReaderPlacePill), findsOneWidget);

    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pumpAndSettle();
    container.read(readerImmersiveProvider.notifier).hide();
    await tester.pumpAndSettle();
    container.read(readerImmersiveProvider.notifier).toggle();
    await tester.pumpAndSettle();
    expect(find.byType(PageScrubber), findsNothing);
  });

  testWidgets('a tap on the page closes only the scrubber; the bars stay', (
    tester,
  ) async {
    final (container, _) = await _pump(tester, savedPage: 10);
    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pumpAndSettle();
    expect(find.byType(PageScrubber), findsOneWidget);
    await tester.tapAt(const Offset(195, 300));
    await tester.pumpAndSettle();
    expect(find.byType(PageScrubber), findsNothing);
    expect(find.byType(ReaderPlacePill).hitTestable(), findsOneWidget);
    expect(container.read(readerImmersiveProvider), isFalse);
    // The next tap puts the bars away, as before.
    await tester.tapAt(const Offset(195, 300));
    await tester.pumpAndSettle();
    expect(container.read(readerImmersiveProvider), isTrue);
  });

  testWidgets('back closes the scrubber before it leaves the reader', (
    tester,
  ) async {
    await _pump(tester, savedPage: 10);
    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PageScrubber), findsNothing);
    expect(find.byType(ReaderPlacePill).hitTestable(), findsOneWidget);
  });

  testWidgets('the scrubber grows out of the page pill and shrinks back into '
      'it', (tester) async {
    await _pump(tester, savedPage: 10);
    final pill = tester.getRect(find.byType(ReaderPlacePill));
    await tester.tap(find.byType(ReaderPlacePill));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    // Early on, the scrubber shows only through a box near the pill's.
    final early = tester.renderObject<RenderClipRRect>(
      find
          .ancestor(
            of: find.byType(PageScrubber),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    final clip = early.clipper!.getClip(early.size);
    final box = clip.outerRect.shift(early.localToGlobal(Offset.zero));
    expect(box.width, lessThan(early.size.width));
    expect((box.center.dx - pill.center.dx).abs(), lessThan(pill.width / 2));
    await tester.pumpAndSettle();
    // Open, it is whole: no clip left.
    expect(
      find.ancestor(
        of: find.byType(PageScrubber),
        matching: find.byWidgetPredicate(
          (widget) => widget is ClipRRect && widget.clipper != null,
        ),
      ),
      findsNothing,
    );
    await tester.tap(find.byTooltip('إغلاق شريط الصفحات'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(ReaderPlacePill)), pill);
  });

  testWidgets('the toolbar keeps the bookmarks at hand: they open the index '
      'on its bookmarks', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('العلامات'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد علامات بعد'), findsOneWidget);
  });

  testWidgets('the bookmark button marks the page and unmarks it', (
    tester,
  ) async {
    await _pump(tester, savedPage: 42);
    await tester.tap(find.byTooltip('إضافة علامة للصفحة'));
    await tester.pumpAndSettle();
    expect(find.text('تمت إضافة العلامة'), findsOneWidget);
    expect(find.byTooltip('إزالة علامة الصفحة'), findsOneWidget);
    await tester.tap(find.byTooltip('إزالة علامة الصفحة'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('إضافة علامة للصفحة'), findsOneWidget);
  });

  testWidgets('two fingers resize the Quran text as they move, and keep the '
      'size', (tester) async {
    final (container, _) = await _pump(tester);
    double size() => tester
        .widgetList<RichText>(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.style?.fontFamily == AppTokens.mushafFontFamily,
          ),
        )
        .map((text) => text.text.style!.fontSize!)
        .reduce((a, b) => a > b ? a : b);
    final before = size();
    final centre = tester.getCenter(find.byType(MushafPager));
    final a = await tester.startGesture(centre - const Offset(50, 0));
    final b = await tester.startGesture(centre + const Offset(50, 0));
    for (var step = 1; step <= 5; step++) {
      final span = 50.0 + 20 * step;
      await a.moveTo(centre - Offset(span, 0));
      await b.moveTo(centre + Offset(span, 0));
      await tester.pump();
    }
    // The text is already bigger while the fingers are still down.
    expect(size(), greaterThan(before * 1.2));
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    final kept = container.read(settingsProvider).value!.readerFontScale;
    expect(kept, closeTo(1.6, 0.03));
    expect(size(), closeTo(before * kept, before * 0.03));
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping turns the page right to left and saves it', (
    tester,
  ) async {
    final (container, positions) = await _pump(tester);
    // In a right-to-left Mushaf the next page comes from the left.
    await tester.fling(find.byType(BookFlip), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(positions.page, 2);
    expect(find.text('سورة البقرة'), findsWidgets);
    expect(
      container.read(readerImmersiveProvider),
      isTrue,
      reason: 'turning the page puts the bars away',
    );
  });

  testWidgets('a page change made elsewhere moves the pager', (tester) async {
    final (container, _) = await _pump(tester);
    await container.read(readingPositionProvider.notifier).setPage(604);
    await tester.pumpAndSettle();
    container.read(readerImmersiveProvider.notifier).hide();
    await tester.pumpAndSettle();
    expect(find.text('٦٠٤').hitTestable(), findsOneWidget);
    expect(find.text('الجزء ٣٠').hitTestable(), findsOneWidget);
  });

  testWidgets('a tap hides the app bars and another brings them back', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);
    final book = tester.getRect(find.byType(BookFlip));
    await tester.tapAt(const Offset(195, 500));
    await tester.pumpAndSettle();
    expect(container.read(readerImmersiveProvider), isTrue);
    // The chips belong to the page: they stay, and the page keeps its size.
    expect(find.text('الفاتحة').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.byType(BookFlip)), book);
    await tester.tapAt(const Offset(195, 500));
    await tester.pumpAndSettle();
    expect(container.read(readerImmersiveProvider), isFalse);
  });

  testWidgets('English, large text, narrow width, and long pages do not '
      'overflow', (tester) async {
    await _pump(tester, locale: 'en', width: 320, textScale: 2, savedPage: 50);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide window shows two pages side by side', (tester) async {
    await _pump(tester, width: 1000, savedPage: 3);
    // Pages 3 and 4 face each other; the right-hand page is odd.
    expect(find.byKey(const ValueKey<int>(3)).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(4)).hitTestable(), findsOneWidget);
    final right = tester
        .getCenter(find.byKey(const ValueKey<int>(3)).hitTestable())
        .dx;
    final left = tester
        .getCenter(find.byKey(const ValueKey<int>(4)).hitTestable())
        .dx;
    expect(right, greaterThan(left));
  });

  test('automatic layout picks two pages only for a wide tablet', () {
    bool auto(Size size) => resolveMushafSpread(ReaderPageLayout.auto, size);
    expect(auto(const Size(1194, 834)), isTrue, reason: 'iPad held wide');
    expect(auto(const Size(834, 1194)), isFalse, reason: 'iPad held tall');
    expect(auto(const Size(932, 430)), isFalse, reason: 'phone on its side');
    expect(auto(const Size(390, 844)), isFalse, reason: 'phone');
    expect(
      auto(const Size(884, 982)),
      isTrue,
      reason: 'a foldable opened like a book, near square',
    );
    expect(auto(const Size(820, 1180)), isFalse, reason: 'iPad held tall');
    // Half folded, the fold upright between the halves: a page each side,
    // even where the screen alone would keep one.
    const fold = DisplayFeature(
      bounds: Rect.fromLTWH(400, 0, 0, 900),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.postureHalfOpened,
    );
    expect(
      resolveMushafSpread(
        ReaderPageLayout.auto,
        const Size(800, 900),
        features: const [fold],
      ),
      isTrue,
    );
    // Folded flat across (a phone held like a laptop): not a book.
    expect(
      resolveMushafSpread(
        ReaderPageLayout.auto,
        const Size(800, 1400),
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(0, 700, 800, 0),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      ),
      isFalse,
    );
    expect(
      resolveMushafSpread(ReaderPageLayout.spread, const Size(390, 844)),
      isTrue,
      reason: 'a person may ask for two pages on a phone',
    );
    expect(
      resolveMushafSpread(ReaderPageLayout.single, const Size(1194, 834)),
      isFalse,
      reason: 'and for one on a big tablet',
    );
  });

  test('automatic page turning is like paper with two pages or on a '
      'tablet, and a slide on a phone', () {
    bool auto(Size size, {bool spread = false}) =>
        resolveRealisticPageTurn(PageTurnStyle.auto, size, spread: spread);
    expect(auto(const Size(390, 844)), isFalse, reason: 'phone');
    expect(auto(const Size(932, 430)), isFalse, reason: 'phone on its side');
    expect(auto(const Size(834, 1194)), isTrue, reason: 'tablet, one page');
    expect(auto(const Size(744, 1133)), isTrue, reason: 'small tablet');
    expect(
      auto(const Size(1194, 834), spread: true),
      isTrue,
      reason: 'two facing pages',
    );
    expect(
      auto(const Size(390, 844), spread: true),
      isTrue,
      reason: 'two pages asked for on a phone',
    );
    // The person's own choice always wins.
    for (final spread in [true, false]) {
      for (final size in const [Size(390, 844), Size(1194, 834)]) {
        expect(
          resolveRealisticPageTurn(
            PageTurnStyle.realistic,
            size,
            spread: spread,
          ),
          isTrue,
        );
        expect(
          resolveRealisticPageTurn(PageTurnStyle.slide, size, spread: spread),
          isFalse,
        );
      }
    }
  });

  testWidgets('the Mushaf turns like paper on a tablet and slides on a '
      'phone until the person chooses', (tester) async {
    bool realistic() =>
        tester.widget<BookFlip>(find.byType(BookFlip)).realistic;
    await _pump(tester, savedPage: 3);
    expect(realistic(), isFalse, reason: 'phone');
    await _pump(tester, savedPage: 3, width: 834, height: 1194);
    expect(realistic(), isTrue, reason: 'tablet held tall, one page');
    await _pump(tester, savedPage: 3, width: 1194, height: 834);
    expect(realistic(), isTrue, reason: 'tablet held wide, two pages');
    await _pump(
      tester,
      savedPage: 3,
      width: 1194,
      height: 834,
      pageTurn: PageTurnStyle.slide,
    );
    expect(realistic(), isFalse, reason: 'turned off by the person');
    await _pump(tester, savedPage: 3, pageTurn: PageTurnStyle.realistic);
    expect(realistic(), isTrue, reason: 'turned on by the person');
  });

  testWidgets('a tall tablet shows one page, a wide one two', (tester) async {
    await _pump(tester, width: 834, height: 1194, savedPage: 3);
    expect(find.byKey(const ValueKey<int>(3)).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(4)).hitTestable(), findsNothing);
  });

  testWidgets('a phone on its side keeps one page', (tester) async {
    await _pump(tester, width: 844, height: 390, savedPage: 3);
    expect(find.byKey(const ValueKey<int>(3)).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(4)).hitTestable(), findsNothing);
  });

  testWidgets('a spread keeps only the arrows on its outer edges', (
    tester,
  ) async {
    await _pump(tester, width: 1194, height: 834, savedPage: 3);
    // The footer of one page: its arrows are the chevrons inside ReaderFooter.
    Finder arrow(int page, IconData icon) => find.descendant(
      of: find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ReaderPageLabels && w.page == page,
        ),
        matching: find.byType(ReaderFooter),
      ),
      matching: find.byIcon(icon),
    );
    // Pages 3 and 4 face each other. Turning like paper, the default on a
    // tablet, the spreads either side are built too, ready for a turn.
    for (final page in [3, 4]) {
      expect(
        find.byWidgetPredicate((w) => w is ReaderPageLabels && w.page == page),
        findsOneWidget,
      );
    }
    // Page 3 is on the right: "back" stays, "onward" (towards page 4) goes.
    expect(arrow(3, Icons.chevron_right_rounded), findsOneWidget);
    expect(arrow(3, Icons.chevron_left_rounded), findsNothing);
    // Page 4 is on the left: the other way round.
    expect(arrow(4, Icons.chevron_left_rounded), findsOneWidget);
    expect(arrow(4, Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('single-page layout stays single on a wide window', (
    tester,
  ) async {
    await _pump(
      tester,
      width: 1000,
      savedPage: 3,
      layout: ReaderPageLayout.single,
    );
    expect(find.byKey(const ValueKey<int>(3)).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(4)).hitTestable(), findsNothing);
  });

  testWidgets('the first spread is pages 1 on the right and 2 on the left', (
    tester,
  ) async {
    await _pump(tester, width: 1000);
    final right = tester
        .getCenter(find.byKey(const ValueKey<int>(1)).hitTestable())
        .dx;
    final left = tester
        .getCenter(find.byKey(const ValueKey<int>(2)).hitTestable())
        .dx;
    expect(right, greaterThan(left));
  });

  testWidgets('turning a spread saves its right-hand page', (tester) async {
    final (_, positions) = await _pump(tester, width: 1000);
    await tester.fling(find.byType(BookFlip), const Offset(500, 0), 1500);
    await tester.pumpAndSettle();
    expect(positions.page, 3);
  });

  testWidgets('one gesture turns one page at most', (tester) async {
    final (_, positions) = await _pump(tester);
    await tester.fling(find.byType(BookFlip), const Offset(600, 0), 4000);
    await tester.pumpAndSettle();
    expect(positions.page, 2);
  });

  testWidgets('dragging back to the left turns to the previous page', (
    tester,
  ) async {
    final (_, positions) = await _pump(tester, savedPage: 5);
    await tester.fling(find.byType(BookFlip), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(positions.page, 4);
  });

  testWidgets('a short slow drag springs back and keeps the page', (
    tester,
  ) async {
    final (_, positions) = await _pump(tester, savedPage: 5);
    final gesture = await tester.startGesture(const Offset(200, 400));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(positions.page, anyOf(isNull, 5));
    expect(find.byKey(const ValueKey<int>(5)).hitTestable(), findsOneWidget);
  });

  testWidgets('a narrow window shows one page', (tester) async {
    await _pump(tester, width: 400, savedPage: 3);
    expect(find.byKey(const ValueKey<int>(3)).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(2)).hitTestable(), findsNothing);
  });

  testWidgets('pressing and holding an ayah opens its actions', (tester) async {
    await _pump(tester);
    final paragraph = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('ٱلۡحَمۡدُ'),
    );
    expect(paragraph, findsOneWidget);
    // Press along the first column of the paragraph until a line of text is
    // under the finger, so the test does not depend on exact line positions.
    final topRight = tester.getTopRight(paragraph);
    for (var dy = 20.0; dy < 400; dy += 18) {
      await tester.longPressAt(topRight + Offset(-90, dy));
      await tester.pumpAndSettle();
      if (find.text('نسخ الآية').evaluate().isNotEmpty) break;
    }
    expect(find.text('نسخ الآية'), findsOneWidget);
    expect(find.text('إضافة علامة'), findsOneWidget);
  });
}
