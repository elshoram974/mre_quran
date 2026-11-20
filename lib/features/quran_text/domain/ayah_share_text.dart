import 'dart:math' as math;

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

  /// Letters a picture holds, when the number of pictures is left automatic,
  /// before the next ayah starts a new one (tashkeel counted). About a phone
  /// screen and a half of the Mushaf script at the card's width: enough for
  /// Ayat al-Kursi and the ayahs around it, short enough to stay readable in
  /// a chat.
  static const int lettersPerPicture = 1400;

  /// The most pictures one choice is cut into.
  static const int maxPictures = 10;

  /// [refs] cut into pictures that each hold whole ayahs, in order.
  ///
  /// With no [count] a picture is filled until the next ayah would pass
  /// [lettersPerPicture]; an ayah longer than that has a picture of its own.
  /// With a [count] the letters are shared between that many pictures as
  /// evenly as whole ayahs allow, never fewer than one ayah each: the count
  /// is held between 1 and the ayahs there are (and [maxPictures]).
  static List<List<AyahRef>> pictures(
    AyahTexts text,
    List<AyahRef> refs, {
    int? count,
  }) {
    if (refs.isEmpty) return const [];
    final lengths = [for (final ref in refs) text.display(ref).length];
    if (count == null) return _byLimit(refs, lengths);
    final pictures = math.max(
      1,
      math.min(count, math.min(refs.length, maxPictures)),
    );
    return _evenly(refs, lengths, pictures);
  }

  static List<List<AyahRef>> _byLimit(List<AyahRef> refs, List<int> lengths) {
    final pictures = <List<AyahRef>>[];
    var current = <AyahRef>[];
    var letters = 0;
    for (final (index, ref) in refs.indexed) {
      if (current.isNotEmpty && letters + lengths[index] > lettersPerPicture) {
        pictures.add(current);
        current = <AyahRef>[];
        letters = 0;
      }
      current.add(ref);
      letters += lengths[index];
    }
    if (current.isNotEmpty) pictures.add(current);
    return pictures;
  }

  /// Each picture but the last takes ayahs while the next one brings its
  /// letters closer to its share of the total, and leaves one ayah for every
  /// picture still to come.
  static List<List<AyahRef>> _evenly(
    List<AyahRef> refs,
    List<int> lengths,
    int count,
  ) {
    final total = lengths.fold(0, (sum, length) => sum + length);
    final pictures = <List<AyahRef>>[];
    var start = 0;
    var before = 0;
    for (var picture = 1; picture < count; picture++) {
      final target = total * picture / count;
      final room = refs.length - (count - picture);
      var end = start;
      var sum = before;
      while (end < room) {
        final next = sum + lengths[end];
        if (end > start && (next - target).abs() >= (sum - target).abs()) break;
        sum = next;
        end++;
      }
      pictures.add(refs.sublist(start, end));
      start = end;
      before = sum;
    }
    pictures.add(refs.sublist(start));
    return pictures;
  }
}
