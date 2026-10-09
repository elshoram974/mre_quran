import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhan_providers.dart';
import '../data/voice_store.dart';
import '../domain/adhan_voice.dart';
import 'voice_info_sheet.dart';

/// One voice: its name and place, listen, and download or use.
class VoiceCard extends ConsumerWidget {
  /// Creates the card.
  const VoiceCard({
    super.key,
    required this.voice,
    required this.status,
    required this.chosen,
    required this.listening,
  });

  /// The recording.
  final AdhanVoice voice;

  /// Where its file stands.
  final VoiceStatus status;

  /// Whether it is the voice in use.
  final bool chosen;

  /// Whether it is being previewed.
  final bool listening;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(displayDigitsFormatterProvider);
    final language = Localizations.localeOf(context).languageCode;
    final notifier = ref.read(adhanVoicesProvider.notifier);
    final size = l10n.adhanSizeMb(
      digits((voice.bytes / 1000000).toStringAsFixed(1)),
    );
    final place = voice.place(language);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  voice.title(language),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.adhanInfo,
                icon: const Icon(Icons.info_outline),
                onPressed: () => VoiceInfoSheet.show(context, voice),
              ),
            ],
          ),
          // A Wrap, so the tag drops under the line when large text leaves no
          // room beside it.
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                voice.builtIn
                    ? '$place · ${l10n.adhanBuiltIn}'
                    : '$place · $size',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (chosen) AppTag(l10n.adhanInUse),
            ],
          ),
          const SizedBox(height: 12),
          if (status case VoiceDownloading(:final progress)) ...[
            LinearProgressIndicator(value: progress == 0 ? null : progress),
            const SizedBox(height: 8),
            Text(
              l10n.adhanDownloading(digits('${(progress * 100).round()}%')),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (status case VoiceAvailable(:final failure?)) ...[
            AppNotice(switch (failure) {
              VoiceDownloadFailure.integrity => l10n.adhanDownloadIntegrity,
              VoiceDownloadFailure.busy => l10n.adhanDownloadBusy,
              _ => l10n.adhanDownloadNetwork,
            }, error: true),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => notifier.toggleListening(voice),
                icon: Icon(listening ? Icons.stop : Icons.play_arrow),
                label: Text(
                  listening ? l10n.adhanStopListening : l10n.adhanListen,
                ),
              ),
              ..._actions(context, l10n, notifier, size),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    AppLocalizations l10n,
    AdhanVoicesNotifier notifier,
    String size,
  ) => switch (status) {
    VoiceDownloading() => [
      TextButton(
        onPressed: () => notifier.cancel(voice),
        child: Text(l10n.adhanCancel),
      ),
    ],
    VoiceAvailable() => [
      FilledButton.tonalIcon(
        onPressed: () => notifier.download(voice),
        icon: const Icon(Icons.download),
        label: Text(l10n.adhanDownload(size)),
      ),
    ],
    VoiceReady() => [
      if (!chosen)
        FilledButton(
          onPressed: () => notifier.choose(voice),
          child: Text(l10n.adhanUse),
        ),
      if (!voice.builtIn)
        TextButton(
          onPressed: () => notifier.delete(voice),
          child: Text(l10n.adhanDelete),
        ),
    ],
  };
}
