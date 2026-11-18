import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/startup_providers.dart';

/// Keeps the app covered while it starts, so no loading is ever seen.
///
/// Android and iOS hand over from their native launch screen to this overlay.
/// The emblem draws itself, then bounces gently while the first screen loads
/// underneath. The overlay fades away once the screen is ready.
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

  /// Whether this draws the splash itself; by default on Android and iOS.
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
    with TickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: AppTokens.splashTurn,
  );
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: AppTokens.splashLeast,
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
      _intro.value = 1;
    } else if (!_turn.isAnimating && !_fading) {
      unawaited(_turn.repeat());
      if (!_intro.isCompleted) unawaited(_intro.forward());
    }
    // The name fades in once the splash is on screen.
    if (!_named) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _update(() => _named = true),
      );
    }
  }

  bool get _overlay =>
      widget.overlay ??
      (Theme.of(context).platform == TargetPlatform.iOS ||
          Theme.of(context).platform == TargetPlatform.android);

  void _update(VoidCallback change) {
    if (mounted) setState(change);
  }

  @override
  void dispose() {
    _least?.cancel();
    _most?.cancel();
    _turn.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(startupReadyProvider);
    // The least time keeps a splash drawn here from only flickering. The
    // platform's launch screen has been up since the process started, so
    // it goes the moment the app is ready when there is no overlay.
    final waited = _leastPassed || !_overlay;
    if (!_fading && ((ready && waited) || _timedOut)) {
      _fading = true;
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
                    intro: _intro,
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
  const _Emblem({
    required this.turn,
    required this.intro,
    required this.named,
    required this.color,
  });

  final Animation<double> turn;
  final Animation<double> intro;
  final bool named;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([turn, intro]),
          builder: (context, child) {
            final wave = math.sin(turn.value * 2 * math.pi);
            final bounce = math.max(0.0, wave);
            final entrance = Curves.easeOutBack.transform(intro.value);
            return Transform.translate(
              offset: Offset(0, -bounce * AppTokens.spaceSmall),
              child: Transform.scale(
                scaleX: entrance * (1 - bounce * 0.035),
                scaleY: entrance * (1 + bounce * 0.05),
                child: child,
              ),
            );
          },
          child: SizedBox.square(
            dimension: AppTokens.splashEmblem,
            child: CustomPaint(
              painter: _StarPainter(turn: turn, intro: intro, color: color),
            ),
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
/// tool/app_icon/render_splash_brand_test.dart.
const String _brand = 'assets/brand/splash_brand.png';

/// An eight-pointed star of two squares, lightly filled, with a disc at its
/// heart. The outline draws on entry and the disc breathes while loading.
class _StarPainter extends CustomPainter {
  _StarPainter({required this.turn, required this.intro, required this.color})
    : super(repaint: Listenable.merge([turn, intro]));

  final Animation<double> turn;
  final Animation<double> intro;
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
        final a = start + i * math.pi / 2 - math.pi / 2;
        final p = centre + Offset(math.cos(a), math.sin(a)) * radius;
        i == 0 ? square.moveTo(p.dx, p.dy) : square.lineTo(p.dx, p.dy);
      }
      star.addPath(square..close(), Offset.zero);
    }
    final breath = 1 + 0.12 * math.sin(t * 2 * math.pi);
    canvas.drawPath(
      star,
      Paint()..color = color.withValues(alpha: 0.14 * intro.value),
    );
    for (final metric in star.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * intro.value),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.035
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.drawCircle(
      centre,
      radius * 0.16 * breath * intro.value,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.turn != turn || old.intro != intro;
}
