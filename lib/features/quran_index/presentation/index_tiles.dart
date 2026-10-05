import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/quran_metadata.dart';

/// A row of the surah list.
class SurahTile extends StatelessWidget {
  /// Creates a row for [surah].
  const SurahTile({
    super.key,
    required this.surah,
    required this.digits,
    required this.onTap,
  });

  /// Surah to show.
  final Surah surah;

  /// Formats numbers for display.
  final String Function(int) digits;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final revelation = surah.revelation == Revelation.meccan
        ? l10n.revelationMeccan
        : l10n.revelationMedinan;
    return IndexRow(
      number: digits(surah.number),
      title: surah.arabicName,
      subtitle:
          '${l10n.ayahCount(surah.ayahCount, digits(surah.ayahCount))} · $revelation',
      page: l10n.pageNumber(digits(surah.startPage)),
      onTap: onTap,
    );
  }
}

/// A row of the juz list.
class JuzTile extends StatelessWidget {
  /// Creates a row for [juz] starting in the surah named [surahName].
  const JuzTile({
    super.key,
    required this.juz,
    required this.surahName,
    required this.digits,
    required this.onTap,
  });

  /// Juz to show.
  final Juz juz;

  /// Arabic name of the surah the juz starts in.
  final String surahName;

  /// Formats numbers for display.
  final String Function(int) digits;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IndexRow(
      number: digits(juz.number),
      title: l10n.juzTitle(digits(juz.number)),
      subtitle: l10n.juzStartsAt(surahName, digits(juz.ayah)),
      page: l10n.pageNumber(digits(juz.startPage)),
      onTap: onTap,
    );
  }
}

/// A numbered row of the index and of search results.
class IndexRow extends StatelessWidget {
  /// Creates a row.
  const IndexRow({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.page,
    required this.onTap,
  });

  /// Number in the badge, already formatted.
  final String number;

  /// Main line.
  final String title;

  /// Second line.
  final String subtitle;

  /// Page label at the end.
  final String page;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTokens.radiusField),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    number,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  page,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
