import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/digits_provider.dart';
import '../application/mushaf_packs.dart';
import '../data/pack_downloader.dart';
import '../domain/mushaf_edition.dart';
import 'mushaf_style_field.dart';

/// The settings section for reading the Mushaf without internet: every
/// edition with what is on the device, and a button to download, stop, or
/// delete it. Downloads run in the background and show a notification.
class OfflinePacksSection extends ConsumerWidget {
  /// Creates the section.
  const OfflinePacksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.offlineMushaf, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          l10n.offlineMushafIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final edition in MushafEdition.all) ...[
          const SizedBox(height: 12),
          _PackTile(edition: edition),
        ],
      ],
    );
  }
}

class _PackTile extends ConsumerWidget {
  const _PackTile({required this.edition});

  final MushafEdition edition;

  /// Words of the download's notification.
  PackNotificationText _text(AppLocalizations l10n) {
    final name = mushafStyleLabel(l10n, edition.style);
    return PackNotificationText(
      runningTitle: l10n.packNotifyRunningTitle(name),
      // The downloader fills in the percentage.
      runningBody: '{progress}',
      completeTitle: l10n.packNotifyCompleteTitle(name),
      completeBody: l10n.packNotifyCompleteBody,
      errorTitle: l10n.packNotifyErrorTitle(name),
      errorBody: l10n.packNotifyErrorBody,
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final digits = ref.read(digitsFormatterProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final name = mushafStyleLabel(l10n, edition.style);
    final text = _text(l10n);
    final failed = l10n.packStartError;
    final confirmed = await _confirm(
      context,
      title: l10n.packDownloadTitle(name),
      body: l10n.packDownloadBody(digits(_megabytes)),
      action: l10n.packDownload,
    );
    if (confirmed != true) return;
    try {
      await ref.read(mushafPacksProvider.notifier).start(edition, text);
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final notifier = ref.read(mushafPacksProvider.notifier);
    final confirmed = await _confirm(
      context,
      title: l10n.packDeleteTitle(mushafStyleLabel(l10n, edition.style)),
      body: l10n.packDeleteBody,
      action: l10n.packDelete,
      destructive: true,
    );
    if (confirmed == true) await notifier.delete(edition);
  }

  int get _megabytes => (edition.approxBytes / (1024 * 1024)).round();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digits = ref.watch(digitsFormatterProvider);
    final progress = ref.watch(
      mushafPacksProvider.select((packs) => packs.value?[edition.style]),
    );
    final percent = digits(((progress?.fraction ?? 0) * 100).floor());
    final subtitle = switch (progress) {
      null => '',
      PackProgress(active: true) => l10n.packDownloading(percent),
      PackProgress(complete: true) => l10n.packReady,
      PackProgress(partial: true) => l10n.packPartial(percent),
      _ => l10n.packNotDownloaded(digits(_megabytes)),
    };
    final Widget? action = switch (progress) {
      null => null,
      PackProgress(active: true) => TextButton(
        onPressed: () => ref.read(mushafPacksProvider.notifier).cancel(edition),
        child: Text(l10n.packCancel),
      ),
      PackProgress(complete: true) => TextButton(
        onPressed: () => _delete(context, ref),
        style: TextButton.styleFrom(foregroundColor: scheme.error),
        child: Text(l10n.packDelete),
      ),
      PackProgress(partial: true) => FilledButton.tonal(
        onPressed: () => _download(context, ref),
        child: Text(l10n.packResume),
      ),
      _ => FilledButton.tonal(
        onPressed: () => _download(context, ref),
        child: Text(l10n.packDownload),
      ),
    };
    final showBar = progress != null && (progress.active || progress.partial);
    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                progress?.complete ?? false
                    ? Icons.download_done_outlined
                    : Icons.cloud_download_outlined,
                color: progress?.complete ?? false
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mushafStyleLabel(l10n, edition.style),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          if (showBar)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 10, end: 8),
              child: LinearProgressIndicator(value: progress.fraction),
            ),
        ],
      ),
    );
  }
}

/// Asks to [action] before a long or lasting change; true when confirmed.
Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool destructive = false,
}) => AppSheet.show<bool>(
  context: context,
  builder: (sheet) {
    final theme = Theme.of(sheet);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(sheet).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            child: Text(action),
          ),
          TextButton(
            onPressed: () => Navigator.of(sheet).pop(false),
            child: Text(sheet.l10n.packCancel),
          ),
        ],
      ),
    );
  },
);
