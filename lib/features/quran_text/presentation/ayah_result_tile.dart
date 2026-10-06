import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';

/// A search result: where the ayah is, and its text with tashkeel.
class AyahResultTile extends StatelessWidget {
  /// Creates a tile for an ayah of [surahName].
  const AyahResultTile({
    super.key,
    required this.surahName,
    required this.ayahNumber,
    required this.page,
    required this.text,
    required this.onTap,
  });

  /// Arabic surah name.
  final String surahName;

  /// Ayah number, already formatted for display.
  final String ayahNumber;

  /// Page number, already formatted for display.
  final String page;

  /// Display text of the ayah.
  final String text;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTokens.radiusField),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$surahName · ${l10n.ayahNumber(ayahNumber)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    l10n.pageNumber(page),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                // Quranic marks (small high letters, sukun, pause signs)
                // need the Quran font; a UI font draws them detached.
                style: TextStyle(
                  fontFamily: AppTokens.quranFontFamily,
                  fontSize: 20,
                  height: 1.9,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
