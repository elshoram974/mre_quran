import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/core/haptics/haptics.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';

import '../helpers/adhkar_fixtures.dart';
import '../helpers/fake_quran_metadata_source.dart';
import '../helpers/fake_quran_text_source.dart';
import '../helpers/memory_bookmarks_repository.dart';
import '../helpers/memory_last_tab_repository.dart';
import '../helpers/memory_reading_position_repository.dart';
import '../helpers/memory_settings_repository.dart';

class _NoMotor extends RecordingHaptics {
  @override
  Future<bool> isSupported() async => false;
}

void main() {
  final original = Haptics.backend;

  tearDown(() {
    Haptics.backend = original;
    Haptics.enabled = true;
  });

  Future<MemorySettingsRepository> pumpSettings(
    WidgetTester tester, {
    required HapticsBackend backend,
  }) async {
    Haptics.backend = backend;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemorySettingsRepository()
      ..settings = const AppSettings(
        hapticsEnabled: false,
        readerMode: ReaderMode.text,
        editionsIntroSeen: true,
      );
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
        initialLocationProvider.overrideWithValue('/settings'),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
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
    return repository;
  }

  testWidgets(
    'the app follows the vibration setting, and the switch changes it',
    (tester) async {
      final repository = await pumpSettings(
        tester,
        backend: RecordingHaptics(),
      );
      expect(Haptics.enabled, isFalse);

      await tester.scrollUntilVisible(
        find.text('الاهتزاز'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Past the floating tab bar.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الاهتزاز'));
      await tester.pumpAndSettle();
      expect(Haptics.enabled, isTrue);
      expect(repository.settings.hapticsEnabled, isTrue);
    },
  );

  testWidgets('a device that cannot vibrate gets a switch that says so', (
    tester,
  ) async {
    final repository = await pumpSettings(tester, backend: _NoMotor());
    await tester.scrollUntilVisible(
      find.text('هذا الجهاز لا يدعم الاهتزاز.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الاهتزاز'));
    await tester.pumpAndSettle();
    expect(repository.settings.hapticsEnabled, isFalse);
  });
}
