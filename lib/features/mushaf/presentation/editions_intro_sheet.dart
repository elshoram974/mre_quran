import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/mushaf_edition.dart';
import 'offline_packs_section.dart';

/// Tells the reader, once, that there are other Mushaf editions: each can be
/// chosen, and downloaded to read without internet. Shown over the reader the
/// first time it opens, then never again on its own.
class EditionsIntroTrigger extends ConsumerStatefulWidget {
  /// Creates the trigger.
  const EditionsIntroTrigger({super.key});

  @override
  ConsumerState<EditionsIntroTrigger> createState() =>
      _EditionsIntroTriggerState();
}

class _EditionsIntroTriggerState extends ConsumerState<EditionsIntroTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  bool _shown = false;

  Future<void> _maybeShow() async {
    if (!mounted || _shown) return;
    final settings = ref.read(settingsProvider).value;
    if (settings == null || settings.editionsIntroSeen) return;
    _shown = true;
    final notifier = ref.read(settingsProvider.notifier);
    // Marked first: closing the app mid-sheet must not show it again.
    await notifier.save(settings.copyWith(editionsIntroSeen: true));
    if (!mounted) return;
    await AppSheet.show<void>(
      context: context,
      builder: (_) => const _EditionsIntro(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Settings can still be loading when the reader first appears.
    ref.listen(settingsProvider, (_, _) => _maybeShow());
    return const SizedBox.shrink();
  }
}

class _EditionsIntro extends ConsumerWidget {
  const _EditionsIntro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editionsIntroTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.editionsIntroBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          for (final edition in MushafEdition.all) ...[
            const SizedBox(height: 12),
            PackTile(
              edition: edition,
              selected:
                  settings.mushafStyle == edition.style &&
                  settings.readerMode == ReaderMode.printed,
              onSelect: () => notifier.save(
                settings.copyWith(
                  mushafStyle: edition.style,
                  readerMode: ReaderMode.printed,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.editionsIntroDone),
          ),
        ],
      ),
    );
  }
}
