import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Lets two fingers change the size of the text a screen reads, such as the
/// reader's text size.
///
/// It enlarges nothing itself: [child] is drawn as it is. While the fingers
/// move, [onChanging] gets the size they have reached, in steps of [step], so
/// the owner sets its text at that size at once; when they lift, [onChanged]
/// gets the final size, once, to keep. One finger is left alone, so swipes,
/// scrolling, taps, and long presses under it work as before.
class PinchZoom extends StatefulWidget {
  /// Creates the detector around [child], whose text size is now [value].
  const PinchZoom({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.child,
    this.onChanging,
  });

  /// The size kept now: where a pinch begins from.
  final double value;

  /// Smallest size a pinch can reach.
  final double min;

  /// Largest size a pinch can reach.
  final double max;

  /// Called with each size the fingers reach while they move. Null shows the
  /// new size only when they lift.
  final ValueChanged<double>? onChanging;

  /// Called once with the final size when the fingers lift, if it changed.
  final ValueChanged<double> onChanged;

  /// The content whose text is resized by the owner.
  final Widget child;

  /// How far apart the sizes handed to [onChanging] are: fine enough to look
  /// smooth, coarse enough to set the text out only so many times.
  static const double step = 0.02;

  @override
  State<PinchZoom> createState() => _PinchZoomState();
}

class _PinchZoomState extends State<PinchZoom> {
  /// The size the pinch began from; null when none is under way. Kept apart
  /// from [PinchZoom.value], which the owner may move while the fingers do.
  double? _base;

  /// The size last reached; null before the fingers have moved.
  double? _reached;

  void _update(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    final base = _base ??= widget.value;
    final raw = (base * details.scale).clamp(widget.min, widget.max);
    final next = ((raw / PinchZoom.step).round() * PinchZoom.step).clamp(
      widget.min,
      widget.max,
    );
    if (next == _reached) return;
    _reached = next;
    widget.onChanging?.call(next);
  }

  void _end(ScaleEndDetails details) {
    final base = _base;
    final reached = _reached;
    _base = null;
    _reached = null;
    if (base == null || reached == null || reached == base) return;
    widget.onChanged(reached);
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      _TwoFingerScaleRecognizer:
          GestureRecognizerFactoryWithHandlers<_TwoFingerScaleRecognizer>(
            _TwoFingerScaleRecognizer.new,
            (recognizer) => recognizer
              ..onUpdate = _update
              ..onEnd = _end,
          ),
    },
    child: widget.child,
  );
}

/// Notices two fingers spreading apart, once for each pinch, and changes
/// nothing on screen: for content that cannot be enlarged, such as a printed
/// page, where [onPinchOut] suggests a better way to read it bigger. One
/// finger is left alone, as in [PinchZoom].
class PinchOut extends StatefulWidget {
  /// Creates the detector around [child].
  const PinchOut({super.key, required this.onPinchOut, required this.child});

  /// Called once when the fingers have spread clearly apart.
  final VoidCallback onPinchOut;

  /// The content, drawn as it is.
  final Widget child;

  /// How far the fingers must spread, as a share of where they began.
  static const double threshold = 1.15;

  @override
  State<PinchOut> createState() => _PinchOutState();
}

class _PinchOutState extends State<PinchOut> {
  bool _reported = false;

  void _update(ScaleUpdateDetails details) {
    if (_reported || details.pointerCount < 2) return;
    if (details.scale < PinchOut.threshold) return;
    _reported = true;
    widget.onPinchOut();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      _TwoFingerScaleRecognizer:
          GestureRecognizerFactoryWithHandlers<_TwoFingerScaleRecognizer>(
            _TwoFingerScaleRecognizer.new,
            (recognizer) => recognizer
              ..onUpdate = _update
              ..onEnd = (_) => _reported = false,
          ),
    },
    child: widget.child,
  );
}

/// A scale recognizer that claims the gesture the moment a second finger
/// lands, before a page swipe or a scroll can take it.
class _TwoFingerScaleRecognizer extends ScaleGestureRecognizer {
  int _pointers = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointers++;
    if (_pointers == 2) resolve(GestureDisposition.accepted);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointers = 0;
    super.didStopTrackingLastPointer(pointer);
  }
}
