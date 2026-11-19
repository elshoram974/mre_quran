import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/bookmarks/presentation/bookmarks_page.dart';
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

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = MemorySettingsRepository();
  repository.settings = repository.settings.copyWith(
    reduceMotion: reduceMotion,
  );
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
      initialLocationProvider.overrideWithValue('/reader'),
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
  testWidgets('tab changes fade in and ignore taps on the outgoing tab', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.bookmarks_outlined).first);
    await tester.pump();
    final page = find.byType(BookmarksPage);
    final opacity = find
        .ancestor(of: page, matching: find.byType(AnimatedOpacity))
        .first;
    final fade = find
        .descendant(of: opacity, matching: find.byType(FadeTransition))
        .first;
    expect(tester.widget<FadeTransition>(fade).opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      inExclusiveRange(0.0, 1.0),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    expect(find.text('لا توجد علامات بعد').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab changes are immediate when motion is reduced', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844), reduceMotion: true);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmarks_outlined).first);
    await tester.pumpAndSettle();
    final page = find.byType(BookmarksPage);
    final opacity = find
        .ancestor(of: page, matching: find.byType(AnimatedOpacity))
        .first;
    expect(tester.widget<AnimatedOpacity>(opacity).duration, Duration.zero);
    expect(find.text('لا توجد علامات بعد').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the floating bar tabs can be activated by assistive tech', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const Size(390, 844));
    for (final label in ['المصحف', 'العلامات']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isButton: true, hasTapAction: true),
      );
    }
    // Activating a tab through its semantics, not a pointer, switches to it.
    tester.semantics.tap(find.semantics.byLabel('العلامات'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد علامات بعد').hitTestable(), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a phone gets the floating bar', (tester) async {
    await _pump(tester, const Size(390, 844));
    expect(find.byType(ExpandingNavBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('a portrait iPad keeps the bar, centred and not stretched', (
    tester,
  ) async {
    await _pump(tester, const Size(820, 1180));
    expect(find.byType(NavigationRail), findsNothing);
    final bar = tester.getSize(find.byType(ExpandingNavBar));
    expect(bar.width, lessThanOrEqualTo(560));
    expect(tester.getCenter(find.byType(ExpandingNavBar)).dx, closeTo(410, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide window moves the tabs into a rail', (tester) async {
    await _pump(tester, const Size(1194, 834));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(ExpandingNavBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on iOS an iPad gets a centred glass bar upright, a rail wide', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await _pump(tester, const Size(820, 1180));
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.getSize(find.byType(GlassTabBar)).width,
      lessThanOrEqualTo(560),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await _pump(tester, const Size(1194, 834));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(GlassTabBar), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
