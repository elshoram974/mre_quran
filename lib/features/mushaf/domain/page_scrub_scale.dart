import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The pages a scrubber track stands for, and where each one lies on it.
///
/// The whole scale spreads every page of the Mushaf over the track, so one
/// page is narrower than a finger. The fine scale spreads only a few pages,
/// so each one can be picked exactly.
///
/// A position on the track is a fraction: 0 at the first page of the scale,
/// 1 at its last.
@immutable
class PageScrubScale {
  const PageScrubScale._(this.first, this.last, {required this.fine});

  /// The scale over all [pageCount] pages.
  const PageScrubScale.whole(int pageCount) : this._(1, pageCount, fine: false);

  /// A fine scale of [span] page steps that keeps [page] at [fraction] of
  /// the track, so the thumb stays under the finger when the scale changes.
  /// Near either end of the Mushaf the window shifts to stay inside it.
  factory PageScrubScale.fineAt(
    int page, {
    required double fraction,
    required int pageCount,
    int span = defaultFineSpan,
  }) {
    final steps = math.min(span, pageCount - 1);
    final wanted = page - (fraction.clamp(0.0, 1.0) * steps).round();
    final first = wanted.clamp(1, pageCount - steps);
    return PageScrubScale._(first, first + steps, fine: true);
  }

  /// This scale moved [by] pages along the Mushaf, as far as its ends
  /// allow. The reader pushes a fine scale along this way by holding the
  /// thumb at one end of the track.
  PageScrubScale shifted(int by, {required int pageCount}) {
    final move = by.clamp(1 - first, pageCount - last);
    return move == 0 ? this : PageScrubScale._(first + move, last + move, fine: fine);
  }

  /// Page steps between two ticks, and between two labelled ticks, for a
  /// track that shows [pages] page steps: every page when few are shown,
  /// every twentieth when the whole Mushaf is.
  static ({int minor, int major}) ticksFor(double pages) => switch (pages) {
    <= 40 => (minor: 1, major: 5),
    <= 200 => (minor: 5, major: 25),
    _ => (minor: 20, major: 100),
  };

  /// Page steps a fine scale shows unless told otherwise.
  static const int defaultFineSpan = 20;

  /// First page of the scale.
  final int first;

  /// Last page of the scale.
  final int last;

  /// Whether this is a fine scale.
  final bool fine;

  /// The page at [fraction] of the track, rounded to the nearest page.
  int pageAt(double fraction) =>
      first + (fraction.clamp(0.0, 1.0) * (last - first)).round();

  /// Where [page] lies on the track, 0–1. A page outside the scale lies at
  /// its nearer end.
  double fractionOf(int page) =>
      last == first ? 0 : ((page - first) / (last - first)).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is PageScrubScale &&
      other.first == first &&
      other.last == last &&
      other.fine == fine;

  @override
  int get hashCode => Object.hash(first, last, fine);
}
