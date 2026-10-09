import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_tag.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhan_providers.dart';
import '../domain/adhan_settings.dart';
import '../domain/adhan_voice.dart';

/// The most the app keeps for a recording from the person's phone, in bytes.
/// The platform enforces the same figure.
const int customVoiceMaxBytes = 25 * 1000 * 1000;

/// A recording the person picks from their own phone, such as the voice of a
/// muezzin they love. It sits beside the catalogue's voices.
class CustomVoiceCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const CustomVoiceCard({
    super.key,
    required this.settings,
    required this.listening,
  });

  /// The saved choices, which hold the picked file.
  final AdhanSettings settings;

  /// Whether the picked file is being previewed.
  final bool listening;

  @override
  ConsumerState<CustomVoiceCard> createState() => _CustomVoiceCardState();
}

class _CustomVoiceCardState extends ConsumerState<CustomVoiceCard> {
  bool _tooLarge = false;

  Future<void> _pick() async {
    final pick = await ref.read(adhanVoicesProvider.notifier).pickCustom();
    if (mounted && pick != null) setState(() => _tooLarge = pick.tooLarge);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(displayDigitsFormatterProvider);
    final notifier = ref.read(adhanVoicesProvider.notifier);
    final settings = widget.settings;
    final chosen = settings.voiceId == AdhanVoice.customId;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            settings.customName ?? l10n.adhanCustomTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                settings.hasCustom
                    ? l10n.adhanCustomTitle
                    : l10n.adhanCustomHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (chosen) AppTag(l10n.adhanInUse),
            ],
          ),
          if (_tooLarge) ...[
            const SizedBox(height: 8),
            AppNotice(
              l10n.adhanCustomTooLarge(
                digits('${customVoiceMaxBytes ~/ 1000000}'),
              ),
              error: true,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (settings.hasCustom)
                OutlinedButton.icon(
                  onPressed: notifier.toggleListeningCustom,
                  icon: Icon(widget.listening ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    widget.listening
                        ? l10n.adhanStopListening
                        : l10n.adhanListen,
                  ),
                ),
              FilledButton.tonalIcon(
                onPressed: _pick,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(
                  settings.hasCustom
                      ? l10n.adhanCustomReplace
                      : l10n.adhanCustomChoose,
                ),
              ),
              if (settings.hasCustom && !chosen)
                FilledButton(
                  onPressed: () => ref
                      .read(adhanSettingsProvider.notifier)
                      .change(
                        (value) => value.copyWith(voiceId: AdhanVoice.customId),
                      ),
                  child: Text(l10n.adhanUse),
                ),
              if (settings.hasCustom)
                TextButton(
                  onPressed: notifier.deleteCustom,
                  child: Text(l10n.adhanDelete),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
