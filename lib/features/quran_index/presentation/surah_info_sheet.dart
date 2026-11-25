import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_directional_icon.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_tag.dart';
import '../../mushaf/presentation/asbab_sheet.dart';
import '../../quran_text/application/asbab_provider.dart';
import '../domain/quran_metadata.dart';
import 'index_tiles.dart';

/// Shows what there is to know about [surah]: where it was revealed, how many
/// ayahs, its place in the Mushaf and in the order of revelation, the surahs
/// revealed just before and after it, its pages and juz. Returns true when the
/// person chose to read it.
Future<bool> showSurahInfo(
  BuildContext context, {
  required QuranMetadata metadata,
  required Surah surah,
  required String Function(int) digits,
}) async =>
    await AppSheet.show<bool>(
      context: context,
      builder: (context) =>
          SurahInfo(metadata: metadata, surah: surah, digits: digits),
    ) ??
    false;

/// The content of the surah sheet.
class SurahInfo extends ConsumerWidget {
  /// Creates the facts of [surah].
  const SurahInfo({
    super.key,
    required this.metadata,
    required this.surah,
    required this.digits,
  });

  /// Quran structure, for the pages, the juz and the order of revelation.
  final QuranMetadata metadata;

  /// The surah.
  final Surah surah;

  /// Formats numbers for display.
  final String Function(int) digits;

  /// The surah revealed at [order], if there is one.
  Surah? _revealed(int order) {
    for (final other in metadata.surahs) {
      if (other.revelationOrder == order) return other;
    }
    return null;
  }

  String _range(BuildContext context, int from, int to) => from == to
      ? digits(from)
      : context.l10n.surahInfoRange(digits(from), digits(to));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final withOccasions =
        ref.watch(asbabProvider).value?.inSurah(surah.number) ?? const [];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = AyahRef(surah.number, surah.ayahCount);
    final endPage = metadata.pageOf(last.surah, last.ayah);
    final firstJuz = metadata.juzOf(AyahRef(surah.number, 1));
    final lastJuz = metadata.juzOf(last);
    final before = _revealed(surah.revelationOrder - 1);
    final after = _revealed(surah.revelationOrder + 1);
    final english = Localizations.localeOf(context).languageCode == 'en';

    Widget fact(String label, String value) => ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    // The sheet scrolls its content itself.
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.surahTitle(surah.arabicName),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: AppTokens.quranFontFamily,
              color: scheme.primary,
              height: 1.8,
            ),
          ),
          Text(
            english
                ? '${surah.transliteration} · ${surah.englishName}'
                : surah.transliteration,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMedium),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              RevelationTag(surah),
              AppTag(
                l10n.ayahCount(surah.ayahCount, digits(surah.ayahCount)),
                tone: AppTagTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMedium),
          AppGroupCard(
            children: [
              fact(l10n.surahInfoMushafOrder, digits(surah.number)),
              fact(
                l10n.surahInfoRevelationOrder,
                digits(surah.revelationOrder),
              ),
              fact(
                l10n.surahInfoPlace,
                surah.revelation == Revelation.meccan
                    ? l10n.revelationMeccan
                    : l10n.revelationMedinan,
              ),
              fact(l10n.surahInfoAyahs, digits(surah.ayahCount)),
              fact(
                l10n.surahInfoPages,
                _range(context, surah.startPage, endPage),
              ),
              fact(l10n.surahInfoJuz, _range(context, firstJuz, lastJuz)),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMedium),
          AppGroupCard(
            children: [
              if (before == null)
                ListTile(title: Text(l10n.surahInfoFirst))
              else
                fact(l10n.surahInfoAfter, l10n.surahTitle(before.arabicName)),
              if (after == null)
                ListTile(title: Text(l10n.surahInfoLast))
              else
                fact(l10n.surahInfoBefore, l10n.surahTitle(after.arabicName)),
            ],
          ),
          // The occasions of revelation of its ayahs that have one.
          if (withOccasions.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spaceMedium),
            AppGroupCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_edu_outlined),
                  title: Text(l10n.surahAsbab),
                  subtitle: Text(
                    l10n.surahAsbabCount(
                      withOccasions.length,
                      digits(withOccasions.length),
                    ),
                  ),
                  trailing: const AppForwardChevron(),
                  onTap: () => showAsbab(
                    context,
                    ayahs: withOccasions,
                    place: l10n.surahTitle(surah.arabicName),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.spaceSmall),
          Text(
            l10n.surahInfoOrderNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMedium),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(l10n.surahInfoOpen),
          ),
        ],
      ),
    );
  }
}
