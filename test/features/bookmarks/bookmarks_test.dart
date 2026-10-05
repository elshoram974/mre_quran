import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/bookmarks/domain/bookmark.dart';
import 'package:mre_quran/features/bookmarks/presentation/bookmarks_page.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_actions_sheet.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_bookmarks_repository.dart';
import '../../helpers/memory_reading_position_repository.dart';

ProviderContainer _container(MemoryBookmarksRepository repo) {
  final container = ProviderContainer(
    overrides: [
      bookmarksRepositoryProvider.overrideWithValue(repo),
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      readingPositionRepositoryProvider.overrideWithValue(
        MemoryReadingPositionRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('BookmarksNotifier', () {
    test('toggle adds, then removes, and saves each change', () async {
      final repo = MemoryBookmarksRepository();
      final container = _container(repo);
      await container.read(bookmarksProvider.future);
      final notifier = container.read(bookmarksProvider.notifier);

      await notifier.toggle(const AyahRef(2, 255));
      expect(container.read(bookmarkedRefsProvider), {const AyahRef(2, 255)});
      expect(repo.items, hasLength(1));

      await notifier.toggle(const AyahRef(2, 255));
      expect(container.read(bookmarkedRefsProvider), isEmpty);
      expect(repo.items, isEmpty);
    });

    test(
      'shows the change before saving finishes and rolls back on failure',
      () async {
        final repo = MemoryBookmarksRepository()..fail = true;
        final container = _container(repo);
        await container.read(bookmarksProvider.future);
        await container
            .read(bookmarksProvider.notifier)
            .toggle(const AyahRef(1, 1));
        expect(container.read(bookmarkedRefsProvider), isEmpty);
      },
    );
  });

  group('Bookmark', () {
    test('round-trips and ignores unreadable data', () {
      final bookmark = Bookmark(
        ref: const AyahRef(36, 1),
        createdAt: DateTime.utc(2026, 10, 5),
      );
      final back = Bookmark.tryFromJson(bookmark.toJson());
      expect(back?.ref, bookmark.ref);
      expect(back?.createdAt, bookmark.createdAt);
      expect(Bookmark.tryFromJson('nope'), isNull);
      expect(Bookmark.tryFromJson({'s': 'x'}), isNull);
    });
  });

  testWidgets('copy puts the ayah and its reference on the clipboard', (
    tester,
  ) async {
    String? copied;
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
    final container = _container(MemoryBookmarksRepository());
    final text = await container.read(quranTextProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showAyahActions(context, text, const AyahRef(2, 255)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('البقرة · آية ٢٥٥'), findsOneWidget);
    await tester.tap(find.text('نسخ الآية'));
    await tester.pumpAndSettle();
    expect(copied, ayahWithReference(text, const AyahRef(2, 255)));
    expect(copied, startsWith('﴿'));
    expect(copied, endsWith('﴾ [البقرة: 255]'));
    expect(find.text('تم نسخ الآية'), findsOneWidget);
  });

  testWidgets('bookmarking from the sheet shows it on the bookmarks page', (
    tester,
  ) async {
    final repo = MemoryBookmarksRepository();
    final container = _container(repo);
    final text = await container.read(quranTextProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  TextButton(
                    onPressed: () =>
                        showAyahActions(context, text, const AyahRef(2, 255)),
                    child: const Text('open'),
                  ),
                  const Expanded(child: BookmarksPage()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا توجد علامات بعد'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة علامة'));
    await tester.pumpAndSettle();
    expect(repo.items.single.ref, const AyahRef(2, 255));
    expect(find.text('البقرة · آية ٢٥٥'), findsOneWidget);
    expect(find.text('لا توجد علامات بعد'), findsNothing);
  });
}
