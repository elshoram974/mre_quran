import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Shared card for grouped content outside the Quran reading surface.
///
/// Liquid glass on iOS, a Material 3 card on Android. Do not place glass
/// controls inside it; Material controls are fine.
class AppCard extends StatelessWidget {
  /// Creates a card around [child].
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => context.isCupertino
      ? GlassCard(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          padding: padding,
          shape: const LiquidRoundedSuperellipse(
            borderRadius: AppTokens.radiusCard,
          ),
          child: child,
        )
      : Card(
          margin: EdgeInsets.zero,
          child: Padding(padding: padding, child: child),
        );
}
