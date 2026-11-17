import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_ornaments.dart';
import 'package:mre_quran/features/mushaf/presentation/surah_banner.dart';
import 'package:mre_quran/features/mushaf/presentation/surah_frame_field.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/memory_settings_repository.dart';

void main() {
  Future<MemorySettingsRepository> pump(
    WidgetTester tester, {
    String locale = 'ar',
    ThemeData? theme,
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = MemorySettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            locale: Locale(locale),
            theme: theme ?? AppTheme.light,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsetsDirectional.all(16),
                child: SurahFrameField(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('shows every frame, the saved one selected, and saves a tap', (
    tester,
  ) async {
    final settings = await pump(tester);
    expect(find.text('إطار اسم السورة'), findsOneWidget);
    for (final name in ['مُدبَّب', 'كلاسيكي', 'مُقوَّس', 'بسيط']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('مُدبَّب')),
      isSemantics(isButton: true, isSelected: true),
    );
    await tester.tap(find.text('مُقوَّس'));
    await tester.pumpAndSettle();
    expect(settings.settings.surahFrame, SurahFrameStyle.arch);
    expect(
      tester.getSemantics(find.bySemanticsLabel('مُقوَّس')),
      isSemantics(isButton: true, isSelected: true),
    );
  });

  testWidgets('reads in English, dark, at large text and on wide screens', (
    tester,
  ) async {
    await pump(tester, locale: 'en', theme: AppTheme.dark, textScale: 2);
    expect(find.text('Surah name frame'), findsOneWidget);
    expect(find.text('Scalloped'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Two to a row on a phone, all four in one row where they fit.
    double rows() => {
      for (final name in ['Pointed', 'Classic', 'Scalloped', 'Simple'])
        tester.getTopLeft(find.text(name)).dy.round(),
    }.length.toDouble();
    expect(rows(), 2);
    await pump(tester, locale: 'en', width: 900);
    expect(rows(), 1);
  });

  testWidgets('every frame draws, with or without the name written in it', (
    tester,
  ) async {
    final metadata = QuranMetadataParser.parse(
      File('assets/quran/quran-data.xml').readAsStringSync(),
    );
    for (final style in SurahFrameStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Column(
            children: [
              for (final showTitle in [true, false])
                SizedBox(
                  width: 360,
                  height: 56,
                  child: SurahBanner(
                    surah: metadata.surah(36),
                    number: (n) => '$n',
                    style: style,
                    showTitle: showTitle,
                    nameWidth: showTitle ? 0 : 90,
                  ),
                ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: style.name);
    }
  });

  test('the plaque holds a printed name of any width the frame allows', () {
    const size = Size(360, 40);
    for (final style in SurahFrameStyle.values) {
      final small = SurahFrameGeometry.plaque(size, style);
      final wide = SurahFrameGeometry.plaque(size, style, nameWidth: 200);
      expect(small.center, size.center(Offset.zero), reason: style.name);
      expect(wide.width, greaterThan(200), reason: style.name);
      expect(wide.width, lessThanOrEqualTo(size.width), reason: style.name);
      final name = SurahFrameGeometry.name(size, style);
      expect(small.contains(name.center), isTrue, reason: style.name);
    }
  });
}
