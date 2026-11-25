import 'dart:convert';

import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';

/// One occasion of revelation and the ayahs it is about.
@immutable
class AsbabPassage {
  /// Creates the passage.
  const AsbabPassage(this.text, this.ayahs);

  /// What Al-Wahidi narrates, word for word; the ayahs it quotes are inside
  /// ﴿ ﴾.
  final String text;

  /// The ayahs (Hafs numbering) it is about, in order.
  final List<AyahRef> ayahs;
}

/// Al-Wahidi's «أسباب نزول القرآن»: the occasions of revelation of the ayahs
/// that have one, by ayah in the Hafs numbering. A passage about several ayahs
/// is kept once.
@immutable
class Asbab {
  /// Creates the book from its passages and which ayahs each serves.
  Asbab({
    required this.version,
    required List<String> texts,
    required Map<AyahRef, List<int>> index,
  }) : _texts = List.unmodifiable(texts),
       _index = Map.unmodifiable(index);

  /// Reads the bundled file's JSON (see `tool/build_asbab.py`).
  factory Asbab.parse(String json) {
    final root = jsonDecode(json) as Map<String, Object?>;
    final texts = [
      for (final text in root['texts']! as List<Object?>) text! as String,
    ];
    final index = <AyahRef, List<int>>{};
    for (final entry in root['ayahs']! as List<Object?>) {
      final [surah, ayah, refs] = entry! as List<Object?>;
      index[AyahRef(surah! as int, ayah! as int)] = [
        for (final ref in refs! as List<Object?>) ref! as int,
      ];
    }
    return Asbab(
      version: root['version']! as String,
      texts: texts,
      index: index,
    );
  }

  /// The version of the source's data.
  final String version;

  final List<String> _texts;
  final Map<AyahRef, List<int>> _index;

  /// Whether [ayah] has an occasion of revelation.
  bool has(AyahRef ayah) => _index.containsKey(ayah);

  /// The ayahs of [surah] that have one, in order.
  List<AyahRef> inSurah(int surah) => [
    for (final ayah in _index.keys)
      if (ayah.surah == surah) ayah,
  ]..sort();

  /// The passages about [ayahs], each once, in the order they first come,
  /// with the ayahs of [ayahs] each is about.
  List<AsbabPassage> passages(Iterable<AyahRef> ayahs) {
    final order = <int>[];
    final about = <int, List<AyahRef>>{};
    for (final ayah in [...ayahs]..sort()) {
      for (final number in _index[ayah] ?? const <int>[]) {
        if (!about.containsKey(number)) order.add(number);
        (about[number] ??= []).add(ayah);
      }
    }
    return [
      for (final number in order) AsbabPassage(_texts[number], about[number]!),
    ];
  }
}
