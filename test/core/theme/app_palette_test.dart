import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/theme/app_palette.dart';
import 'package:mre_quran/core/theme/app_surface_style.dart';

/// WCAG contrast ratio between [a] and [b].
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final paper in AppPaper.values) {
    for (final accent in AppAccent.values) {
      final name = '${paper.name} + ${accent.name}';
      final scheme = AppPalette.scheme(paper, accent);
      group('$name meets WCAG AA', () {
        final raised = AppSurfaceStyle.from(scheme).raised;
        // Body text needs 4.5:1 on every surface it is drawn on.
        final pairs = <String, (Color, Color)>{
          'onSurface on surface': (scheme.onSurface, scheme.surface),
          'onSurface on card': (scheme.onSurface, raised),
          'onSurfaceVariant on surface': (
            scheme.onSurfaceVariant,
            scheme.surface,
          ),
          'onSurfaceVariant on card': (scheme.onSurfaceVariant, raised),
          'onSurfaceVariant on field': (
            scheme.onSurfaceVariant,
            scheme.surfaceContainerHighest,
          ),
          'primary on surface': (scheme.primary, scheme.surface),
          'primary on card': (scheme.primary, raised),
          'primary on primaryContainer': (
            scheme.primary,
            scheme.primaryContainer,
          ),
          'primary on surfaceContainerLow': (
            scheme.primary,
            scheme.surfaceContainerLow,
          ),
          'onPrimary on primary': (scheme.onPrimary, scheme.primary),
          'onPrimaryContainer on primaryContainer': (
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
          ),
          'onSecondaryContainer on secondaryContainer': (
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ),
          'onTertiaryContainer on tertiaryContainer': (
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
          ),
          'onError on error': (scheme.onError, scheme.error),
          'onInverseSurface on inverseSurface': (
            scheme.onInverseSurface,
            scheme.inverseSurface,
          ),
        };
        for (final MapEntry(key: pair, value: (fg, bg)) in pairs.entries) {
          test(pair, () {
            expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
          });
        }
      });
    }
  }
}
