import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/application/passage_text.dart';
import 'package:mre_quran/features/adhkar/domain/quran_passage.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';

QuranPassage _passage(List<(int, int, int)> spans, {bool istiadha = false}) =>
    QuranPassage(
      istiadha: istiadha,
      spans: [
        for (final (surah, from, to) in spans)
          AyahSpan(surah: surah, from: from, to: to),
      ],
    );

void main() {
  late QuranText text;

  setUpAll(() async {
    final container = ProviderContainer(
      overrides: [
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      ],
    );
    text = await container.read(quranTextProvider.future);
  });

  test('a mid-surah ayah is wrapped and has no basmala', () {
    final result = composePassage(_passage([(2, 255, 255)]), text);
    expect(result.startsWith('﴿'), isTrue);
    expect(result.endsWith('﴾'), isTrue);
    expect(result, isNot(contains(text.basmala)));
    expect(result, contains(text.uthmani(const AyahRef(2, 255))));
  });

  test('the isti\'adha comes first, once, only when asked', () {
    final with_ = composePassage(
      _passage([(2, 255, 255)], istiadha: true),
      text,
    );
    expect(with_.startsWith(Recitation.istiadha), isTrue);
    final without = composePassage(_passage([(2, 255, 255)]), text);
    expect(without, isNot(contains(Recitation.istiadha)));
  });

  test('a surah opening gets its basmala, each time', () {
    final result = composePassage(
      _passage([(112, 1, 4), (113, 1, 5), (114, 1, 6)], istiadha: true),
      text,
    );
    expect(text.basmala.allMatches(result), hasLength(3));
    expect(result.startsWith(Recitation.istiadha), isTrue);
    expect(
      result.indexOf(text.basmala),
      greaterThan(Recitation.istiadha.length),
    );
  });

  test('a range of ayahs is joined inside one pair of brackets', () {
    final result = composePassage(_passage([(2, 285, 286)]), text);
    expect('﴿'.allMatches(result), hasLength(1));
    expect(result, contains(text.uthmani(const AyahRef(2, 285))));
    expect(result, contains(text.uthmani(const AyahRef(2, 286))));
  });

  test('Al-Fatiha and At-Tawba get no extra basmala', () {
    expect(text.hasBasmala(1), isFalse);
    expect(text.hasBasmala(9), isFalse);
    expect(
      composePassage(_passage([(9, 1, 1)]), text),
      isNot(contains(text.basmala)),
    );
    // Al-Fatiha's basmala is its own first ayah, so it is there once.
    final fatiha = composePassage(_passage([(1, 1, 7)]), text);
    expect(text.basmala.allMatches(fatiha), hasLength(1));
  });

  test('describes spans by surah name and ayah numbers', () {
    String digits(int n) => '$n';
    final name2 = text.metadata.surah(2).arabicName;
    expect(
      describePassage(_passage([(2, 255, 255)]), text, digits),
      '$name2 255',
    );
    expect(
      describePassage(_passage([(2, 285, 286)]), text, digits),
      '$name2 285–286',
    );
  });
}
