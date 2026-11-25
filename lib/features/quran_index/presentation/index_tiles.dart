import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/press_scale.dart';
import '../domain/quran_metadata.dart';

/// The tag that says where [surah] was revealed: one colour for Meccan, another
/// for Medinan, so the two kinds tell apart at a glance down the list.
class RevelationTag extends StatelessWidget {
  /// Creates the tag of [surah].
  const RevelationTag(this.surah, {super.key});

  /// The surah.
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (surah.revelation) {
      Revelation.meccan => AppTag(
        l10n.revelationMeccan,
        tone: AppTagTone.primary,
      ),
      Revelation.medinan => AppTag(
        l10n.revelationMedinan,
        tone: AppTagTone.accent,
      ),
    };
  }
}

/// A row of the surah list: its number, its name, where it was revealed, how
/// many ayahs it has and its place in the order of revelation, the page it
/// begins on, and a button for more about it.
class SurahTile extends StatelessWidget {
  /// Creates a row for [surah].
  const SurahTile({
    super.key,
    required this.surah,
    required this.digits,
    required this.onTap,
    this.onInfo,
    this.current = false,
  });

  /// Surah to show.
  final Surah surah;

  /// Formats numbers for display.
  final String Function(int) digits;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Opens more about the surah; no button when null.
  final VoidCallback? onInfo;

  /// Whether the reader is in this surah now.
  final bool current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IndexRow(
      number: digits(surah.number),
      title: surah.arabicName,
      tags: [
        RevelationTag(surah),
        AppTag(
          l10n.ayahCount(surah.ayahCount, digits(surah.ayahCount)),
          tone: AppTagTone.neutral,
        ),
        AppTag(
          l10n.revelationOrderTag(digits(surah.revelationOrder)),
          tone: AppTagTone.neutral,
        ),
      ],
      page: l10n.pageNumber(digits(surah.startPage)),
      onTap: onTap,
      current: current,
      info: onInfo == null
          ? null
          : IconButton(
              tooltip: l10n.surahInfo(surah.arabicName),
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: onInfo,
            ),
    );
  }
}

/// A row of the juz list: where it begins, and the words it begins with.
class JuzTile extends StatelessWidget {
  /// Creates a row for [juz] starting in the surah named [surahName].
  const JuzTile({
    super.key,
    required this.juz,
    required this.surahName,
    required this.digits,
    required this.onTap,
    this.opening,
    this.openingFont,
    this.current = false,
  });

  /// Juz to show.
  final Juz juz;

  /// Arabic name of the surah the juz starts in.
  final String surahName;

  /// Formats numbers for display.
  final String Function(int) digits;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// The first words of its first ayah, as the Mushaf prints them.
  final String? opening;

  /// The font of [opening].
  final String? openingFont;

  /// Whether the reader is in this juz now.
  final bool current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IndexRow(
      number: digits(juz.number),
      title: l10n.juzTitle(digits(juz.number)),
      subtitle: l10n.juzStartsAt(surahName, digits(juz.ayah)),
      opening: opening,
      openingFont: openingFont,
      page: l10n.pageNumber(digits(juz.startPage)),
      onTap: onTap,
      current: current,
    );
  }
}

/// A row of the hizb list: where it begins, and the words it begins with.
class HizbTile extends StatelessWidget {
  /// Creates a row for [hizb] starting in the surah named [surahName].
  const HizbTile({
    super.key,
    required this.hizb,
    required this.surahName,
    required this.digits,
    required this.onTap,
    this.opening,
    this.openingFont,
    this.current = false,
  });

  /// Hizb to show.
  final Hizb hizb;

  /// Arabic name of the surah the hizb starts in.
  final String surahName;

  /// Formats numbers for display.
  final String Function(int) digits;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// The first words of its first ayah, as the Mushaf prints them.
  final String? opening;

  /// The font of [opening].
  final String? openingFont;

  /// Whether the reader is in this hizb now.
  final bool current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IndexRow(
      number: digits(hizb.number),
      title: l10n.hizbTitle(digits(hizb.number)),
      subtitle: l10n.juzStartsAt(surahName, digits(hizb.ayah)),
      opening: opening,
      openingFont: openingFont,
      page: l10n.pageNumber(digits(hizb.startPage)),
      onTap: onTap,
      current: current,
    );
  }
}

/// A row of the sajda list.
class SajdaTile extends StatelessWidget {
  /// Creates a row for [sajda], in the surah named [surahName], in [juz].
  const SajdaTile({
    super.key,
    required this.sajda,
    required this.surahName,
    required this.juz,
    required this.digits,
    required this.onTap,
  });

  /// Sajda to show.
  final Sajda sajda;

  /// Arabic name of the surah it is in.
  final String surahName;

  /// The juz it is in.
  final int juz;

  /// Formats numbers for display.
  final String Function(int) digits;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IndexRow(
      number: digits(sajda.number),
      title: l10n.sajdaTitle(surahName),
      subtitle: l10n.sajdaAt(digits(sajda.ayah), digits(juz)),
      page: l10n.pageNumber(digits(sajda.startPage)),
      onTap: onTap,
    );
  }
}

/// The heading over a group of rows, such as the juz a pair of hizb belong
/// to.
class IndexSectionHeader extends StatelessWidget {
  /// Creates a heading reading [title].
  const IndexSectionHeader({super.key, required this.title});

  /// What the group is.
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, top: 14, bottom: 4),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(height: 1, color: scheme.outlineVariant)),
          ],
        ),
      ),
    );
  }
}

/// A numbered row of the index and of search results: the number in a star,
/// the title, then a line of text, the opening words of the place, or tags,
/// and the page at the end.
class IndexRow extends StatelessWidget {
  /// Creates a row.
  const IndexRow({
    super.key,
    required this.number,
    required this.title,
    this.subtitle,
    this.opening,
    this.openingFont,
    this.tags = const [],
    required this.page,
    required this.onTap,
    this.info,
    this.current = false,
  });

  /// Number in the badge, already formatted.
  final String number;

  /// Main line.
  final String title;

  /// Second line.
  final String? subtitle;

  /// The first words of the place, in the Mushaf's script.
  final String? opening;

  /// The font of [opening].
  final String? openingFont;

  /// Small facts under the title.
  final List<Widget> tags;

  /// Page label at the end.
  final String page;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// A button before the page label, such as one for more about the row.
  final Widget? info;

  /// Whether the reader is here now: the row is marked, and says so.
  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = this.subtitle;
    final opening = this.opening;
    // With large text the page goes under the title, so the title keeps the
    // row's width.
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= AppTokens.stackTextScale;
    final pageLabel = Text(
      page,
      style: theme.textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
    final tags = [
      if (current)
        AppTag(
          context.l10n.indexYouAreHere,
          icon: Icons.my_location_rounded,
          tone: AppTagTone.primary,
        ),
      ...this.tags,
    ];
    final radius = BorderRadius.circular(AppTokens.radiusField);
    return PressScale(
      child: Material(
        color: current ? scheme.secondaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: current
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            selected: current,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
                child: Row(
                  children: [
                    _NumberStar(number),
                    const SizedBox(width: AppTokens.spaceMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (opening != null) ...[
                            const SizedBox(height: AppTokens.spaceTiny),
                            Text(
                              opening,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: openingFont,
                                fontSize: theme.textTheme.titleMedium?.fontSize,
                                color: scheme.primary,
                                height: 1.6,
                              ),
                            ),
                          ],
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(spacing: 6, runSpacing: 6, children: tags),
                          ],
                          if (stacked) ...[
                            const SizedBox(height: AppTokens.spaceTiny),
                            pageLabel,
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSmall),
                    if (stacked)
                      ?info
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [?info, pageLabel],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A number in an eight-pointed star, as Mushafs number their surahs. It grows
/// with the text, up to half as large again, so a three-digit number fits.
class _NumberStar extends StatelessWidget {
  const _NumberStar(this.number);

  final String number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final side = 30.0 * scale;
    Widget square(double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(side / 6),
        ),
      ),
    );
    return SizedBox.square(
      dimension: side * math.sqrt2,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          square(0),
          square(math.pi / 4),
          Text(
            number,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
