import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/ayah_selection_provider.dart';
import 'package:mre_quran/features/mushaf/domain/mushaf_edition.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_range.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';

/// The real ayah counts, without the words: all a selection needs.
class _Counts implements AyahTexts {
  _Counts(this.metadata);

  @override
  final QuranMetadata metadata;

  @override
  int ayahCount(int surah) => metadata.surah(surah).ayahCount;

  @override
  bool has(AyahRef ref) => true;

  @override
  String copy(AyahRef ref) => '';

  @override
  String display(AyahRef ref) => '';

  @override
  String? mark(AyahRef ref) => null;

  @override
  int pageOf(AyahRef ref) => metadata.pageOf(ref.surah, ref.ayah);

  @override
  String get fontFamily => 'KfgqpcHafs';
}

void main() {
  final texts = _Counts(
    QuranMetadataParser.parse(
      File('assets/quran/quran-data.xml').readAsStringSync(),
    ),
  );

  late ProviderContainer container;
  AyahSelectionNotifier notifier() =>
      container.read(ayahSelectionProvider.notifier);
  AyahRange? range() => container.read(ayahSelectionProvider)?.range;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts on the ayah pressed and grows to the one tapped, across '
      'surahs', () {
    notifier().start(MushafEditions.hafs, texts, const AyahRef(2, 285));
    expect(range(), const AyahRange.single(AyahRef(2, 285)));
    expect(notifier().extendTo(const AyahRef(3, 3), limit: 50), isTrue);
    expect(range(), const AyahRange(AyahRef(2, 285), AyahRef(3, 3)));
  });

  test('an ayah before the first one makes it the end', () {
    notifier().start(MushafEditions.hafs, texts, const AyahRef(3, 2));
    notifier().extendTo(const AyahRef(2, 284), limit: 50);
    expect(range(), const AyahRange(AyahRef(2, 284), AyahRef(3, 2)));
    // Back past the first ayah: it is the start again.
    notifier().extendTo(const AyahRef(3, 5), limit: 50);
    expect(range(), const AyahRange(AyahRef(3, 2), AyahRef(3, 5)));
  });

  test('stops at the limit, in the direction tapped, and says so', () {
    notifier().start(MushafEditions.hafs, texts, const AyahRef(2, 280));
    expect(notifier().extendTo(const AyahRef(3, 100), limit: 10), isFalse);
    expect(range(), const AyahRange(AyahRef(2, 280), AyahRef(3, 3)));
    expect(notifier().extendTo(const AyahRef(1, 1), limit: 10), isFalse);
    expect(range(), const AyahRange(AyahRef(2, 271), AyahRef(2, 280)));
  });

  test('clears', () {
    notifier().start(MushafEditions.hafs, texts, const AyahRef(1, 1));
    notifier().clear();
    expect(container.read(ayahSelectionProvider), isNull);
  });
}
