import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../adhan/application/adhan_providers.dart';
import '../../adhan/domain/adhan_voice.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Where everything in the app comes from, and on what terms: the Quran's
/// text, the Mushaf and its readings, the tafsir, the adhkar, every adhan
/// and dua recording (listed from the catalogue itself, so a new voice is
/// never left out), the prayer-time libraries, the fonts and the icons; and
/// the licences of the software libraries.
class AboutPage extends ConsumerWidget {
  /// Creates the page.
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final voices = ref.watch(adhanCatalogProvider).value ?? const [];
    return AppPageScaffold(
      title: l10n.creditsTitle,
      body: Builder(
        builder: (context) => SelectionArea(
          child: ListView(
            padding: pagePadding(context),
            children: [
              Text(
                l10n.sourcesIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              _Section(
                title: l10n.sourcesQuran,
                entries: [l10n.creditsTanzil, l10n.creditsMushafScript],
              ),
              _Section(
                title: l10n.sourcesMushaf,
                entries: [l10n.creditsImages, l10n.creditsRiwayat],
              ),
              _Section(
                title: l10n.sourcesAdhkar,
                entries: [l10n.creditsAdhkar],
              ),
              _Section(
                title: l10n.sourcesAudio,
                entries: [
                  l10n.creditsAudioIntro,
                  for (final voice in voices)
                    l10n.creditsAudioVoice(
                      voice.title(language),
                      voice.credit,
                      voice.sourceUrl,
                      _licence(l10n, voice),
                    ),
                  l10n.creditsAudioDuaShaarawy,
                  l10n.creditsAudioDuaMishary,
                ],
              ),
              _Section(
                title: l10n.sourcesPrayer,
                entries: [l10n.creditsPrayer],
              ),
              _Section(
                title: l10n.sourcesDesign,
                entries: [l10n.creditsQuranFont, l10n.creditsIcons],
              ),
              const SizedBox(height: AppTokens.spaceMedium),
              AppTileCard(
                icon: Icons.description_outlined,
                title: l10n.creditsLibraries,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A recording's licence, or that permission is still being asked for.
  static String _licence(AppLocalizations l10n, AdhanVoice voice) =>
      voice.license.name == 'Permission pending'
      ? l10n.creditsPermissionPending
      : voice.license.name;
}

/// A heading and its sources, one paragraph each, in a card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.entries});

  final String title;
  final List<String> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppTokens.spaceMedium),
      AppSectionHeader(title: title),
      AppCard(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, entry) in entries.indexed) ...[
              if (index > 0) const Divider(height: 24),
              Text(entry),
            ],
          ],
        ),
      ),
    ],
  );
}
