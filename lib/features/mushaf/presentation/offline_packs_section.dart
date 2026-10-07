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
class OfflinePacksSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const OfflinePacksSection({super.key});

  @override
  ConsumerState<OfflinePacksSection> createState() =>
      _OfflinePacksSectionState();
}

class _OfflinePacksSectionState extends ConsumerState<OfflinePacksSection> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // Downloads go on while the app is away; collect what finished.
      onResume: () => ref.read(mushafPacksProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 8),
        Text(
          l10n.packStorageInfo,
          style: theme.textTheme.bodySmall?.copyWith(
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
    final digits = ref.read(digitsFormatterProvider);
    final notifier = ref.read(mushafPacksProvider.notifier);
    final progress = ref.read(mushafPacksProvider).value?[edition.style];
    if (progress == null) return;
    final megabytes = (progress.bytes / (1024 * 1024)).ceil();
    final confirmed = await AppSheet.show<bool>(
      context: context,
      builder: (sheet) => _DeleteWarning(
        title: l10n.packDeleteWarnTitle(mushafStyleLabel(l10n, edition.style)),
        body: l10n.packDeleteWarnBody(digits(progress.done), digits(megabytes)),
      ),
    );
    if (confirmed == true) await notifier.delete(edition);
  }

  static int _mb(int bytes) => (bytes / (1024 * 1024)).ceil();

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
      PackProgress(complete: true) =>
        '${l10n.packReady} · ${l10n.packOnDevice(digits(_mb(progress.bytes)))}',
      PackProgress(partial: true) =>
        '${l10n.packPartial(percent)} · ${l10n.packOnDevice(digits(_mb(progress.bytes)))}',
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
      PackProgress(partial: true) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.packDelete,
            color: scheme.error,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _delete(context, ref),
          ),
          FilledButton.tonal(
            onPressed: () => _download(context, ref),
            child: Text(l10n.packResume),
          ),
        ],
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

/// The last warning before downloaded files are deleted: what goes, what it
/// costs, and a box to tick before the button works.
class _DeleteWarning extends StatefulWidget {
  const _DeleteWarning({required this.title, required this.body});

  final String title;
  final String body;

  @override
  State<_DeleteWarning> createState() => _DeleteWarningState();
}

class _DeleteWarningState extends State<_DeleteWarning> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.warning_amber_rounded, size: 36, color: scheme.error),
          const SizedBox(height: 8),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _understood,
            onChanged: (value) => setState(() => _understood = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.packDeleteAck),
          ),
          const SizedBox(height: 8),
          FilledButton(
            // Nothing is deleted until the box is ticked.
            onPressed: _understood
                ? () => Navigator.of(context).pop(true)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(l10n.packDeletePermanently),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.packCancel),
          ),
        ],
      ),
    );
  }
}
