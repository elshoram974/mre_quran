import '../../quran_index/domain/quran_metadata.dart';
import 'ayah_range.dart';
import 'ayah_texts.dart';

/// Writes ayahs out as text to paste or send, and cuts long choices into
/// pictures that stay readable.
abstract final class AyahShareText {
  /// The ayahs of [run] in the reading's copyable text, with tashkeel, each
  /// followed by its number in [digits], inside the ornate brackets:
  /// `﴿… (١) … (٢)﴾`.
  static String body(
    AyahTexts text,
    SurahRun run,
    String Function(int) digits,
  ) {
    final ayahs = [
      for (var ayah = run.first; ayah <= run.last; ayah++)
        '${text.copy(AyahRef(run.surah, ayah))} (${digits(ayah)})',
    ];
    return '﴿${ayahs.join(' ')}﴾';
  }

  /// [text] set to read right to left wherever it is pasted: each line
  /// starts with a right-to-left mark, so an app that takes a line's
  /// direction from its first letter (or from its own language) still lays
  /// the Quran and its reference out from the right.
  static String rightToLeft(String text) =>
      text.split('\n').map((line) => '$_rlm$line').join('\n');

  static const String _rlm = '‏';

  /// The pages [run] lies on: its first ayah's page and its last ayah's.
  static ({int first, int last}) pages(AyahTexts text, SurahRun run) => (
    first: text.pageOf(AyahRef(run.surah, run.first)),
    last: text.pageOf(AyahRef(run.surah, run.last)),
  );

  /// Letters a picture holds before the next ayah starts a new one. About
  /// a phone screen of the Mushaf script at the card's size.
  static const int lettersPerPicture = 650;

  /// [refs] cut into pictures: each holds whole ayahs, in order, and stops
  /// before the one that would pass [lettersPerPicture]. An ayah longer than
  /// that has a picture of its own.
  static List<List<AyahRef>> pictures(AyahTexts text, List<AyahRef> refs) {
    final pictures = <List<AyahRef>>[];
    var current = <AyahRef>[];
    var letters = 0;
    for (final ref in refs) {
      final length = text.display(ref).length;
      if (current.isNotEmpty && letters + length > lettersPerPicture) {
        pictures.add(current);
        current = <AyahRef>[];
        letters = 0;
      }
      current.add(ref);
      letters += length;
    }
    if (current.isNotEmpty) pictures.add(current);
    return pictures;
  }
}
