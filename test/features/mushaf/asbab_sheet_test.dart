import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/ayah_actions_sheet.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/asbab_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/asbab.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_bookmarks_repository.dart';

final _asbab = Asbab(
  version: '2026-08-10',
  texts: const [
    'قال ابن عباس: نزلت ﴿ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ﴾ في سبب معروف.',
  ],
  index: {
    const AyahRef(112, 1): [0],
  },
);

Future<void> _open(WidgetTester tester, AyahRef ayah) async {
  final container = ProviderContainer(
    overrides: [
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      bookmarksRepositoryProvider.overrideWithValue(
        MemoryBookmarksRepository(),
      ),
      asbabProvider.overrideWith((ref) async => _asbab),
    ],
  );
  addTearDown(container.dispose);
  final text = await container.read(quranTextProvider.future);
  await container.read(quranMetadataProvider.future);
  await container.read(asbabProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAyahActions(
                context,
                HafsAyahTexts(text, fontFamily: 'KfgqpcHafs'),
                ayah,
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

void main() {
  testWidgets('an ayah\'s occasion opens as its tafsir does, and steps on', (
    tester,
  ) async {
    await _open(tester, const AyahRef(112, 1));
    await tester.ensureVisible(find.text('سبب النزول'));
    await tester.tap(find.text('سبب النزول'));
    await tester.pumpAndSettle();
    expect(find.text('أسباب النزول'), findsOneWidget);
    expect(find.textContaining('الإخلاص'), findsWidgets);
    expect(
      find.textContaining('قال ابن عباس', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('quranpedia.net'), findsOneWidget);
    // The next ayah has none: said plainly.
    await tester.tap(find.byTooltip('الآية التالية'));
    await tester.pumpAndSettle();
    expect(
      find.text('لا يوجد لدينا سبب نزول مسجَّل لهذه الآية.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an ayah with none still offers it, and says none is recorded', (
    tester,
  ) async {
    await _open(tester, const AyahRef(2, 254));
    expect(find.text('التفسير'), findsOneWidget);
    await tester.ensureVisible(find.text('سبب النزول'));
    await tester.tap(find.text('سبب النزول'));
    await tester.pumpAndSettle();
    expect(
      find.text('لا يوجد لدينا سبب نزول مسجَّل لهذه الآية.'),
      findsOneWidget,
    );
  });
}
