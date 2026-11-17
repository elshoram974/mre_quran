import '../../quran_index/domain/quran_metadata.dart';
import 'quran_text.dart';

/// The words of a printed Mushaf's ayahs, as one reading writes them: what
/// is copied and shared from a page of that reading.
abstract interface class AyahTexts {
  /// Surah names and order, the same in every reading.
  QuranMetadata get metadata;

  /// How many ayahs [surah] has in this reading.
  int ayahCount(int surah);

  /// Whether this reading's text of [ref] can be given. False where the
  /// reading's text and its printed pages count an ayah differently.
  bool has(AyahRef ref);

  /// The ayah with its tashkeel, to copy or send as text.
  String copy(AyahRef ref);

  /// The ayah as it is drawn in [fontFamily].
  String display(AyahRef ref);

  /// The ayah's number as [fontFamily] draws it after the ayah, or null
  /// when it has none.
  String? mark(AyahRef ref);

  /// The page of this reading's printed Mushaf the ayah starts on.
  int pageOf(AyahRef ref);

  /// The font that draws [display] and [mark].
  String get fontFamily;
}

/// Hafs, from the app's verified text.
class HafsAyahTexts implements AyahTexts {
  /// Wraps [text], drawn in [fontFamily].
  const HafsAyahTexts(this.text, {required this.fontFamily});

  /// The verified text.
  final QuranText text;

  @override
  final String fontFamily;

  @override
  QuranMetadata get metadata => text.metadata;

  @override
  int ayahCount(int surah) => text.metadata.surah(surah).ayahCount;

  @override
  bool has(AyahRef ref) =>
      ref.surah >= 1 &&
      ref.surah <= text.metadata.surahs.length &&
      ref.ayah >= 1 &&
      ref.ayah <= ayahCount(ref.surah);

  @override
  String copy(AyahRef ref) => text.uthmani(ref);

  @override
  String display(AyahRef ref) => text.mushaf(ref);

  @override
  String? mark(AyahRef ref) => text.mark(ref);

  @override
  int pageOf(AyahRef ref) => text.metadata.pageOf(ref.surah, ref.ayah);
}

/// One ayah of a reading's text: its words, its number as written, and the
/// page it starts on.
typedef RiwayaAyah = ({String text, String mark, int page});

/// Another reading, from the King Fahd Complex's text of it.
class RiwayaAyahTexts implements AyahTexts {
  /// Creates the texts of a reading.
  RiwayaAyahTexts({
    required this.metadata,
    required Map<AyahRef, RiwayaAyah> ayahs,
    required this.fontFamily,
    Set<int> unmatchedSurahs = const {},
  }) : _ayahs = Map.unmodifiable(ayahs),
       _unmatched = Set.unmodifiable(unmatchedSurahs),
       _counts = _countsOf(ayahs.keys);

  @override
  final QuranMetadata metadata;

  @override
  final String fontFamily;

  final Map<AyahRef, RiwayaAyah> _ayahs;
  final Set<int> _unmatched;
  final Map<int, int> _counts;

  static Map<int, int> _countsOf(Iterable<AyahRef> refs) {
    final counts = <int, int>{};
    for (final ref in refs) {
      if (ref.ayah > (counts[ref.surah] ?? 0)) counts[ref.surah] = ref.ayah;
    }
    return counts;
  }

  @override
  int ayahCount(int surah) => _counts[surah] ?? 0;

  @override
  bool has(AyahRef ref) =>
      !_unmatched.contains(ref.surah) && _ayahs.containsKey(ref);

  RiwayaAyah _of(AyahRef ref) =>
      _ayahs[ref] ?? (throw ArgumentError.value(ref, 'ref', 'not held'));

  @override
  String copy(AyahRef ref) => _of(ref).text;

  @override
  String display(AyahRef ref) => _of(ref).text;

  @override
  String? mark(AyahRef ref) => _of(ref).mark;

  @override
  int pageOf(AyahRef ref) => _of(ref).page;
}
