import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Lets [child] give a little under the finger while it is pressed, and
/// spring back on release, so a tappable card answers the touch before it
/// answers the tap.
///
/// It only listens: the card's own tap, ripple, scrolling and long presses
/// work as before. A finger that moves off to scroll lets the card go. With
/// `MediaQuery.disableAnimationsOf` the card does not move.
class PressScale extends StatefulWidget {
  /// Creates the effect around [child].
  const PressScale({super.key, required this.child});

  /// The pressable content.
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  Offset? _from;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _move(PointerMoveEvent event) {
    final from = _from;
    if (_down &&
        from != null &&
        (event.position - from).distance > kTouchSlop) {
      _set(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (event) {
        _from = event.position;
        _set(true);
      },
      onPointerMove: _move,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !still ? AppTokens.pressScale : 1,
        duration: still ? Duration.zero : AppTokens.motionPress,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
