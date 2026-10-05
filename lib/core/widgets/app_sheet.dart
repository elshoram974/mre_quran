import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Shared bottom sheet.
///
/// Short content gets a sheet sized to the content; drag it down to dismiss.
/// Long content ([expandable]) gets a draggable sheet that snaps between half
/// and almost full height and scrolls its body.
///
/// iOS draws a floating, frosted glass panel. Android draws the Material 3
/// container. The body is a plain, non-scrolling widget.
abstract final class AppSheet {
  /// Shows a sheet and returns the value it is popped with.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool expandable = false,
  }) {
    final cupertino = context.isCupertino;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: cupertino ? 0.2 : 0.32),
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (sheetContext) {
        if (!expandable) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
            ),
            child: _SheetSurface(
              // Clamping physics: short content does not claim the drag, so
              // dragging the sheet down still dismisses it.
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: builder(sheetContext),
              ),
            ),
          );
        }
        return DraggableScrollableSheet(
          expand: false,
          snap: true,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          builder: (context, controller) => _SheetSurface(
            child: SingleChildScrollView(
              controller: controller,
              child: builder(context),
            ),
          ),
        );
      },
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Handle(),
        Flexible(child: child),
      ],
    );
    if (!context.isCupertino) {
      return Material(
        color: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTokens.radiusSheetFloating);
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sheetInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRSuperellipse(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: scheme.surface.withValues(alpha: dark ? 0.72 : 0.78),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? 0.12 : 0.55),
                ),
              ),
              child: Material(type: MaterialType.transparency, child: body),
            ),
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant
              .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}
