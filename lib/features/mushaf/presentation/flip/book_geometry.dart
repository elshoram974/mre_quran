import 'package:flutter/foundation.dart';

/// How pages map to steps of a book that opens right to left.
///
/// A step is one resting position of the book. In single mode a step is one
/// page. In spread mode a step is two facing pages: the odd page on the right
/// and the even page on its left, so step 0 shows pages 1 and 2.
@immutable
class BookGeometry {
  /// Creates the geometry for a book of [pageCount] pages.
  const BookGeometry({required this.pageCount, required this.spread});

  /// Number of pages.
  final int pageCount;

  /// Whether two pages face each other.
  final bool spread;

  /// Number of resting steps.
  int get stepCount => spread ? (pageCount + 1) ~/ 2 : pageCount;

  /// The step that shows [page].
  int stepOfPage(int page) => spread ? (page - 1) ~/ 2 : page - 1;

  /// The page recorded as the reading position at [step]: the right-hand page.
  int pageOfStep(int step) => spread ? 2 * step + 1 : step + 1;

  /// The right-hand page of [step], or null past the end.
  int? rightPage(int step) {
    final page = spread ? 2 * step + 1 : step + 1;
    return page >= 1 && page <= pageCount ? page : null;
  }

  /// The left-hand page of [step] (spread mode only), or null past the end.
  int? leftPage(int step) {
    if (!spread) return null;
    final page = 2 * step + 2;
    return page >= 1 && page <= pageCount ? page : null;
  }

  /// Clamps a continuous [position] to the valid range of steps.
  double clampPosition(double position) =>
      position.clamp(0, (stepCount - 1).toDouble());
}
