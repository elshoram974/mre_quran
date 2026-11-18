import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/data/kfgqpc_hafs_parser.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_search.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';

void main() {
  late QuranMetadata metadata;
  late QuranTextData data;
  late QuranText text;
  late AyahSearchIndex search;
  final file = File(QuranTextSource.mushafAsset);
  late QuranSearchKeys keys;

  setUpAll(() async {
    metadata = QuranMetadataParser.parse(
      File(QuranMetadataSource.assetPath).readAsStringSync(),
    );
    data = QuranTextSource.parse((
      uthmani: File(QuranTextSource.uthmaniAsset).readAsBytesSync(),
      clean: File(QuranTextSource.cleanAsset).readAsBytesSync(),
      mushaf: file.readAsBytesSync(),
      counts: [for (final s in metadata.surahs) s.ayahCount],
    ));
    text = QuranText(
      metadata: metadata,
      uthmani: data.uthmani,
      clean: data.clean,
      basmala: data.basmala,
      prefixed: data.prefixed,
      mushaf: data.mushaf,
      marks: data.marks,
    );
    keys = await buildQuranSearchKeys(data);
    search = AyahSearchIndex(
      text: text,
      keys: keys.keys,
      uthmaniKeys: keys.uthmaniKeys,
      plainKeys: keys.plainKeys,
    );
  });

  group('King Fahd Complex data', () {
    test('the bundled file and font match their recorded SHA-256', () {
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        QuranTextSource.mushafSha256,
      );
      expect(
        sha256
            .convert(
              File('assets/fonts/kfgqpc_hafs/uthmanic_hafs_v20.ttf')
                  .readAsBytesSync(),
            )
            .toString(),
        'd560bbbc7a90a4f4d416d206a5ac48bd8a1ad00273d64d232f16ca54941bd041',
      );
    });

    test('holds every ayah with its text and its number glyph', () {
      expect(data.mushaf, hasLength(6236));
      expect(data.marks, hasLength(6236));
      for (var i = 0; i < data.mushaf.length; i++) {
        expect(data.mushaf[i].trim(), isNotEmpty);
        expect(data.marks[i], isNotEmpty);
        // The glyph is separated out, never left inside the ayah.
        expect(data.mushaf[i].contains(' ${data.marks[i]}'), isFalse);
      }
    });

    test('the text is the source’s own, cut only at the number glyph', () {
      final rows = file.readAsLinesSync().skip(1).toList();
      for (final index in [0, 7, 261, 292, 6235]) {
        expect(
          rows[index].split('\t')[9],
          '${data.mushaf[index]} ${data.marks[index]}',
        );
      }
    });

    test('rejects a file with a missing or misplaced ayah', () {
      final lines = file.readAsLinesSync();
      final counts = [for (final s in metadata.surahs) s.ayahCount];
      expect(
        () => KfgqpcHafsParser.parse(
          [...lines.take(5), ...lines.skip(6)].join('\n'),
          counts,
        ),
        throwsFormatException,
      );
      expect(
        () => KfgqpcHafsParser.parse(lines.take(100).join('\n'), counts),
        throwsFormatException,
      );
    });
  });

  group('Mushaf script in QuranText', () {
    test('the reader gets the Mushaf script; copying keeps Tanzil', () {
      const kursi = AyahRef(2, 255);
      expect(text.hasMushafScript, isTrue);
      expect(text.mushaf(kursi), data.mushaf[text.indexOf(kursi)]);
      expect(text.uthmani(kursi), data.uthmani[text.indexOf(kursi)]);
      expect(text.mushaf(kursi), isNot(text.uthmani(kursi)));
      expect(text.mark(kursi), isNotNull);
    });

    test('the basmala is ayah 1:1 without its number', () {
      expect(text.mushafBasmala, data.mushaf.first);
    });

    test('without the script it falls back to the Tanzil text', () {
      final plain = QuranText(
        metadata: metadata,
        uthmani: data.uthmani,
        clean: data.clean,
        basmala: data.basmala,
        prefixed: data.prefixed,
      );
      const ref = AyahRef(1, 2);
      expect(plain.hasMushafScript, isFalse);
      expect(plain.mushaf(ref), plain.uthmani(ref));
      expect(plain.mark(ref), isNull);
      expect(plain.mushafBasmala, plain.basmala);
    });

    test('a script of the wrong length is rejected', () {
      expect(
        () => QuranText(
          metadata: metadata,
          uthmani: data.uthmani,
          clean: data.clean,
          basmala: data.basmala,
          prefixed: data.prefixed,
          mushaf: data.mushaf.take(10).toList(),
          marks: data.marks.take(10).toList(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('search ranking', () {
    // Whole in any of the three spellings, as the index ranks it.
    bool wholeWord(AyahRef ref, String word) {
      final i = text.indexOf(ref);
      return [
        keys.keys[i],
        keys.uthmaniKeys[i],
        keys.plainKeys[i],
      ].any((key) => ' $key '.contains(' $word '));
    }

    test('whole-word matches come before matches inside longer words', () {
      final result = search.search('من', limit: 7000);
      final refs = [for (final match in result.matches) match.ref];
      final firstPartial = refs.indexWhere((ref) => !wholeWord(ref, 'من'));
      expect(firstPartial, greaterThan(0), reason: 'both kinds exist');
      // Every whole-word ayah sits before the first
      // ayah that only holds the letters inside another word.
      for (var i = firstPartial; i < refs.length; i++) {
        expect(wholeWord(refs[i], 'من'), isFalse, reason: '${refs[i]}');
      }
    });

    test('each group keeps Quran order', () {
      final refs = [
        for (final match in search.search('الرحمن', limit: 7000).matches)
          text.indexOf(match.ref),
      ];
      final whole = refs.takeWhile(
        (i) => ' ${keys.keys[i]} '.contains(' الرحمن '),
      );
      expect(whole, orderedEquals([...whole]..sort()));
    });

    test('repeated spaces in the query do not break a phrase', () {
      final tidy = search.search('الحمد لله رب العالمين');
      final messy = search.search('  الحمد   لله  رب العالمين ');
      expect(messy.total, tidy.total);
      expect(messy.matches.first.ref, const AyahRef(1, 2));
    });

    test('the Complex’s plain spelling is searchable', () {
      final index = text.indexOf(const AyahRef(2, 255));
      final phrase = keys.plainKeys[index].split(' ').take(4).join(' ');
      final refs = [for (final m in search.search(phrase).matches) m.ref];
      expect(refs, contains(const AyahRef(2, 255)));
    });
  });
}
