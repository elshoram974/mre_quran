import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Lets two fingers change a size setting, such as the reader's text size.
///
/// While the fingers move, [child] is only scaled on screen, which costs no
/// layout; when they lift, [onChanged] gets the new value once, and the
/// owner lays the content out at its new size. One finger is left alone, so
/// swipes, scrolling, taps, and long presses under it work as before.
class PinchZoom extends StatefulWidget {
  /// Creates the detector around [child], whose size setting is now [value].
  const PinchZoom({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.child,
  });

  /// The current value of the setting.
  final double value;

  /// Smallest value a pinch can reach.
  final double min;

  /// Largest value a pinch can reach.
  final double max;

  /// Called once with the new value when the fingers lift.
  final ValueChanged<double> onChanged;

  /// The content that grows and shrinks.
  final Widget child;

  @override
  State<PinchZoom> createState() => _PinchZoomState();
}

class _PinchZoomState extends State<PinchZoom> {
  /// The value under the fingers; null when no pinch is under way.
  double? _live;

  void _update(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    final next = (widget.value * details.scale).clamp(widget.min, widget.max);
    if (next != _live) setState(() => _live = next);
  }

  void _end(ScaleEndDetails details) {
    final reached = _live;
    if (reached == null) return;
    setState(() => _live = null);
    if (reached != widget.value) widget.onChanged(reached);
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
    child: Transform.scale(
      scale: (_live ?? widget.value) / widget.value,
      child: widget.child,
    ),
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
