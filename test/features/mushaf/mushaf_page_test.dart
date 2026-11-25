import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderClipRRect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
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
  bool realistic = false,
  ReaderPageLayout layout = ReaderPageLayout.auto,
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
            realisticPageTurn: realistic,
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
    await _pump(tester, savedPage: 5, realistic: true);
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
    expect(find.byType(ReaderPageLabels), findsNWidgets(2));
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
