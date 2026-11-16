import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// A pill on the Mushaf page: the surah, the juz, or the page number. Light
/// paper-coloured fill with a thin ink outline, so it reads as part of the
/// page and never as a toolbar over it.
class ReaderChip extends StatelessWidget {
  /// Creates a chip showing [label], or [icon] when [label] is null.
  const ReaderChip({
    super.key,
    this.label,
    this.icon,
    required this.tooltip,
    required this.onPressed,
  }) : assert((label == null) != (icon == null));

  /// Text shown.
  final String? label;

  /// Icon shown instead of text.
  final IconData? icon;

  /// What the chip does, for screen readers and long press.
  final String tooltip;

  /// Called on tap.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = StadiumBorder(
      side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
    );
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label == null ? tooltip : '$label, $tooltip',
        excludeSemantics: true,
        // The visible pill is small; the touch target is the full 48 dp.
        child: SizedBox(
          height: AppTokens.minTarget,
          child: Center(
            child: Material(
              color: scheme.secondaryContainer.withValues(alpha: 0.7),
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                customBorder: shape,
                child: SizedBox(
                  height: AppTokens.readerChipHeight,
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: label == null ? 4 : 14,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: label == null
                          // The Mushaf turns right to left in every language,
                          // so its arrows are never mirrored.
                          ? Directionality(
                              textDirection: TextDirection.ltr,
                              child: Icon(
                                icon,
                                size: 22,
                                color: scheme.primary,
                              ),
                            )
                          : Text(
                              label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                    ),
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

/// The row above the Mushaf page: the surah with a step to the next surah
/// and search at the start, the index in the middle, and the juz and a page
/// bookmark at the end. It sits in the room the page frame keeps for it.
class ReaderHeader extends StatelessWidget {
  /// Creates the header.
  const ReaderHeader({
    super.key,
    required this.start,
    required this.middle,
    required this.end,
  });

  /// Items at the reading start (right in Arabic).
  final List<Widget> start;

  /// The item in the middle.
  final Widget middle;

  /// Items at the reading end.
  final List<Widget> end;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    // The row has fixed room above the page.
    maxScaleFactor: 1.3,
    child: SizedBox(
      height: AppTokens.readerHeaderExtent,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Row(children: [for (final item in start) _fit(item)]),
            ),
            middle,
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [for (final item in end) _fit(item)],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A text chip gives way when the row is short; buttons keep their size.
Widget _fit(Widget item) =>
    item is ReaderChip && item.label != null ? Flexible(child: item) : item;

/// The row below the Mushaf page: the page number in the middle, with a step
/// to the previous page on its right and to the next on its left. The Mushaf
/// turns right to left in every language, so the sides never swap.
class ReaderFooter extends StatelessWidget {
  /// Creates the footer.
  const ReaderFooter({super.key, required this.children});

  /// The chips, from the right: previous, number, next.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.3,
    child: SizedBox(
      height: AppTokens.readerFooterExtent,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// A raised, rounded surface floating over the page: the reader's toolbar
/// and controls. Opaque on every platform, since glass never goes over the
/// Quran text.
class ReaderFloatingSurface extends StatelessWidget {
  /// Creates the surface around [child].
  const ReaderFloatingSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: 4),
  });

  /// Content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The toolbar that floats at the top while the reader's bars show: the
/// index, a search field, and the page bookmark.
class ReaderToolbar extends StatelessWidget {
  /// Creates the toolbar.
  const ReaderToolbar({
    super.key,
    required this.menu,
    required this.searchLabel,
    required this.onSearch,
    required this.actions,
  });

  /// The leading button.
  final Widget menu;

  /// Placeholder of the search field.
  final String searchLabel;

  /// Opens search.
  final VoidCallback onSearch;

  /// Trailing buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ReaderFloatingSurface(
        child: SizedBox(
          height: AppTokens.minTarget + 8,
          child: Row(
            children: [
              menu,
              Expanded(
                child: Semantics(
                  button: true,
                  label: searchLabel,
                  excludeSemantics: true,
                  child: Material(
                    color: scheme.surfaceContainerHigh,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onSearch,
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                searchLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
