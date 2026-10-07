import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/reader_immersive_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';
import 'package:mre_quran/features/mushaf/presentation/reader_bar.dart';
import 'package:mre_quran/features/mushaf/presentation/reader_page_labels.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_bookmarks_repository.dart';
import '../../helpers/memory_reading_position_repository.dart';
import '../../helpers/memory_settings_repository.dart';

Future<(ProviderContainer, MemoryReadingPositionRepository)> _pump(
  WidgetTester tester, {
  int? savedPage,
  String locale = 'ar',
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final positions = MemoryReadingPositionRepository()..page = savedPage;
  final container = ProviderContainer(
    overrides: [
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      bookmarksRepositoryProvider.overrideWithValue(
        MemoryBookmarksRepository(),
      ),
      readingPositionRepositoryProvider.overrideWithValue(positions),
      settingsRepositoryProvider.overrideWithValue(
        MemorySettingsRepository()..settings = AppSettings(localeCode: locale),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    // The surah button of the floating controls, and the page pill.
    expect(find.text('الفاتحة').hitTestable(), findsOneWidget);
    expect(find.text('صفحة ١'), findsOneWidget, reason: 'page pill');
    expect(find.bySemanticsLabel('ابحث في القرآن'), findsOneWidget);
    for (final tip in ['إضافة علامة للصفحة', 'العرض', 'إخفاء الأشرطة']) {
      expect(find.byTooltip(tip), findsOneWidget, reason: tip);
    }
    // The page's own labels step aside while the bars show.
    expect(find.text('الجزء ١').hitTestable(), findsNothing);
  });

  testWidgets('hiding the bars leaves the page number and the arrow', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);
    await tester.tap(find.byTooltip('إخفاء الأشرطة'));
    await tester.pumpAndSettle();
    expect(container.read(readerImmersiveProvider), isTrue);
    expect(find.text('الجزء ١').hitTestable(), findsOneWidget);
    expect(find.text('١').hitTestable(), findsOneWidget);
    expect(find.byTooltip('الصفحة التالية').hitTestable(), findsOneWidget);
    expect(find.bySemanticsLabel('ابحث في القرآن').hitTestable(), findsNothing);
  });

  testWidgets('the surah, juz, and page number are part of the page itself', (
    tester,
  ) async {
    await _pump(tester, savedPage: 5);
    // Inside each page's own subtree, so the turning sheet carries them.
    for (final number in [4, 5, 6]) {
      final labels = find.descendant(
        of: find.byKey(ValueKey<int>(number)),
        matching: find.byType(ReaderPageLabels),
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
    await tester.tap(find.byTooltip('الصفحة التالية').hitTestable());
    await tester.pumpAndSettle();
    expect(positions.page, 6);
    container.read(readerImmersiveProvider.notifier).hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('السورة التالية').hitTestable());
    await tester.pumpAndSettle();
    // Al-Baqarah is followed by Al Imran, which starts on page 50.
    expect(positions.page, 50);
  });

  testWidgets('the page pill opens a slider and goes to the chosen page', (
    tester,
  ) async {
    final (_, positions) = await _pump(tester, savedPage: 10);
    await tester.tap(find.byType(ReaderPagePill));
    await tester.pumpAndSettle();
    expect(find.text('صفحة ١٠ من ٦٠٤'), findsOneWidget);
    // The slider runs right to left: the left end is the last page.
    final slider = tester.getRect(find.byType(Slider));
    await tester.tapAt(Offset(slider.left + 24, slider.center.dy));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتقال'));
    await tester.pumpAndSettle();
    expect(positions.page, greaterThan(550));
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
      (w) => w is RichText && w.text.toPlainText().contains('ٱلْحَمْدُ'),
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
