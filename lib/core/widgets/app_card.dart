import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';
import 'app_surface_card.dart';

/// Shared card for grouped content outside the Quran reading surface.
///
/// Liquid glass on iOS, an opaque raised [AppSurfaceCard] on Android. Do not
/// place glass controls inside it; Material controls are fine. With [onTap]
/// the whole card is one tappable target.
class AppCard extends StatelessWidget {
  /// Creates a card around [child].
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(AppTokens.spaceSmall),
    this.onTap,
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Called on tap; null makes the card inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!context.isCupertino) {
      return AppSurfaceCard(padding: padding, onTap: onTap, child: child);
    }
    final content = Padding(padding: padding, child: child);
    return GlassCard(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      padding: EdgeInsets.zero,
      shape: const LiquidRoundedSuperellipse(
        borderRadius: AppTokens.radiusCard,
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}
