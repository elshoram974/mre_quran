import 'package:flutter/material.dart';

import '../theme/app_surface_style.dart';
import '../theme/app_tokens.dart';

/// The one prominent panel at the top of a screen: the next prayer, today's
/// adhkar. A gold-tinted gradient with an optional faint [watermark] glyph at
/// the end corner.
///
/// Text and icons inside take the on-primary-container colour by default, so
/// children need no colour of their own. It is opaque on every platform.
class AppHeroCard extends StatelessWidget {
  /// Creates a hero panel around [child].
  const AppHeroCard({
    super.key,
    required this.child,
    this.watermark,
    this.onTap,
  });

  /// Panel content.
  final Widget child;

  /// A large faint glyph drawn behind the content at the end corner.
  final IconData? watermark;

  /// Called on tap; null makes the panel inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusCard);
    final foreground = scheme.onPrimaryContainer;
    final content = Padding(
      padding: const EdgeInsetsDirectional.all(AppTokens.heroPadding),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground),
          child: child,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppSurfaceStyle.of(context).raisedShadow,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.16),
              scheme.primaryContainer,
            ),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            if (watermark != null)
              PositionedDirectional(
                end: -AppTokens.heroPadding,
                bottom: -AppTokens.heroPadding,
                child: ExcludeSemantics(
                  child: Icon(
                    watermark,
                    size: AppTokens.badgeLarge * 2,
                    color: foreground.withValues(alpha: 0.07),
                  ),
                ),
              ),
            Material(
              type: MaterialType.transparency,
              child: onTap == null
                  ? content
                  : InkWell(borderRadius: radius, onTap: onTap, child: content),
            ),
          ],
        ),
      ),
    );
  }
}
