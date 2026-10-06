import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

import '../domain/page_geometry.dart';

/// One line row of a printed page, in the image and on screen.
typedef SpreadRow = ({
  double srcTop,
  double srcBottom,
  double destTop,
  double destHeight,
});

/// Lays the line rows of a printed page apart, so a page whose image is
/// shorter than the screen fills it, as a Mushaf app's page does.
///
/// Every row keeps the script's size and shape: the rows are drawn one by one
/// at the scale that fits the page's width, and the room left over becomes
/// equal gaps between them. Maps between image fractions and screen pixels,
/// for highlights and presses.
@immutable
class LineSpread {
  const LineSpread._(this._cuts, this._scale, this._gap, this._offset);

  /// The spread of a page with row edges [cuts] (fractions of the image
  /// height) that shows the part [crop] of the image's width, for an image of
  /// [aspect] (width over height) in [area], or null when the page already
  /// reaches the bottom of [area] or its rows are not known.
  static LineSpread? fit({
    required List<double> cuts,
    required FractionRect crop,
    required double aspect,
    required Size area,
  }) {
    if (cuts.length < 2) return null;
    final scale = area.width / ((crop.right - crop.left) * aspect);
    final natural = (cuts.last - cuts.first) * scale;
    if (natural >= area.height) return null;
    final rows = cuts.length - 1;
    // A page of few rows is not stretched past one row of room between rows;
    // it sits in the middle instead.
    final gap = ((area.height - natural) / rows).clamp(
      0.0,
      (cuts.last - cuts.first) / rows * scale,
    );
    final offset = (area.height - natural - gap * rows) / 2;
    return LineSpread._(cuts, scale, gap, offset);
  }

  final List<double> _cuts;

  /// Screen pixels per image height.
  final double _scale;

  /// Room between two rows.
  final double _gap;

  /// Room above the first row and below the last, beyond half a gap.
  final double _offset;

  @override
  bool operator ==(Object other) =>
      other is LineSpread &&
      identical(other._cuts, _cuts) &&
      other._scale == _scale &&
      other._gap == _gap &&
      other._offset == _offset;

  @override
  int get hashCode => Object.hash(_cuts, _scale, _gap, _offset);

  /// The rows, top to bottom.
  List<SpreadRow> get rows => [
    for (var i = 0; i < _cuts.length - 1; i++)
      (
        srcTop: _cuts[i],
        srcBottom: _cuts[i + 1],
        destTop: _destTop(i),
        destHeight: (_cuts[i + 1] - _cuts[i]) * _scale,
      ),
  ];

  double _destTop(int row) =>
      _offset + _gap / 2 + row * _gap + (_cuts[row] - _cuts.first) * _scale;

  /// The screen y of the image fraction [y], taken as the top of a span, or
  /// as its bottom when [bottom].
  double toScreen(double y, {bool bottom = false}) {
    var row = 0;
    while (row < _cuts.length - 2 &&
        (bottom ? y > _cuts[row + 1] : y >= _cuts[row + 1])) {
      row++;
    }
    final inside = y.clamp(_cuts[row], _cuts[row + 1]);
    return _destTop(row) + (inside - _cuts[row]) * _scale;
  }

  /// The image fraction under the screen y [dy]; a press in a gap belongs to
  /// the row above or below it, whichever is nearer.
  double toImage(double dy) {
    var row = 0;
    while (row < _cuts.length - 2 && dy >= _destTop(row + 1) - _gap / 2) {
      row++;
    }
    return (_cuts[row] + (dy - _destTop(row)) / _scale).clamp(
      _cuts[row],
      _cuts[row + 1],
    );
  }
}
