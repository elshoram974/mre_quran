import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Shared loading shimmer. Wrap skeleton shapes ([SkeletonBox]) in it.
///
/// The sweep follows the text direction, so it runs right to left in Arabic.
/// With reduced motion it paints a static block instead of animating.
class AppShimmer extends StatefulWidget {
  /// Creates a shimmer over [child].
  const AppShimmer({super.key, required this.child});

  /// Skeleton shapes to shimmer.
  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final highlight = scheme.surfaceContainerLowest;
    final direction = Directionality.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            if (still) {
              return ColorFiltered(
                colorFilter: ColorFilter.mode(base, BlendMode.srcIn),
                child: child,
              );
            }
            final slide = _controller.value * 2 - 0.5;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [base, highlight, base],
                stops: [
                  (slide - 0.25).clamp(0.0, 1.0),
                  slide.clamp(0.0, 1.0),
                  (slide + 0.25).clamp(0.0, 1.0),
                ],
              ).createShader(bounds, textDirection: direction),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

/// A rounded placeholder block used inside [AppShimmer].
class SkeletonBox extends StatelessWidget {
  /// Creates a block. Omit [width] to fill the available width.
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppTokens.radiusField,
  });

  /// Block width, or null to fill.
  final double? width;

  /// Block height.
  final double height;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
