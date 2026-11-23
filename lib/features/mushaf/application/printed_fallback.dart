import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../data/svg_page_store.dart';
import 'svg_page_providers.dart';

/// What the reader did about the printed Mushaf and the internet.
enum PrintedFallbackChange {
  /// A printed page could not be had without the internet: the Mushaf now
  /// shows as typeset text.
  toText,

  /// The person asked for the typeset text in place of a reading whose page
  /// could not be had without the internet.
  toTextChosen,

  /// A page downloaded: the internet is back, and so is the printed Mushaf.
  toPrinted,

  /// Every page of the reading is on the device, with or without the
  /// internet: the printed Mushaf is back.
  toPrintedSaved,
}

/// The last change, numbered so that two alike in a row are both heard.
typedef PrintedFallbackEvent = ({PrintedFallbackChange change, int serial});

/// Switches the reader to typeset text when a printed page cannot be had
/// offline, and back to the printed Mushaf once pages download again. Its
/// state is the last switch it made, for the reader to announce.
final printedFallbackProvider =
    NotifierProvider<PrintedFallback, PrintedFallbackEvent?>(
      PrintedFallback.new,
    );

/// Keeps the reader's mode in step with whether the printed pages can be
/// had.
///
/// Offline, a page that is not on the device cannot be shown printed. The
/// reader then shows the Mushaf as typeset text, and the settings say so
/// ([AppSettings.textUntilOnline]), rather than a page of text under a
/// printed-Mushaf setting. While it is so, the reader keeps trying to
/// download a page that is not on the device: when it turns a page, when
/// the app comes back to the front, and every [retryEvery]. The first that
/// arrives brings the printed Mushaf back. The person choosing a mode ends
/// it (see [SettingsNotifier.chooseReaderMode]).
class PrintedFallback extends Notifier<PrintedFallbackEvent?> {
  /// How often the printed pages are tried while the reader shows text in
  /// their place.
  @visibleForTesting
  static Duration retryEvery = const Duration(seconds: 30);

  Timer? _timer;
  bool _trying = false;
  int _serial = 0;
  int? _page;

  @override
  PrintedFallbackEvent? build() {
    ref.listen(
      settingsProvider.select((settings) => _waitingIn(settings.value)),
      (_, waiting) => _watch(waiting),
      fireImmediately: true,
    );
    final lifecycle = AppLifecycleListener(onResume: () => unawaited(retry()));
    ref.onDispose(() {
      _timer?.cancel();
      lifecycle.dispose();
    });
    return null;
  }

  static bool _waitingIn(AppSettings? settings) =>
      settings != null &&
      settings.textUntilOnline &&
      settings.readerMode == ReaderMode.text;

  bool get _waiting => _waitingIn(ref.read(settingsProvider).value);

  void _watch(bool waiting) {
    _timer?.cancel();
    _timer = waiting
        ? Timer.periodic(retryEvery, (_) {
            // Only while the app is in front: nobody reads it otherwise.
            final state = WidgetsBinding.instance.lifecycleState;
            if (state == null || state == AppLifecycleState.resumed) {
              unawaited(retry());
            }
          })
        : null;
  }

  /// A printed page could not be had because the internet is not there:
  /// the Mushaf shows as typeset text until it is. Only a reading whose
  /// text is the app's own (Hafs) has text to stand in; another stays
  /// printed and says why on the page.
  Future<void> offline() async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null || settings.readerMode != ReaderMode.printed) return;
    if (!ref.read(printedEditionProvider).matchesAppText) return;
    await ref
        .read(settingsProvider.notifier)
        .save(
          settings.copyWith(readerMode: ReaderMode.text, textUntilOnline: true),
        );
    _emit(PrintedFallbackChange.toText);
  }

  /// The person asked for the typeset text in place of a printed page that
  /// could not be had: one of a reading whose text is not the app's own,
  /// whose page the reader cannot stand text in for. Offline ([offline]),
  /// the printed reading comes back with the internet, as for Hafs; else
  /// (the server failed) the text stays until the person chooses again.
  Future<void> readTextInstead({required bool offline}) async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null || settings.readerMode != ReaderMode.printed) return;
    if (!offline) {
      await ref
          .read(settingsProvider.notifier)
          .chooseReaderMode(ReaderMode.text);
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .save(
          settings.copyWith(readerMode: ReaderMode.text, textUntilOnline: true),
        );
    _emit(PrintedFallbackChange.toTextChosen);
  }

  /// Tries whether the printed pages can be had again, from [page] (the
  /// page the reader is on; the last one given when null): downloads the
  /// nearest page that is not on the device. When it arrives, the internet
  /// is back; when every page is on the device (downloaded, or unpacked
  /// meanwhile), none is needed. Either way the printed Mushaf comes back,
  /// and says which. Does nothing unless the reader shows text because it
  /// was offline.
  Future<void> retry([int? page]) async {
    if (page != null) _page = page;
    final from = _page;
    if (_trying || from == null || !_waiting) return;
    _trying = true;
    PrintedFallbackChange? back;
    try {
      final store = ref.read(
        svgPageStoreProvider(ref.read(printedEditionProvider)),
      );
      final missing = await store.nearestMissing(from);
      if (missing != null) await store.fetch(missing);
      // A page that came out of a waiting download proves nothing about
      // the internet; a Mushaf now whole on the device needs none.
      back = await store.complete()
          ? PrintedFallbackChange.toPrintedSaved
          : PrintedFallbackChange.toPrinted;
    } on Object catch (error) {
      // The server answering with an error means the internet is there; the
      // page that failed says so itself when it is opened.
      if (error is PageDownloadException && !error.unreachable) {
        back = PrintedFallbackChange.toPrinted;
      } else {
        AppLogger.debug('Printed pages still offline: ${error.runtimeType}');
      }
    } finally {
      _trying = false;
    }
    if (back != null && _waiting) await _toPrinted(back);
  }

  Future<void> _toPrinted(PrintedFallbackChange change) async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    await ref
        .read(settingsProvider.notifier)
        .save(
          settings.copyWith(
            readerMode: ReaderMode.printed,
            textUntilOnline: false,
          ),
        );
    _emit(change);
  }

  void _emit(PrintedFallbackChange change) =>
      state = (change: change, serial: ++_serial);
}
