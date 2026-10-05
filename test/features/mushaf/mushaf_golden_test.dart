import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/reader_immersive_provider.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page_view.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_text_source.dart';

/// Golden pages from the plan: 1, 2, 42 (Ayat al-Kursi), and 604, in light
/// and dark. Rendered with the bundled Amiri Quran font.
void main() {
  late QuranText text;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('AmiriQuran')
      ..addFont(
        rootBundle.load('assets/fonts/amiri_quran/AmiriQuran-Regular.ttf'),
      );
    await loader.load();
    final metadata = QuranMetadataParser.parse(
      File('assets/quran/quran-data.xml').readAsStringSync(),
    );
    final data = await FakeQuranTextSource().load([
      for (final s in metadata.surahs) s.ayahCount,
    ]);
    text = QuranText(
      metadata: metadata,
      uthmani: data.uthmani,
      clean: data.clean,
      basmala: data.basmala,
      prefixed: data.prefixed,
    );
  });

  for (final page in [1, 2, 42, 604]) {
    for (final (name, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      testWidgets('page $page, $name', (tester) async {
        tester.view.physicalSize = const Size(430 * 2, 760 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Page labels show while the reader's bars are hidden.
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(readerImmersiveProvider.notifier).toggle();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme,
              locale: const Locale('ar'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: MushafPageView(
                  text: text,
                  page: page,
                  fontScale: 1,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MushafPageView),
          matchesGoldenFile('goldens/page_${page}_$name.png'),
        );
      });
    }
  }
}
