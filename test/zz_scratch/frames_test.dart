// SCRATCH: renders real pages with each frame style. Deleted after use.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_compiler.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/presentation/svg_page_view.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../helpers/memory_settings_repository.dart';

const out = '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/frames';
final jobs = [
  ('qalon', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/qalon-svg/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/qalon', 267, false),
  ('warsh', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/warsh-svg/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/warsh', 520, true),
  ('hafs', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/x/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/j', 187, true),
  ('hafs', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/x/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/j', 50, true),
  ('hafs', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/x/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/j', 496, true),
  ('hafs', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/x/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/all/j', 604, true),
  ('qalon', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/qalon-svg/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/qalon', 528, false),
  ('warsh', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/warsh-svg/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/warsh', 604, true),
  ('douri', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/douri-svg/svg', '/private/tmp/claude-501/-Users-mohammedelshora-Desktop-Shora-projects-mrecode-mre-quran/d446a615-996b-40e8-a911-634fd6cd28e7/scratchpad/riw/douri', 293, false),
];

void main() {
  final metadata = QuranMetadataParser.parse(File('assets/quran/quran-data.xml').readAsStringSync());
  Directory(out).createSync(recursive: true);
  for (final (name, svgs, jsons, page, ordered) in jobs) {
    for (final style in SurahFrameStyle.values) {
      testWidgets('$name $page ${style.name}', (tester) async {
        tester.view.physicalSize = const Size(390, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final file = page.toString().padLeft(3, '0');
        final parsed = SvgPageParser.page(page, svg: File('$svgs/$file.svg').readAsStringSync(), json: File('$jsons/$file.json').readAsStringSync(), ordered: ordered);
        final key = GlobalKey();
        await tester.runAsync(() async {
          await tester.pumpWidget(ProviderScope(
            overrides: [
              svgPageProvider.overrideWith((ref, request) async => SvgPagePicture_(parsed, request.stretch / 1000)),
              settingsRepositoryProvider.overrideWithValue(MemorySettingsRepository()..settings = AppSettings(surahFrame: style)),
            ],
            child: MaterialApp(
              locale: const Locale('ar'),
              theme: AppTheme.light,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: appLocalizationsDelegates,
              home: Scaffold(body: RepaintBoundary(key: key, child: ColoredBox(color: const Color(0xFFF6F0E2), child: SvgPageView(metadata: metadata, page: page, onTap: () {}, fillWidth: true)))),
            ),
          ));
          for (var i = 0; i < 60; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 100));
          }
          debugPrint('DBG svg pictures: ${find.byType(SvgPicture).evaluate().length}');
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.6);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$out/$name-$page-${style.name}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}

// ignore: non_constant_identifier_names
SvgPagePicture_(page, double stretch) => SvgPageCompiler.compile(page, stretch: stretch);
