import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../adhan/application/adhan_providers.dart';
import '../../../l10n/generated/app_localizations.dart';

/// On what terms something in the app is used.
enum _Terms {
  /// An open licence, named on the tag.
  open,

  /// The publisher's own terms, which allow digital use with credit.
  publisher,

  /// Its owner's permission is asked for and has not come yet.
  pending,
}

/// One source: what it is and where it comes from, and on what terms.
class _Entry {
  const _Entry(this.text, this.terms, [this.licence]);

  final String text;
  final _Terms terms;

  /// The licence's name, for [_Terms.open].
  final String? licence;
}

/// Where everything in the app comes from, and on what terms: the Quran's
/// text, the Mushaf and its readings, the tafsir, the adhkar, every adhan
/// and dua recording (listed from the catalogue itself, so a new voice is
/// never left out), the reminder sounds, the prayer-time libraries, the fonts
/// and the icons; and the licences of the software libraries. Each entry
/// says on a tag whether it is under an open licence, the publisher's terms,
/// or still waiting for permission. Reached from the privacy settings.
class LicencesPage extends ConsumerWidget {
  /// Creates the page.
  const LicencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final voices = ref.watch(adhanCatalogProvider).value ?? const [];
    return AppPageScaffold(
      title: l10n.licencesTitle,
      body: Builder(
        builder: (context) => SelectionArea(
          child: ListView(
            padding: pagePadding(context),
            children: [
              Text(
                '${l10n.appTitle} · ${l10n.appVersion(AppConfig.version)}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.spaceSmall),
              Text(l10n.sourcesIntro, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppTokens.spaceSmall),
              Text(
                l10n.licencesLegend,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              _Section(
                title: l10n.sourcesQuran,
                entries: [
                  _Entry(l10n.creditsTanzil, _Terms.open, 'CC BY 3.0'),
                  _Entry(l10n.creditsMushafScript, _Terms.publisher),
                ],
              ),
              _Section(
                title: l10n.sourcesMushaf,
                entries: [
                  _Entry(l10n.creditsImages, _Terms.publisher),
                  _Entry(l10n.creditsRiwayat, _Terms.publisher),
                ],
              ),
              _Section(
                title: l10n.sourcesAdhkar,
                entries: [
                  _Entry(l10n.creditsAdhkar, _Terms.open, 'MIT · Unlicense'),
                ],
              ),
              _Section(
                title: l10n.sourcesAudio,
                entries: [
                  _Entry(l10n.creditsAudioIntro, _Terms.pending),
                  for (final voice in voices)
                    _Entry(
                      l10n.creditsAudioVoice(
                        voice.title(language),
                        voice.credit,
                        voice.sourceUrl,
                        _licence(l10n, voice.license.name),
                      ),
                      voice.license.name == _pendingName
                          ? _Terms.pending
                          : _Terms.open,
                      voice.license.name,
                    ),
                  _Entry(l10n.creditsAudioDuaMishary, _Terms.pending),
                  _Entry(l10n.creditsAudioDuaShaarawy, _Terms.pending),
                  _Entry(l10n.creditsAudioIqama, _Terms.pending),
                  _Entry(l10n.creditsAudioNear, _Terms.pending),
                ],
              ),
              _Section(
                title: l10n.sourcesPrayer,
                entries: [_Entry(l10n.creditsPrayer, _Terms.open, 'MIT · BSD')],
              ),
              _Section(
                title: l10n.sourcesDesign,
                entries: [
                  _Entry(l10n.creditsQuranFont, _Terms.open, 'OFL 1.1'),
                  _Entry(l10n.creditsIcons, _Terms.open, 'Apache 2.0'),
                  _Entry(l10n.creditsBrandFont, _Terms.open, 'OFL 1.1'),
                ],
              ),
              const SizedBox(height: AppTokens.spaceMedium),
              AppTileCard(
                icon: Icons.description_outlined,
                title: l10n.creditsLibraries,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: AppConfig.version,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// How the catalogue marks a recording whose permission is asked for.
  static const String _pendingName = 'Permission pending';

  /// A recording's licence, or that permission is still being asked for.
  static String _licence(AppLocalizations l10n, String name) =>
      name == _pendingName ? l10n.creditsPermissionPending : name;
}

/// A heading and its sources, one paragraph each with its terms, in a card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.entries});

  final String title;
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppTokens.spaceMedium),
        AppSectionHeader(title: title),
        AppCard(
          padding: const EdgeInsetsDirectional.all(AppTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, entry) in entries.indexed) ...[
                if (index > 0) const Divider(height: 24),
                switch (entry.terms) {
                  _Terms.open => AppTag(
                    entry.licence ?? l10n.licenceOpen,
                    icon: Icons.verified_outlined,
                    tone: AppTagTone.primary,
                  ),
                  _Terms.publisher => AppTag(
                    l10n.licencePublisher,
                    icon: Icons.handshake_outlined,
                    tone: AppTagTone.secondary,
                  ),
                  _Terms.pending => AppTag(
                    l10n.creditsPermissionPending,
                    icon: Icons.hourglass_top_rounded,
                  ),
                },
                const SizedBox(height: AppTokens.spaceSmall),
                Text(entry.text),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
