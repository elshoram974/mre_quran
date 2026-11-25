import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Shared way to pick one of a few places or modes: a track in which the chosen
/// one sits on a filled pill in the accent colour, its label bold, the others
/// plain. Liquid glass on iOS, Material elsewhere.
///
/// The segments share the width equally when every label fits; otherwise the
/// track scrolls sideways, each segment as wide as its label, and the chosen
/// one is brought into view.
class AppSegmentedControl<T extends Object> extends StatelessWidget {
  /// Creates a control for [segments] with [value] selected.
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  /// Value to label, in display order.
  final Map<T, String> segments;

  /// Selected value.
  final T value;

  /// Called with the chosen value.
  final ValueChanged<T> onChanged;

  /// Room on each side of a label in a track that scrolls.
  static const double _labelPadding = 14;

  /// The least room on each side of a label when the segments share the
  /// width; they are centred in their share, so there is more.
  static const double _tightPadding = 6;

  /// Room between the track and the pills.
  static const double _inset = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.labelLarge ?? const TextStyle();
    final selectedStyle = base.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onPrimary,
    );
    final unselectedStyle = base.copyWith(
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = _fits(context, constraints.maxWidth, selectedStyle);
        if (context.isCupertino) {
          return _GlassSegments<T>(
            segments: segments,
            value: value,
            onChanged: onChanged,
            scrollable: !fits,
            selectedStyle: selectedStyle,
            unselectedStyle: unselectedStyle,
          );
        }
        return _MaterialSegments<T>(
          segments: segments,
          value: value,
          onChanged: onChanged,
          scrollable: !fits,
          selectedStyle: selectedStyle,
          unselectedStyle: unselectedStyle,
        );
      },
    );
  }

  /// Whether every label fits in an equal share of [width], in the bold
  /// style it takes when chosen, at the person's text size.
  bool _fits(BuildContext context, double width, TextStyle style) {
    if (!width.isFinite) return false;
    final share = (width - 2 * _inset) / segments.length - 2 * _tightPadding;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    for (final label in segments.values) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final wide = painter.width > share;
      painter.dispose();
      if (wide) return false;
    }
    return true;
  }
}

/// Android and the rest: a tonal track with a filled pill under the choice.
class _MaterialSegments<T extends Object> extends StatelessWidget {
  const _MaterialSegments({
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.scrollable,
    required this.selectedStyle,
    required this.unselectedStyle,
  });

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool scrollable;
  final TextStyle selectedStyle;
  final TextStyle unselectedStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTokens.motionMedium;
    final children = [
      for (final MapEntry(:key, value: label) in segments.entries)
        _Segment(
          label: label,
          selected: key == value,
          scrollable: scrollable,
          duration: duration,
          selectedStyle: selectedStyle,
          unselectedStyle: unselectedStyle,
          onTap: () => onChanged(key),
        ),
    ];
    final track = Container(
      constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
      padding: const EdgeInsets.all(AppSegmentedControl._inset),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: scrollable
          ? IntrinsicHeight(child: Row(children: children))
          : Row(
              children: [for (final child in children) Expanded(child: child)],
            ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: scrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: track,
            )
          : track,
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.scrollable,
    required this.duration,
    required this.selectedStyle,
    required this.unselectedStyle,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool scrollable;
  final Duration duration;
  final TextStyle selectedStyle;
  final TextStyle unselectedStyle;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  @override
  void didUpdateWidget(_Segment old) {
    super.didUpdateWidget(old);
    // A chosen segment out of view, in a track that scrolls, is brought in.
    if (widget.selected && !old.selected && widget.scrollable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: widget.duration,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        decoration: ShapeDecoration(
          color: selected
              ? scheme.primary
              : scheme.primary.withValues(alpha: 0),
          shape: const StadiumBorder(),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: selected ? null : widget.onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.scrollable
                    ? AppSegmentedControl._labelPadding
                    : AppSegmentedControl._tightPadding,
                vertical: 10,
              ),
              child: Center(
                widthFactor: 1,
                child: AnimatedDefaultTextStyle(
                  duration: widget.duration,
                  style: selected
                      ? widget.selectedStyle
                      : widget.unselectedStyle,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: widget.scrollable ? null : TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS: the glass segmented control, its pill in the accent colour.
class _GlassSegments<T extends Object> extends StatelessWidget {
  const _GlassSegments({
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.scrollable,
    required this.selectedStyle,
    required this.unselectedStyle,
  });

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool scrollable;
  final TextStyle selectedStyle;
  final TextStyle unselectedStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The glass control lays its segments out left to right whatever the
    // language. In a right-to-left language the order is reversed instead,
    // so the first segment still sits at the start (the right).
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final entries = segments.entries.toList();
    final ordered = rtl ? entries.reversed.toList() : entries;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GlassSegmentedControl(
          segments: [
            for (final entry in ordered) GlassSegment(label: entry.value),
          ],
          selectedIndex: ordered.indexWhere((entry) => entry.key == value),
          onSegmentSelected: (index) => onChanged(ordered[index].key),
          height: AppTokens.minTarget,
          isScrollable: scrollable,
          backgroundColor: scheme.surfaceContainerHigh,
          indicatorColor: scheme.primary,
          selectedTextStyle: selectedStyle,
          unselectedTextStyle: unselectedStyle,
        ),
      ),
    );
  }
}
