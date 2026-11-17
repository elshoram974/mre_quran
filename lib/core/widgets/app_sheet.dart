import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Shared bottom sheet.
///
/// [initialSize] is the share of the screen an expandable sheet opens at.
/// Short content gets a sheet sized to the content. Long content
/// ([expandable]) gets a draggable sheet that snaps between half and almost
/// full height and scrolls its body.
///
/// Every sheet closes the same way: drag it down from anywhere. Once what it
/// holds is scrolled to the top, pulling further down takes the sheet with
/// the finger, and letting go far enough down, or with a flick, closes it.
///
/// iOS draws a floating liquid glass panel. Android draws the Material 3
/// container. The body is a plain, non-scrolling widget.
///
/// The sheet always sits above the on-screen keyboard: it is lifted by the
/// keyboard height and shrinks to the room left, and its body scrolls when
/// that room is short.
abstract final class AppSheet {
  /// Smallest and largest share of the screen a draggable sheet takes.
  static const double _minSize = 0.3;
  static const double _maxSize = 0.92;

  /// Shows a tall sheet whose body fills it and lays itself out: a header
  /// that stays, a part that scrolls, a bar pinned at the bottom.
  ///
  /// The body gets the sheet's scroll controller and must give it to the one
  /// part that scrolls; dragging that part at its top then moves the sheet.
  /// Wrap a part that does not scroll in [AppSheetDragArea] to let it drag
  /// the sheet too. The handle always does.
  static Future<T?> showFilling<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, ScrollController scroll)
    builder,
    double initialSize = 0.88,
  }) => _present<T>(
    context,
    (_) => _FillingSheetHost(initialSize: initialSize, builder: builder),
  );

  /// Shows a sheet and returns the value it is popped with.
  ///
  /// [above] floats over the dimmed screen just above the sheet, outside
  /// it: what the sheet acts on, shown where the person can see it.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool expandable = false,
    double initialSize = 0.6,
    Widget? above,
  }) => _present<T>(context, (context) {
    if (expandable) {
      return _FillingSheetHost(
        initialSize: initialSize,
        builder: (context, scroll) => SingleChildScrollView(
          controller: scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: builder(context),
        ),
      );
    }
    // The room left above the keyboard and the status bar.
    final media = MediaQuery.of(context);
    final room =
        media.size.height - media.viewInsets.bottom - media.padding.top;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: room * 0.9),
      child: _PullToClose(
        above: above,
        builder: (scroll) => _SheetSurface(
          // Clamping physics: short content does not claim the drag, so
          // dragging the sheet down still dismisses it, and long content
          // reports the pull past its top that moves the sheet.
          child: SingleChildScrollView(
            controller: scroll,
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: builder(context),
          ),
        ),
      ),
    );
  });

  static Future<T?> _present<T>(BuildContext context, WidgetBuilder sheet) {
    final cupertino = context.isCupertino;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      // The sheet draws its own handle, on glass and on Material alike.
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: cupertino ? 0.2 : 0.32),
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (sheetContext) => _KeyboardLift(child: Builder(builder: sheet)),
    );
  }
}

/// Lets a sheet sized to its content follow the finger down once its body
/// is scrolled to the top, and close when let go far enough down or with a
/// flick. A short body that does not scroll is dragged by the sheet itself.
class _PullToClose extends StatefulWidget {
  const _PullToClose({required this.builder, this.above});

  final Widget Function(ScrollController scroll) builder;
  final Widget? above;

  @override
  State<_PullToClose> createState() => _PullToCloseState();
}

class _PullToCloseState extends State<_PullToClose>
    with SingleTickerProviderStateMixin {
  /// A pull longer than this share of the sheet closes it.
  static const double _closeShare = 0.25;

  /// A downward flick faster than this, in pixels a second, closes it.
  static const double _closeFling = 700;

  final ScrollController _scroll = ScrollController();
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: AppTokens.motionMedium,
  );
  final GlobalKey _surface = GlobalKey();
  double _pull = 0;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _back.addListener(() => setState(() => _pull = _from * (1 - _back.value)));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _back.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    switch (notification) {
      // Pulled down past the top: the sheet follows the finger.
      case OverscrollNotification(:final overscroll, dragDetails: _?)
          when overscroll < 0:
        _back.stop();
        setState(() => _pull -= overscroll);
      // Pushed back up while pulled down: the sheet goes up first.
      case ScrollUpdateNotification(:final scrollDelta?, dragDetails: _?)
          when _pull > 0 && scrollDelta > 0:
        setState(() => _pull = (_pull - scrollDelta).clamp(0, double.infinity));
        _scroll.jumpTo(0);
      case ScrollEndNotification(:final dragDetails) when _pull > 0:
        final height = _surface.currentContext?.size?.height ?? 0;
        final velocity = dragDetails?.primaryVelocity ?? 0;
        if (velocity > _closeFling || _pull > height * _closeShare) {
          Navigator.of(context).maybePop();
          break;
        }
        _from = _pull;
        if (MediaQuery.disableAnimationsOf(context)) {
          setState(() => _pull = 0);
        } else {
          _back.forward(from: 0);
        }
      default:
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final above = widget.above;
    return Transform.translate(
      offset: Offset(0, _pull),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (above != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppTokens.gutterCompact,
                0,
                AppTokens.gutterCompact,
                AppTokens.spaceSmall,
              ),
              child: above,
            ),
          Flexible(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: KeyedSubtree(
                key: _surface,
                child: widget.builder(_scroll),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets a part of a filling sheet that does not scroll, such as its header,
/// drag the sheet: up to make it taller, down to shrink it and then close
/// it. Use it inside [AppSheet.showFilling]; elsewhere it is just [child].
class AppSheetDragArea extends StatelessWidget {
  /// Creates a drag area over [child].
  const AppSheetDragArea({super.key, required this.child});

  /// What the person drags.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheet = _FillingSheet.maybeOf(context);
    if (sheet == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) => sheet.dragBy(details.primaryDelta!),
      onVerticalDragEnd: (details) => sheet.settle(
        context,
        details.primaryVelocity ?? 0,
        animate: !MediaQuery.disableAnimationsOf(context),
      ),
      child: child,
    );
  }
}

/// The size controller of a filling sheet, for [AppSheetDragArea].
class _FillingSheet extends InheritedWidget {
  const _FillingSheet({
    required this.controller,
    required this.restSize,
    required super.child,
  });

  final DraggableScrollableController controller;

  /// The size the sheet opened at.
  final double restSize;

  /// Below this share of the screen a released sheet closes.
  static const double _closeBelow = 0.5;

  /// A downward fling faster than this, in pixels a second, closes the
  /// sheet.
  static const double _closeFling = 900;

  static _FillingSheet? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_FillingSheet>();

  void dragBy(double pixels) {
    if (!controller.isAttached || controller.size <= 0) return;
    final full = controller.pixels / controller.size;
    controller.jumpTo(
      (controller.size - pixels / full).clamp(
        AppSheet._minSize,
        AppSheet._maxSize,
      ),
    );
  }

  void settle(BuildContext context, double velocity, {required bool animate}) {
    if (!controller.isAttached) return;
    if (velocity > _closeFling || controller.size < _closeBelow) {
      Navigator.of(context).maybePop();
      return;
    }
    final target = controller.size > (restSize + AppSheet._maxSize) / 2
        ? AppSheet._maxSize
        : restSize;
    if (animate) {
      controller.animateTo(
        target,
        duration: AppTokens.motionMedium,
        curve: Curves.easeOutCubic,
      );
    } else {
      controller.jumpTo(target);
    }
  }

  @override
  bool updateShouldNotify(_FillingSheet old) =>
      old.controller != controller || old.restSize != restSize;
}

class _FillingSheetHost extends StatefulWidget {
  const _FillingSheetHost({required this.initialSize, required this.builder});

  final double initialSize;
  final Widget Function(BuildContext context, ScrollController scroll) builder;

  @override
  State<_FillingSheetHost> createState() => _FillingSheetHostState();
}

class _FillingSheetHostState extends State<_FillingSheetHost> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Closes the sheet when the body's drag lets it go far enough down, as
  /// the handle does.
  bool _onScrollEnd(ScrollEndNotification notification) {
    if (notification.dragDetails == null || !_controller.isAttached) {
      return false;
    }
    if (_controller.size < _FillingSheet._closeBelow) {
      Navigator.of(context).maybePop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => _FillingSheet(
    controller: _controller,
    restSize: widget.initialSize,
    child: NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: DraggableScrollableSheet(
        controller: _controller,
        expand: false,
        snap: true,
        snapSizes: [widget.initialSize],
        initialChildSize: widget.initialSize,
        minChildSize: AppSheet._minSize,
        maxChildSize: AppSheet._maxSize,
        builder: (context, scroll) =>
            _SheetSurface(fill: true, child: widget.builder(context, scroll)),
      ),
    ),
  );
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
  const _SheetSurface({required this.child, this.fill = false});

  final Widget child;

  /// Whether the body takes all the sheet's height, not only what it needs.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Column(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetDragArea(child: _Handle()),
        Flexible(fit: fill ? FlexFit.tight : FlexFit.loose, child: child),
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
