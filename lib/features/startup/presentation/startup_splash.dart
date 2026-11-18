import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/startup_providers.dart';
import '../data/launch_screen.dart';

/// Keeps the app covered while it starts, so no loading is ever seen.
///
/// On Android the platform's own launch screen does it: its star turns
/// until this lets it go. Where a launch screen can neither turn nor wait
/// (iOS), this draws the same star turning on the paper, in the place the
/// launch screen draws it still, with the app's name fading in under it. The first screen is built and loads
/// underneath (the Quran text and the Mushaf page, at the same time), and
/// the splash fades away once it is ready, so no loading is ever seen.
///
/// Where it draws the splash, it stays at least [least], so it never only
/// flickers. It stays at most [most], so a slow device or a page that cannot
/// be had never keeps the app shut.
class StartupSplash extends ConsumerStatefulWidget {
  /// Creates the splash over [child].
  const StartupSplash({
    super.key,
    required this.child,
    this.least = AppTokens.splashLeast,
    this.most = AppTokens.splashMost,
    this.overlay,
  });

  /// Whether this draws the splash itself; by default only on iOS, whose
  /// launch screen cannot wait.
  final bool? overlay;

  /// The app.
  final Widget child;

  /// Shortest and longest time the splash shows.
  final Duration least;
  final Duration most;

  @override
  ConsumerState<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends ConsumerState<StartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: AppTokens.splashTurn,
  );
  bool _named = false;
  bool _leastPassed = false;
  bool _timedOut = false;
  bool _fading = false;
  bool _gone = false;
  Timer? _least;
  Timer? _most;

  @override
  void initState() {
    super.initState();
    _least = Timer(widget.least, () => _update(() => _leastPassed = true));
    _most = Timer(widget.most, () => _update(() => _timedOut = true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_overlay || MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating && !_fading) {
      unawaited(_turn.repeat());
    }
    // The name fades in once the splash is on screen.
    if (!_named) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _update(() => _named = true),
      );
    }
  }

  bool get _overlay =>
      widget.overlay ?? Theme.of(context).platform == TargetPlatform.iOS;

  void _update(VoidCallback change) {
    if (mounted) setState(change);
  }

  @override
  void dispose() {
    _least?.cancel();
    _most?.cancel();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(startupReadyProvider);
    // The least time keeps a splash drawn here from only flickering. The
    // platform's launch screen has been up since the process started, so
    // it goes the moment the app is ready.
    final waited = _leastPassed || !_overlay;
    if (!_fading && ((ready && waited) || _timedOut)) {
      _fading = true;
      unawaited(ref.read(launchScreenProvider).release());
    }
    if (!_overlay) return widget.child;
    // Without animations there is no fade to wait for.
    if (_gone || (_fading && MediaQuery.disableAnimationsOf(context))) {
      // Nothing turns behind the app once the splash is gone.
      _turn.stop();
      return widget.child;
    }
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _fading,
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppTokens.motionMedium,
              onEnd: () => _update(() {
                _gone = _fading;
                if (_gone) _turn.stop();
              }),
              child: ColoredBox(
                color: scheme.surface,
                child: Semantics(
                  label: context.l10n.appTitle,
                  excludeSemantics: true,
                  child: _Emblem(
                    turn: _turn,
                    named: _named,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The app's star in the middle of the screen, as the launch screen has
/// it, and its name beneath.
class _Emblem extends StatelessWidget {
  const _Emblem({required this.turn, required this.named, required this.color});

  final Animation<double> turn;
  final bool named;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: AppTokens.splashEmblem,
          child: CustomPaint(
            painter: _StarPainter(turn: turn, color: color),
          ),
        ),
        // Below the star, which stays exactly in the middle.
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: AppTokens.splashEmblem + AppTokens.heroPadding * 3,
          ),
          child: AnimatedOpacity(
            opacity: named ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppTokens.splashName,
            child: Text(
              context.l10n.appTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        // The maker's mark, the same picture and place as
        // LaunchScreen.storyboard, so the hand-over from it does not move.
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: const Center(
            child: Image(
              image: AssetImage(_brand),
              width: 200,
              height: 80,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// "made by MRECode" ([AppConfig.brand]), drawn by
/// tool/app_icon/render_splash_brand_test.dart; bundled for iOS only, the
/// one platform whose splash this draws.
const String _brand = 'assets/brand/splash_brand.png';

/// An eight-pointed star of two squares, lightly filled, with a disc at its
/// heart: turned by [turn] through an eighth of a circle, after which it
/// looks as it began, so the turn never jumps. The disc breathes with it.
class _StarPainter extends CustomPainter {
  _StarPainter({required this.turn, required this.color})
    : super(repaint: turn);

  final Animation<double> turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = turn.value;
    final centre = size.center(Offset.zero);
    // As the launch screen draws it: radius 0.43 of the side.
    final radius = size.shortestSide / 2 * 0.86;
    final star = Path();
    for (final start in [0.0, math.pi / 4]) {
      final square = Path();
      for (var i = 0; i < 4; i++) {
        final a = start + t * math.pi / 4 + i * math.pi / 2 - math.pi / 2;
        final p = centre + Offset(math.cos(a), math.sin(a)) * radius;
        i == 0 ? square.moveTo(p.dx, p.dy) : square.lineTo(p.dx, p.dy);
      }
      star.addPath(square..close(), Offset.zero);
    }
    final breath = 1 + 0.12 * math.sin(t * 2 * math.pi);
    canvas
      ..drawPath(star, Paint()..color = color.withValues(alpha: 0.14))
      ..drawPath(
        star,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.035
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(centre, radius * 0.16 * breath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.turn != turn;
}
