import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';

import '../helpers/fake_quran_metadata_source.dart';
import '../helpers/fake_quran_text_source.dart';
import '../helpers/memory_bookmarks_repository.dart';
import '../helpers/memory_last_tab_repository.dart';
import '../helpers/memory_reading_position_repository.dart';
import '../helpers/memory_settings_repository.dart';

Future<void> _pump(WidgetTester tester, {String? lastTab}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(MemorySettingsRepository()),
      lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
      initialLocationProvider.overrideWithValue(lastTab ?? '/reader'),
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      readingPositionRepositoryProvider.overrideWithValue(
        MemoryReadingPositionRepository(),
      ),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      bookmarksRepositoryProvider.overrideWithValue(
        MemoryBookmarksRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const QuranApp()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('back on another tab returns to the Mushaf, not out of the app', (
    tester,
  ) async {
    var exited = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exited = true;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, lastTab: '/bookmarks');
    expect(find.text('لا توجد علامات بعد'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('لا توجد علامات بعد'), findsNothing);
    expect(find.text('إغلاق التطبيق؟'), findsNothing);
    expect(exited, isFalse);
  });

  testWidgets('back on the Mushaf asks before closing; stay keeps the app', (
    tester,
  ) async {
    var exited = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exited = true;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('إغلاق التطبيق؟'), findsOneWidget);
    expect(exited, isFalse);

    await tester.tap(find.text('البقاء'));
    await tester.pumpAndSettle();
    expect(find.text('إغلاق التطبيق؟'), findsNothing);
    expect(exited, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    expect(exited, isTrue);
  });
}
