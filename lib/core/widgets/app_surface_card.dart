import 'package:material_ui/material_ui.dart';

import '../theme/app_surface_style.dart';
import '../theme/app_tokens.dart';
import 'press_scale.dart';

/// An opaque raised card: a soft fill above the page, a hairline edge, and a
/// diffuse shadow.
///
/// It is the Material face of `AppCard`, and the card to use on every platform
/// when the content is Quran text, which must never sit on glass. When
/// [highlighted], the fill eases to the primary container, for a finished or
/// current item. With [onTap] the whole card is one tappable target.
class AppSurfaceCard extends StatelessWidget {
  /// Creates a card around [child].
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsetsDirectional.zero,
    this.highlighted = false,
    this.onTap,
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Whether the card is tinted to stand out from its neighbours.
  final bool highlighted;

  /// Called on tap; null makes the card inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = AppSurfaceStyle.of(context);
    final radius = BorderRadius.circular(AppTokens.radiusCard);
    final content = Padding(padding: padding, child: child);
    final card = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTokens.motionMedium,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: highlighted ? scheme.primaryContainer : surfaces.raised,
        borderRadius: radius,
        border: Border.all(
          color: highlighted
              ? scheme.primary.withValues(alpha: 0.35)
              : surfaces.hairline,
        ),
        boxShadow: surfaces.raisedShadow,
      ),
      // Always a Material above the content, so rows inside (ListTile,
      // switches) paint their ink on the card, not under its fill.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(borderRadius: radius, onTap: onTap, child: content),
      ),
    );
    return onTap == null ? card : PressScale(child: card);
  }
}
