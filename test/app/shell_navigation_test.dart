import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
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

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(MemorySettingsRepository()),
      lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
      initialLocationProvider.overrideWithValue('/bookmarks'),
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
