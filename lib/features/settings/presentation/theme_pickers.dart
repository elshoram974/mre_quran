import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/settings_provider.dart';
import '../domain/app_settings.dart';

/// The localized name of [theme].
String pageThemeLabel(AppLocalizations l10n, AppThemePreference theme) =>
    switch (theme) {
      AppThemePreference.system => l10n.themeSystem,
      AppThemePreference.light => l10n.themeLight,
      AppThemePreference.white => l10n.themeWhite,
      AppThemePreference.sepia => l10n.themeSepia,
      AppThemePreference.green => l10n.themeGreen,
      AppThemePreference.dark => l10n.themeDark,
      AppThemePreference.black => l10n.themeBlack,
    };

/// The localized name of [accent].
String accentLabel(AppLocalizations l10n, AppAccent accent) => switch (accent) {
  AppAccent.gold => l10n.accentGold,
  AppAccent.emerald => l10n.accentEmerald,
  AppAccent.teal => l10n.accentTeal,
  AppAccent.blue => l10n.accentBlue,
  AppAccent.indigo => l10n.accentIndigo,
  AppAccent.rose => l10n.accentRose,
  AppAccent.crimson => l10n.accentCrimson,
  AppAccent.brown => l10n.accentBrown,
};

/// The page colour and accent choosers, under their headings. Used by
/// Settings and by the reader's display sheet, so both stay identical.
class ThemePickers extends ConsumerWidget {
  /// Creates both pickers.
  const ThemePickers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.pageTheme, style: text.titleSmall),
        const SizedBox(height: AppTokens.spaceSmall),
        _SwatchRow(
          children: [
            for (final theme in AppThemePreference.values)
              _PaperSwatch(
                theme: theme,
                accent: settings.accent,
                label: pageThemeLabel(l10n, theme),
                selected: theme == settings.theme,
                onTap: () => notifier.save(settings.copyWith(theme: theme)),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.cardPadding),
        Text(l10n.accentColor, style: text.titleSmall),
        Text(
          l10n.accentColorHint,
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.spaceSmall),
        _SwatchRow(
          children: [
            for (final accent in AppAccent.values)
              _AccentSwatch(
                accent: accent,
                label: accentLabel(l10n, accent),
                selected: accent == settings.accent,
                onTap: () => notifier.save(settings.copyWith(accent: accent)),
              ),
          ],
        ),
      ],
    );
  }
}

/// A row of swatches that wraps onto more lines on a narrow screen or with
/// large text, instead of scrolling sideways out of sight.
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppTokens.spaceSmall,
    runSpacing: AppTokens.spaceSmall,
    children: children,
  );
}

/// The shared tappable body of a swatch: at least a 48 dp target, one
/// screen-reader label with its selection, and a light tick on change.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  void _choose() {
    if (selected) return;
    onTap();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    // The node replaces its children's semantics, so it carries the tap
    // itself; otherwise a screen reader could hear a swatch but not choose it.
    onTap: _choose,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: InkResponse(
        onTap: _choose,
        radius: AppTokens.minTarget / 2,
        // At least a 48 dp target; a captioned swatch grows to hold its
        // caption, so the caption is part of the same target.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppTokens.minTarget,
            minHeight: AppTokens.minTarget,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    ),
  );
}

/// A circle of paper with a dot of ink and the accent, ringed when chosen.
class _PaperSwatch extends StatelessWidget {
  const _PaperSwatch({
    required this.theme,
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreference theme;
  final AppAccent accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = Theme.of(context).colorScheme;
    final day = AppPalette.scheme(theme.dayPaper, accent);
    final night = AppPalette.scheme(theme.nightPaper, accent);
    return _Swatch(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Ring(
            selected: selected,
            color: current.primary,
            // "System" is split: its day paper and its night paper.
            child: ClipOval(
              child: CustomPaint(
                size: const Size.square(AppTokens.badgeSmall),
                painter: _PaperPainter(
                  day: day.surface,
                  night: night.surface,
                  ink: day.primary,
                  edge: current.outlineVariant,
                ),
              ),
            ),
          ),
          SizedBox(
            width: AppTokens.minTarget + AppTokens.spaceMedium,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? current.primary : current.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A solid circle of the accent, as it shows on the current paper.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paper = theme.brightness == Brightness.dark
        ? AppPaper.navy
        : AppPaper.cream;
    final tone = AppPalette.scheme(paper, accent);
    return _Swatch(
      label: label,
      selected: selected,
      onTap: onTap,
      child: _Ring(
        selected: selected,
        color: tone.primary,
        child: Container(
          width: AppTokens.badgeSmall,
          height: AppTokens.badgeSmall,
          decoration: BoxDecoration(
            color: tone.primary,
            shape: BoxShape.circle,
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 20, color: tone.onPrimary)
              : null,
        ),
      ),
    );
  }
}

/// A ring around a chosen swatch: the second cue besides the label colour
/// and, on accents, the tick.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.selected,
    required this.color,
    required this.child,
  });

  final bool selected;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTokens.motionMedium,
    padding: const EdgeInsetsDirectional.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? color : Colors.transparent,
        width: 2,
      ),
    ),
    child: child,
  );
}

/// Draws a paper swatch: the day paper, and the night paper on the lower
/// half when they differ, with an accent dot for ink and a hairline edge.
class _PaperPainter extends CustomPainter {
  const _PaperPainter({
    required this.day,
    required this.night,
    required this.ink,
    required this.edge,
  });

  final Color day;
  final Color night;
  final Color ink;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = day);
    if (night != day) {
      canvas.drawRect(
        Rect.fromLTRB(0, size.height / 2, size.width, size.height),
        Paint()..color = night,
      );
    }
    canvas
      ..drawCircle(rect.center, size.width * 0.14, Paint()..color = ink)
      ..drawOval(
        rect.deflate(0.5),
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke,
      );
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.day != day ||
      old.night != night ||
      old.ink != ink ||
      old.edge != edge;
}
