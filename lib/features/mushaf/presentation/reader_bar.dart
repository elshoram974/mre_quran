import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/theme/app_platform.dart';
import '../../../core/theme/app_tokens.dart';

/// The Mushaf tab's own top bar: menu (index), title, and actions.
///
/// Glass on iOS, a Material 3 top app bar elsewhere. It sits above the page,
/// never over the Quran text.
class ReaderBar extends StatelessWidget {
  /// Creates the bar.
  const ReaderBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.menuTooltip,
    required this.onMenu,
    required this.actions,
  });

  /// Main title (the surah of the page).
  final String title;

  /// Second line (juz and page).
  final String subtitle;

  /// Tooltip of the menu button.
  final String menuTooltip;

  /// Opens the index.
  final VoidCallback onMenu;

  /// Trailing buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.textTheme.titleMedium, maxLines: 1),
        Text(
          subtitle,
          maxLines: 1,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final menu = IconButton(
      icon: const Icon(Icons.menu),
      tooltip: menuTooltip,
      onPressed: onMenu,
    );
    if (!context.isCupertino) {
      return AppBar(
        leading: menu,
        title: titles,
        centerTitle: true,
        actions: actions,
      );
    }
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: const LiquidRoundedSuperellipse(
            borderRadius: AppTokens.radiusCard,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  menu,
                  Expanded(child: titles),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
