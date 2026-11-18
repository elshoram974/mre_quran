import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon_badge.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/mushaf_packs.dart';
import '../application/svg_page_providers.dart';
import '../data/pack_downloader.dart';

/// The settings section for reading the printed Mushaf without internet:
/// what is on the device, and a button to download, stop, or delete it. The
/// download runs in the background and shows a notification.
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
      onResume: () {
        for (final edition in MushafEditions.all) {
          ref.read(mushafPackProvider(edition).notifier).refresh();
        }
      },
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
        AppSectionHeader(title: l10n.offlineMushaf),
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
        const SizedBox(height: 8),
        Text(
          l10n.offlinePickHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final edition in MushafEditions.all) ...[
          const SizedBox(height: 12),
          PackTile(edition: edition),
        ],
      ],
    );
  }
}

/// One reading's printed Mushaf: what is on the device, its download, stop
/// and delete buttons, and whether the reader shows it. A tap chooses it
/// for reading.
class PackTile extends ConsumerWidget {
  /// Creates the tile of [edition].
  const PackTile({super.key, required this.edition});

  /// The reading this tile is for.
  final MushafEdition edition;

  PackNotificationText _text(AppLocalizations l10n) =>
      packNotificationText(edition, l10n);

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final digits = ref.read(digitsFormatterProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final text = _text(l10n);
    final failed = l10n.packStartError;
    final megabytes = _mb(
      (await ref.read(svgManifestProvider(edition).future)).downloadBytes,
    );
    if (!context.mounted) return;
    final confirmed = await _confirm(
      context,
      title: l10n.packDownloadTitle(edition.name(l10n.localeName)),
      body: l10n.packDownloadBody(digits(megabytes)),
      action: l10n.packDownload,
    );
    if (confirmed != true) return;
    try {
      await ref.read(mushafPackProvider(edition).notifier).start(text);
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final digits = ref.read(digitsFormatterProvider);
    final notifier = ref.read(mushafPackProvider(edition).notifier);
    final progress = ref.read(mushafPackProvider(edition)).value;
    if (progress == null) return;
    final megabytes = _mb(progress.bytes);
    final confirmed = await AppSheet.show<bool>(
      context: context,
      builder: (sheet) => _DeleteWarning(
        title: l10n.packDeleteWarnTitle(edition.name(l10n.localeName)),
        body: l10n.packDeleteWarnBody(digits(progress.done), digits(megabytes)),
      ),
    );
    if (confirmed == true) await notifier.delete();
  }

  /// Makes this the reading the reader shows.
  void _use(WidgetRef ref) {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    ref
        .read(settingsProvider.notifier)
        .save(settings.copyWith(mushafEdition: edition));
  }

  static int _mb(int bytes) => (bytes / (1024 * 1024)).ceil();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digits = ref.watch(digitsFormatterProvider);
    final pack = ref.watch(mushafPackProvider(edition));
    final progress = pack.value;
    // The state could not be read: say so and offer another try, rather
    // than a card with nothing to press.
    final failed = progress == null && pack.hasError;
    final packed =
        ref.watch(svgManifestProvider(edition)).value?.packedBytes ?? 0;
    // While downloading, the bar follows the transfer; otherwise it shows
    // how many of the pages are on the device.
    final shown = (progress?.active ?? false)
        ? progress!.transfer
        : progress?.fraction ?? 0;
    final percent = digits((shown * 100).floor());
    final subtitle = switch (progress) {
      null => failed ? l10n.packStateError : l10n.packChecking,
      PackProgress(installing: true) => l10n.packInstallingProgress(
        digits((progress.fraction * 100).floor()),
      ),
      PackProgress(active: true) => l10n.packDownloading(percent),
      PackProgress(complete: true) =>
        '${l10n.packReady} · ${l10n.packOnDevice(digits(_mb(progress.bytes)))}',
      PackProgress(partial: true) =>
        '${l10n.packPartial(percent)} · ${l10n.packOnDevice(digits(_mb(progress.bytes)))}',
      _ => l10n.packNotDownloaded(digits(_mb(packed))),
    };
    final Widget? action = switch (progress) {
      null when failed => TextButton(
        onPressed: () => ref.invalidate(mushafPackProvider(edition)),
        child: Text(l10n.retry),
      ),
      null || PackProgress(installing: true) => null,
      PackProgress(active: true) => TextButton(
        onPressed: () =>
            ref.read(mushafPackProvider(edition).notifier).cancel(),
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
    final installing = progress?.installing ?? false;
    final showBar =
        progress != null && (progress.active || progress.partial || installing);
    final ready = progress?.complete ?? false;
    final inUse = ref.watch(printedEditionProvider) == edition;
    return AppCard(
      onTap: inUse ? null : () => _use(ref),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIconBadge(
                ready
                    ? Icons.download_done_outlined
                    : Icons.cloud_download_outlined,
                size: AppIconBadgeSize.small,
                emphasized: ready || inUse,
              ),
              const SizedBox(width: AppTokens.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edition.name(l10n.localeName),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (inUse)
                      Text(
                        l10n.editionInUse,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
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
              // Unpacking shows how many pages are ready; before the first
              // one lands, while the archive itself is checked, it runs free.
              child: LinearProgressIndicator(
                value: installing && shown <= 0 ? null : shown,
              ),
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

/// Words of the notification of [edition]'s download.
PackNotificationText packNotificationText(
  MushafEdition edition,
  AppLocalizations l10n,
) {
  final name = edition.name(l10n.localeName);
  return PackNotificationText(
    runningTitle: l10n.packNotifyRunningTitle(name),
    // The downloader fills in the percentage.
    runningBody: '{progress}',
    completeTitle: l10n.packNotifyCompleteTitle(name),
    completeBody: l10n.packNotifyCompleteBody,
    errorTitle: l10n.packNotifyErrorTitle(name),
    errorBody: l10n.packNotifyErrorBody,
    pausedTitle: l10n.packNotifyPausedTitle(name),
    pausedBody: l10n.packNotifyPausedBody,
  );
}
