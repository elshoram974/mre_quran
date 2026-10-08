import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../settings/application/digits_provider.dart';
import '../application/passage_text.dart';
import '../domain/dhikr.dart';

/// Shows the evidence behind a dhikr: its source, virtue, and hadith.
abstract final class EvidenceSheet {
  /// Opens the sheet for [dhikr].
  static Future<void> show(BuildContext context, Dhikr dhikr) =>
      AppSheet.show<void>(
        context: context,
        expandable: true,
        builder: (context) => _EvidenceBody(dhikr: dhikr),
      );
}

class _EvidenceBody extends ConsumerWidget {
  const _EvidenceBody({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final passage = dhikr.quran;
    final quran = passage == null
        ? null
        : ref
              .watch(quranTextProvider)
              .whenData((text) => describePassage(passage, text, digits))
              .value;
    final theme = Theme.of(context);
    final sections = <(String, String)>[
      if (quran != null) (l10n.adhkarQuranLabel, quran),
      (l10n.adhkarSourceLabel, dhikr.source),
      if (dhikr.virtue != null) (l10n.adhkarVirtueLabel, dhikr.virtue!),
      if (dhikr.hadithText != null) (l10n.adhkarHadithLabel, dhikr.hadithText!),
      if (dhikr.vocabulary != null)
        (l10n.adhkarVocabularyLabel, dhikr.vocabulary!),
    ];
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutterCompact,
        4,
        AppTokens.gutterCompact,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adhkarEvidence, style: theme.textTheme.titleLarge),
          for (final (label, text) in sections) ...[
            const SizedBox(height: 20),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            // The evidence is Arabic whatever the interface language is.
            Directionality(
              textDirection: TextDirection.rtl,
              child: SelectableText(
                text,
                style: TextStyle(
                  fontFamily: AppTokens.quranFontFamily,
                  fontSize: 19,
                  height: 1.9,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
