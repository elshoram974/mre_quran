import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/domain/mushaf_edition.dart';

void main() {
  test('every edition has its own id, download and manifest', () {
    final ids = {for (final e in MushafEditions.all) e.id};
    final groups = {for (final e in MushafEditions.all) e.downloadGroup};
    expect(ids, hasLength(MushafEditions.all.length));
    expect(groups, hasLength(MushafEditions.all.length));
    for (final edition in MushafEditions.all) {
      expect(
        File(edition.manifestAsset).existsSync(),
        isTrue,
        reason: '$edition',
      );
      expect(edition.manifestSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(edition.names['ar'], isNotEmpty);
    }
  });

  test('the bundled manifests are all listed in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final edition in MushafEditions.all) {
      expect(
        pubspec,
        contains('- ${edition.manifestAsset}'),
        reason: '$edition',
      );
    }
  });

  test('Hafs is the default and the only one tied to the app text', () {
    expect(MushafEditions.all.first, MushafEditions.hafs);
    expect(
      [
        for (final e in MushafEditions.all)
          if (e.matchesAppText) e,
      ],
      [MushafEditions.hafs],
    );
    // A download begun before there were several editions is still found.
    expect(MushafEditions.hafs.downloadGroup, 'mushaf-svg');
  });

  test('a name falls back to Arabic, and an unknown id finds nothing', () {
    expect(MushafEditions.warsh.name('fr'), 'ورش عن نافع');
    expect(MushafEditions.warsh.name('en'), "Warsh from Nafi'");
    expect(MushafEditions.byId('warsh-kfqc'), MushafEditions.warsh);
    expect(MushafEditions.byId('nope'), isNull);
  });
}
