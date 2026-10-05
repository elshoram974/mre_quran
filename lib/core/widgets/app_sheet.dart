import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Shared draggable bottom sheet.
///
/// Drag the handle or the content to expand, shrink, or dismiss. The body is a
/// plain (non-scrolling) widget; the sheet scrolls it. iOS uses a liquid glass
/// sheet with medium and large detents. Android uses a Material 3 container.
abstract final class AppSheet {
  /// Shows a sheet and returns the value it is popped with.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double initialSize = 0.5,
    double minSize = 0.25,
    double maxSize = 0.92,
  }) {
    final scheme = Theme.of(context).colorScheme;
    if (context.isCupertino) {
      return GlassModalSheet.show<T>(
        context: context,
        useRootNavigator: true,
        halfSize: initialSize,
        fullSize: maxSize,
        detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
        settings: LiquidGlassSettings(
          blur: 22,
          glassColor: scheme.surface.withValues(alpha: 0.62),
        ),
        builder: (sheetContext) => Material(
          type: MaterialType.transparency,
          child: builder(sheetContext),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        snap: true,
        initialChildSize: initialSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        builder: (context, controller) => _MaterialSheetSurface(
          child: SingleChildScrollView(
            controller: controller,
            child: builder(context),
          ),
        ),
      ),
    );
  }
}

class _MaterialSheetSurface extends StatelessWidget {
  const _MaterialSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.radiusSheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

/// Small grab handle drawn at the top of a sheet.
class AppSheetHandle extends StatelessWidget {
  /// Creates the handle.
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}
