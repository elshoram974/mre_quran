import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../domain/adhan_voice.dart';

/// Shows where a recording comes from and the licence it is shared under.
abstract final class VoiceInfoSheet {
  /// Opens the sheet for [voice].
  static Future<void> show(BuildContext context, AdhanVoice voice) =>
      AppSheet.show<void>(
        context: context,
        builder: (context) => _Body(voice: voice),
      );
}

class _Body extends StatelessWidget {
  const _Body({required this.voice});

  final AdhanVoice voice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutterCompact,
        4,
        AppTokens.gutterCompact,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(voice.title(language), style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          SelectableText(
            l10n.adhanCreditLine(voice.credit),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          SelectableText(
            l10n.adhanLicenseLine(
              '${voice.license.name} · ${voice.license.url}',
            ),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          // Web addresses read left to right in any language.
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              l10n.adhanSourceLine(voice.sourceUrl),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
