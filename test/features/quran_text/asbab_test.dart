import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/asbab_provider.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';
import 'package:mre_quran/features/quran_text/domain/asbab.dart';

void main() {
  group('the bundled occasions of revelation', () {
    final bytes = File(AsbabAsset.path).readAsBytesSync();
    final asbab = decodeAsbab(bytes);

    test('are the recorded file', () {
      expect(sha256.convert(bytes).toString(), AsbabAsset.sha256Hex);
    });

    test('cover the ayahs Al-Wahidi records, by Quranpedia\'s version', () {
      expect(asbab.version, '2026-08-10');
      var count = 0;
      for (var surah = 1; surah <= 114; surah++) {
        count += asbab.inSurah(surah).length;
      }
      expect(count, 564);
      // Al-Baqarah 1–2 share one passage, about the first ayahs.
      final opening = asbab.passages(const [AyahRef(2, 1), AyahRef(2, 2)]);
      expect(opening, hasLength(1));
      expect(opening.single.ayahs, const [AyahRef(2, 1), AyahRef(2, 2)]);
      expect(opening.single.text, contains('﴿'));
    });

    test('keep the words and drop only the markup', () {
      for (var surah = 1; surah <= 114; surah++) {
        for (final passage in asbab.passages(asbab.inSurah(surah))) {
          expect(passage.text, isNot(contains('<')), reason: '$surah');
          expect(passage.text.trim(), passage.text);
        }
      }
    });

    test('a damaged file is refused', () {
      final damaged = Uint8List.fromList(bytes)..[100] ^= 1;
      expect(
        () => decodeAsbab(damaged),
        throwsA(isA<QuranTextIntegrityException>()),
      );
    });
  });

  test('a passage about several ayahs is shown once, under them all', () {
    final asbab = Asbab(
      version: 'v',
      texts: const ['first', 'second'],
      index: {
        const AyahRef(3, 2): [0],
        const AyahRef(3, 1): [0, 1],
        const AyahRef(4, 1): [1],
      },
    );
    final passages = asbab.passages(const [AyahRef(3, 2), AyahRef(3, 1)]);
    expect([for (final p in passages) p.text], ['first', 'second']);
    expect(passages.first.ayahs, const [AyahRef(3, 1), AyahRef(3, 2)]);
    expect(asbab.has(const AyahRef(4, 1)), isTrue);
    expect(asbab.has(const AyahRef(4, 2)), isFalse);
    expect(asbab.inSurah(3), const [AyahRef(3, 1), AyahRef(3, 2)]);
  });
}
