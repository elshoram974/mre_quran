import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/hints/hints.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_hint_sheet.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/mushaf_packs.dart';
import '../application/reading_position_provider.dart';
import '../application/svg_page_providers.dart';
import 'offline_packs_section.dart';

/// Says, firmly, that the printed Mushaf needs the internet, the first time
/// in a run of the app that the reader opens a page that is not on the
/// device while the whole Mushaf is not downloaded; and offers to download
/// the reading being read. "Don't remind me again" turns it off. It draws
/// nothing itself.
class OfflineMushafHint extends ConsumerStatefulWidget {
  /// Creates the watcher.
  const OfflineMushafHint({super.key});

  @override
  ConsumerState<OfflineMushafHint> createState() => _OfflineMushafHintState();
}

class _OfflineMushafHintState extends ConsumerState<OfflineMushafHint> {
  bool _checking = false;

  bool get _readerVisible {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return false;
    final router = GoRouter.maybeOf(context);
    return router == null ||
        router.state.matchedLocation == AppRoute.reader.path;
  }

  Future<void> _check(int page) async {
    if (_checking || !_readerVisible) return;
    _checking = true;
    try {
      final hints = await ref.read(hintsProvider.future);
      if (!hints.allows(AppHint.offlineMushaf)) return;
      final printed =
          ref.read(settingsProvider).value?.readerMode != ReaderMode.text;
      if (!printed) return;
      final edition = ref.read(printedEditionProvider);
      final pack = await ref.read(mushafPackProvider(edition).future);
      if (pack.complete || pack.active || pack.installing) return;
      if (await ref.read(svgPageStoreProvider(edition)).isOnDevice(page)) {
        return;
      }
      final manifest = await ref.read(svgManifestProvider(edition).future);
      if (!_readerVisible || !mounted) return;
      final l10n = context.l10n;
      final digits = ref.read(digitsFormatterProvider);
      final megabytes = (manifest.downloadBytes / (1024 * 1024)).ceil();
      final download = await showAppHint(
        context,
        ref,
        hint: AppHint.offlineMushaf,
        icon: Icons.wifi_off_rounded,
        title: l10n.hintOfflineTitle,
        body: l10n.hintOfflineBody(digits(megabytes)),
        action: l10n.hintOfflineAction(edition.name(l10n.localeName)),
        // Hafs has its text in the app, which needs no internet at all.
        secondaryAction: edition.matchesAppText ? l10n.hintOfflineText : null,
        onSecondary: _showAsText,
        dismissLabel: l10n.hintGotIt,
      );
      if (!download || !mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      try {
        await ref
            .read(mushafPackProvider(edition).notifier)
            .start(packNotificationText(edition, l10n));
      } on Object {
        messenger?.showSnackBar(SnackBar(content: Text(l10n.packStartError)));
      }
    } on Object {
      // A hint that cannot be worked out is simply not shown.
    } finally {
      _checking = false;
    }
  }

  /// Switches the reader to typeset text, which is in the app.
  void _showAsText() {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    ref
        .read(settingsProvider.notifier)
        .save(settings.copyWith(readerMode: ReaderMode.text));
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(readingPositionProvider).value;
    if (page != null && TickerMode.valuesOf(context).enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _check(page);
      });
    }
    return const SizedBox.shrink();
  }
}
