import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Builds the scrollable body of an [AppSheet].
///
/// The returned widget must attach [controller] to its scrollable so dragging
/// the content also drags the sheet.
typedef AppSheetBuilder = Widget Function(
  BuildContext context,
  ScrollController controller,
);

/// Shared draggable bottom sheet.
///
/// Drag up to expand, drag down to shrink or dismiss. iOS gets a translucent,
/// blurred surface; Android gets the Material 3 container.
abstract final class AppSheet {
  /// Shows a sheet and returns the value it is popped with.
  static Future<T?> show<T>({
    required BuildContext context,
    required AppSheetBuilder builder,
    double initialSize = 0.5,
    double minSize = 0.25,
    double maxSize = 0.92,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      builder: (context, controller) =>
          _SheetSurface(child: builder(context, controller)),
    ),
  );
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.vertical(
      top: Radius.circular(AppTokens.radiusSheet),
    );
    if (context.isCupertino) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.82),
              border: Border(
                top: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      );
    }
    return Material(
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
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
