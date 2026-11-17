import 'package:material_ui/material_ui.dart';

/// How raised surfaces (cards, the floating tab bar, hero panels) look in the
/// current theme: their fill, their hairline edge, and their soft shadow.
///
/// Light themes lift cards above the page with a whiter fill and a warm,
/// diffuse shadow; the dark theme lifts them with a lighter fill and a deeper
/// shadow. Read it with [AppSurfaceStyle.of].
@immutable
class AppSurfaceStyle extends ThemeExtension<AppSurfaceStyle> {
  /// Creates a surface style.
  const AppSurfaceStyle({
    required this.raised,
    required this.hairline,
    required this.raisedShadow,
    required this.floatingShadow,
  });

  /// Derives the style for [scheme]: cards sit on the lightest container in a
  /// light theme and on a lighter container than the page in a dark theme.
  factory AppSurfaceStyle.from(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return AppSurfaceStyle(
      raised: dark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
      hairline: scheme.outlineVariant.withValues(alpha: dark ? 0.6 : 0.7),
      raisedShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: dark ? 0.28 : 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      floatingShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: dark ? 0.4 : 0.12),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Fill of a raised card.
  final Color raised;

  /// Thin edge around a raised card.
  final Color hairline;

  /// Shadow under a card resting on the page.
  final List<BoxShadow> raisedShadow;

  /// Shadow under chrome that floats over content, such as the tab bar.
  final List<BoxShadow> floatingShadow;

  /// The style of the nearest theme.
  ///
  /// The style is a pure function of the colour scheme, so a theme built
  /// outside `AppTheme` (a test, a preview) gets the same derivation instead
  /// of an unverified default.
  static AppSurfaceStyle of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppSurfaceStyle>() ??
        AppSurfaceStyle.from(theme.colorScheme);
  }

  @override
  AppSurfaceStyle copyWith({
    Color? raised,
    Color? hairline,
    List<BoxShadow>? raisedShadow,
    List<BoxShadow>? floatingShadow,
  }) => AppSurfaceStyle(
    raised: raised ?? this.raised,
    hairline: hairline ?? this.hairline,
    raisedShadow: raisedShadow ?? this.raisedShadow,
    floatingShadow: floatingShadow ?? this.floatingShadow,
  );

  @override
  AppSurfaceStyle lerp(AppSurfaceStyle? other, double t) {
    if (other == null) return this;
    return AppSurfaceStyle(
      raised: Color.lerp(raised, other.raised, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      raisedShadow: BoxShadow.lerpList(raisedShadow, other.raisedShadow, t)!,
      floatingShadow: BoxShadow.lerpList(
        floatingShadow,
        other.floatingShadow,
        t,
      )!,
    );
  }
}
