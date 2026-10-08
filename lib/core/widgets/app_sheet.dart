import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Shared bottom sheet.
///
/// [initialSize] is the share of the screen an expandable sheet opens at.
/// Short content gets a sheet sized to the content; drag it down to dismiss.
/// Long content ([expandable]) gets a draggable sheet that snaps between half
/// and almost full height and scrolls its body.
///
/// iOS draws a floating liquid glass panel. Android draws the Material 3
/// container. The body is a plain, non-scrolling widget.
///
/// The sheet always sits above the on-screen keyboard: it is lifted by the
/// keyboard height and shrinks to the room left, and its body scrolls when
/// that room is short. Drag the handle or the sheet down to dismiss, with the
/// keyboard open or closed.
abstract final class AppSheet {
  /// Shows a sheet and returns the value it is popped with.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool expandable = false,
    double initialSize = 0.6,
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
      builder: (sheetContext) => _KeyboardLift(
        child: Builder(
          builder: (context) {
            if (!expandable) {
              // The room left above the keyboard and the status bar.
              final media = MediaQuery.of(context);
              final room =
                  media.size.height -
                  media.viewInsets.bottom -
                  media.padding.top;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: room * 0.9),
                child: _SheetSurface(
                  // Clamping physics: short content does not claim the drag,
                  // so dragging the sheet down still dismisses it.
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: builder(context),
                  ),
                ),
              );
            }
            return DraggableScrollableSheet(
              expand: false,
              snap: true,
              initialChildSize: initialSize,
              minChildSize: 0.3,
              maxChildSize: 0.92,
              builder: (context, controller) => _SheetSurface(
                child: SingleChildScrollView(
                  controller: controller,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: builder(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lifts its child by the keyboard height and tells the content the keyboard
/// is accounted for, so a sheet never sits under the keyboard.
class _KeyboardLift extends StatelessWidget {
  const _KeyboardLift({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: MediaQuery(
        data: media.removeViewInsets(removeBottom: true),
        child: child,
      ),
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
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sheetInset),
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.premium,
        settings: LiquidGlassSettings(
          blur: 16,
          glassColor: scheme.surface.withValues(alpha: 0.45),
        ),
        shape: const LiquidRoundedSuperellipse(
          borderRadius: AppTokens.radiusSheetFloating,
        ),
        child: Material(type: MaterialType.transparency, child: body),
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
