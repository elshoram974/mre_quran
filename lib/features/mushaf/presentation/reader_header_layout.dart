import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../core/theme/app_tokens.dart';

/// Side padding that gives way before its child does.
///
/// With room, the child has [most] at each side. In a narrower box the
/// padding closes up, to no less than [least]; only then is the child itself
/// made narrower. The child is centred both ways.
class YieldingPadding extends SingleChildRenderObjectWidget {
  /// Creates padding of [most] at each side of [child], and no less than
  /// [least].
  const YieldingPadding({
    super.key,
    required this.most,
    required this.least,
    required super.child,
  }) : assert(least >= 0 && most >= least);

  /// The padding at each side when there is room.
  final double most;

  /// The padding at each side in the narrowest box.
  final double least;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderYieldingPadding(most: most, least: least);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderYieldingPadding)
      ..most = most
      ..least = least;
  }
}

class _RenderYieldingPadding extends RenderShiftedBox {
  _RenderYieldingPadding({required this._most, required this._least})
    : super(null);

  double get most => _most;
  double _most;
  set most(double value) {
    if (value == _most) return;
    _most = value;
    markNeedsLayout();
  }

  double get least => _least;
  double _least;
  set least(double value) {
    if (value == _least) return;
    _least = value;
    markNeedsLayout();
  }

  /// The room the child may take: all but the least padding.
  BoxConstraints _inner(BoxConstraints constraints) => BoxConstraints(
    maxWidth: math.max(0.0, constraints.maxWidth - 2 * _least),
    maxHeight: constraints.maxHeight,
  );

  /// This box around a child of size [child]: as much padding as fits.
  Size _outer(BoxConstraints constraints, Size child) =>
      constraints.constrain(Size(child.width + 2 * _most, child.height));

  @override
  double computeMinIntrinsicWidth(double height) =>
      (child?.getMinIntrinsicWidth(height) ?? 0) + 2 * _least;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height) ?? 0) + 2 * _most;

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(math.max(0.0, width - 2 * _least)) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(math.max(0.0, width - 2 * _least)) ?? 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => _outer(
    constraints,
    child?.getDryLayout(_inner(constraints)) ?? Size.zero,
  );

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final inner = _inner(constraints);
    final at = child.getDryBaseline(inner, baseline);
    if (at == null) return null;
    final size = child.getDryLayout(inner);
    return at + (_outer(constraints, size).height - size.height) / 2;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = _outer(constraints, Size.zero);
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = _outer(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }
}

/// Where an item of the row above a Mushaf page sits.
enum ReaderHeaderSide {
  /// At the reading start, packed from the edge.
  start,

  /// In the centre, or as near to it as the sides leave room.
  middle,

  /// At the reading end, packed from the edge.
  end,
}

class _HeaderParentData extends ContainerBoxParentData<RenderBox> {
  ReaderHeaderSide side = ReaderHeaderSide.start;
  double? give;
}

/// Says where a child of a [ReaderHeaderLayout] sits, and whether it gives
/// way when the row is short.
class ReaderHeaderSlot extends ParentDataWidget<_HeaderParentData> {
  /// Puts [child] at [side].
  const ReaderHeaderSlot({
    super.key,
    required this.side,
    this.give,
    required super.child,
  });

  /// The side of the row the child sits at.
  final ReaderHeaderSide side;

  /// Null for a child that keeps its size, such as a button. Otherwise the
  /// child holds text and may be made narrower, and this is how much it can
  /// lose before its text is cut short: the padding it can spare.
  final double? give;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _HeaderParentData;
    if (data.side == side && data.give == give) return;
    data
      ..side = side
      ..give = give;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => ReaderHeaderLayout;
}

/// One row whose children take the room they need, not a fixed share.
///
/// The start's children are packed from the reading start, the end's from
/// the reading end, and the middle child sits in the centre, or as near to
/// it as the sides leave room. A side that needs more than half the row
/// takes it from the other's spare room.
///
/// When the row is too short for everyone, room is found in this order, so
/// that nothing is cut short until it must be:
///
/// 1. the gaps between neighbours close up;
/// 2. the children that give ([ReaderHeaderSlot.give]) each spare the same
///    share of their padding;
/// 3. their text gives way to an ellipsis, one child at a time: the start's
///    first (the surah's name, which still reads when cut), then the end's
///    from the last back (a juz or hizb cut short loses its number);
/// 4. in a row too narrow even for that, they all shrink together.
///
/// It never overflows: a child that keeps its size is laid out as it likes,
/// as a [Row] lays out a child without flex, and the rest fit around it.
class ReaderHeaderLayout extends MultiChildRenderObjectWidget {
  /// Creates the row. Every child is a [ReaderHeaderSlot].
  const ReaderHeaderLayout({super.key, super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReaderHeaderLayout(textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderReaderHeaderLayout).textDirection =
        Directionality.of(context);
  }
}

/// The children of a header row, sized for one set of constraints.
typedef _Fit = ({
  Size size,
  List<RenderBox> children,
  List<BoxConstraints> limits,
  List<Size> sizes,
  double gap,
});

class _RenderReaderHeaderLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeaderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeaderParentData> {
  _RenderReaderHeaderLayout({required this._textDirection});

  /// The gap between neighbours when there is room, and when there is not.
  static const double _gapMost = AppTokens.spaceSmall;
  static const double _gapLeast = AppTokens.spaceTiny;

  /// The narrowest a child holding text is made while another can still
  /// give: a touch target, enough for a few letters.
  static const double _textLeast = AppTokens.minTarget;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  static _HeaderParentData _data(RenderBox child) =>
      child.parentData! as _HeaderParentData;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeaderParentData) {
      child.parentData = _HeaderParentData();
    }
  }

  /// The children in the order their text gives way: the start's, then the
  /// end's from the last back, then the middle's.
  static List<int> _yieldOrder(List<RenderBox> children) {
    final all = [for (var i = 0; i < children.length; i++) i];
    bool at(int i, ReaderHeaderSide side) =>
        _data(children[i]).give != null && _data(children[i]).side == side;
    return [
      ...all.where((i) => at(i, ReaderHeaderSide.start)),
      ...all.reversed.where((i) => at(i, ReaderHeaderSide.end)),
      ...all.where((i) => at(i, ReaderHeaderSide.middle)),
    ];
  }

  /// The width of each child in a row [room] wide, given the width each
  /// would [wish] for, and the gap between neighbours.
  static ({List<double> widths, double gap}) _share(
    List<RenderBox> children,
    List<double> wish,
    double room,
  ) {
    final widths = [...wish];
    final gaps = math.max(0, wish.where((width) => width > 0).length - 1);
    final sum = wish.fold<double>(0, (total, width) => total + width);
    if (sum + gaps * _gapMost <= room) return (widths: widths, gap: _gapMost);
    // The gaps close up first.
    if (sum + gaps * _gapLeast <= room) {
      return (widths: widths, gap: (room - sum) / gaps);
    }
    var short = sum + gaps * _gapLeast - room;
    final yielding = _yieldOrder(children);

    // Then each spares the same share of its padding.
    final spare = {
      for (final i in yielding) i: math.min(_data(children[i]).give!, wish[i]),
    };
    final spared = spare.values.fold<double>(0, (total, part) => total + part);
    if (spared > 0) {
      final part = math.min(1.0, short / spared);
      for (final i in yielding) {
        widths[i] -= spare[i]! * part;
      }
      short -= spared * part;
    }
    // Then text gives way, one child at a time.
    for (final i in yielding) {
      if (short <= precisionErrorTolerance) break;
      final cut = math.min(math.max(0.0, widths[i] - _textLeast), short);
      widths[i] -= cut;
      short -= cut;
    }
    // In a row too narrow even for that, they shrink together.
    if (short > precisionErrorTolerance) {
      final left = yielding.fold<double>(0, (total, i) => total + widths[i]);
      if (left > 0) {
        final part = math.min(1.0, short / left);
        for (final i in yielding) {
          widths[i] *= 1 - part;
        }
      }
    }
    return (widths: widths, gap: _gapLeast);
  }

  /// Sizes every child for a row under [constraints]: a child that keeps its
  /// size as it likes, one that gives to its share of the room.
  _Fit _fit(BoxConstraints constraints, ChildLayouter layoutChild) {
    final children = getChildrenAsList();
    final free = BoxConstraints(maxHeight: constraints.maxHeight);
    final limits = List<BoxConstraints>.filled(children.length, free);
    final sizes = List<Size>.filled(children.length, Size.zero);
    final wish = List<double>.filled(children.length, 0);
    for (var i = 0; i < children.length; i++) {
      if (_data(children[i]).give == null) {
        sizes[i] = layoutChild(children[i], free);
        wish[i] = sizes[i].width;
      } else {
        // A whole pixel: text laid out in exactly its own width may wrap.
        wish[i] = children[i]
            .getMaxIntrinsicWidth(constraints.maxHeight)
            .ceilToDouble();
      }
    }
    final share = _share(children, wish, constraints.maxWidth);
    var width = 0.0;
    var height = 0.0;
    for (var i = 0; i < children.length; i++) {
      if (_data(children[i]).give != null) {
        limits[i] = free.tighten(width: share.widths[i]);
        sizes[i] = layoutChild(children[i], limits[i]);
      }
      width +=
          sizes[i].width + (sizes[i].width > 0 && width > 0 ? share.gap : 0);
      height = math.max(height, sizes[i].height);
    }
    return (
      // The whole row when it has an end; else only what the children need.
      size: constraints.constrain(
        Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : width,
          height,
        ),
      ),
      children: children,
      limits: limits,
      sizes: sizes,
      gap: share.gap,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var width = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final wish = child.getMaxIntrinsicWidth(height);
      final give = _data(child).give;
      width += give == null ? wish : math.min(wish, _textLeast);
      if (wish > 0 && child != firstChild) width += _gapLeast;
    }
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var width = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final wish = child.getMaxIntrinsicWidth(height);
      width += wish + (wish > 0 && width > 0 ? _gapMost : 0);
    }
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      height = math.max(height, child.getMaxIntrinsicHeight(double.infinity));
    }
    return height;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _fit(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final fit = _fit(constraints, ChildLayoutHelper.dryLayoutChild);
    double? highest;
    for (var i = 0; i < fit.children.length; i++) {
      final at = fit.children[i].getDryBaseline(fit.limits[i], baseline);
      if (at == null) continue;
      final y = at + (fit.size.height - fit.sizes[i].height) / 2;
      highest = highest == null ? y : math.min(highest, y);
    }
    return highest;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void performLayout() {
    final fit = _fit(constraints, ChildLayoutHelper.layoutChild);
    size = fit.size;
    final count = fit.children.length;
    // How far each child is from the reading start.
    final along = List<double>.filled(count, 0);
    var from = 0.0;
    var to = size.width;
    for (var i = 0; i < count; i++) {
      final width = fit.sizes[i].width;
      if (_data(fit.children[i]).side != ReaderHeaderSide.start) continue;
      along[i] = from;
      if (width > 0) from += width + fit.gap;
    }
    for (var i = count - 1; i >= 0; i--) {
      final width = fit.sizes[i].width;
      if (_data(fit.children[i]).side != ReaderHeaderSide.end) continue;
      to -= width;
      along[i] = to;
      if (width > 0) to -= fit.gap;
    }
    for (var i = 0; i < count; i++) {
      final width = fit.sizes[i].width;
      if (_data(fit.children[i]).side != ReaderHeaderSide.middle) continue;
      along[i] = ((size.width - width) / 2)
          .clamp(from, math.max(from, to - width))
          .toDouble();
    }
    for (var i = 0; i < count; i++) {
      final box = fit.sizes[i];
      _data(fit.children[i]).offset = Offset(
        // The row runs from the reading start: mirrored right to left.
        _textDirection == TextDirection.rtl
            ? size.width - along[i] - box.width
            : along[i],
        (size.height - box.height) / 2,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
