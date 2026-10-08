import 'package:meta/meta.dart';

/// A run of ayahs of one surah, inclusive at both ends.
@immutable
class AyahSpan {
  /// Creates the span of surah [surah] from ayah [from] to ayah [to].
  const AyahSpan({required this.surah, required this.from, required this.to});

  /// Surah number, 1 to 114.
  final int surah;

  /// First ayah.
  final int from;

  /// Last ayah. Equals [from] for a single ayah.
  final int to;

  /// Whether the span starts at the beginning of its surah.
  bool get opensSurah => from == 1;

  @override
  bool operator ==(Object other) =>
      other is AyahSpan &&
      other.surah == surah &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(surah, from, to);
}

/// What a Quran dhikr recites: only references. The words come from the
/// verified Quran text, never from the adhkar data.
@immutable
class QuranPassage {
  /// Creates a passage of [spans], read in order.
  const QuranPassage({required this.spans, required this.istiadha});

  /// The ayahs, in reading order.
  final List<AyahSpan> spans;

  /// Whether the recitation starts with the isti'adha. Only the first Quran
  /// dhikr of a list does: it is said once when recitation begins (An-Nahl
  /// 16:98), not again for every surah.
  final bool istiadha;
}

/// Recitation formulas that are not ayahs of any surah's text.
abstract final class Recitation {
  /// The isti'adha said before reciting the Quran.
  static const String istiadha =
      'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ';
}
