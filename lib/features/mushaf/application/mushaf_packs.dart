import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pack_downloader.dart';
import '../data/svg_page_store.dart';
import 'svg_page_providers.dart';

/// How much of the printed Mushaf is on the device for reading without a
/// connection.
@immutable
class PackProgress {
  /// Creates the progress: [done] of [total] files, [active] while a
  /// download is running.
  const PackProgress({
    required this.done,
    required this.total,
    required this.active,
    this.bytes = 0,
  });

  /// Bytes the files take on the device.
  final int bytes;

  /// Files on the device.
  final int done;

  /// Files the whole Mushaf needs.
  final int total;

  /// Whether a download is running.
  final bool active;

  /// Done, 0–1.
  double get fraction => total == 0 ? 0 : done / total;

  /// Whether every file is there.
  bool get complete => done >= total;

  /// Whether some files are there but a download is not running.
  bool get partial => !active && done > 0 && !complete;

  PackProgress copyWith({int? done, bool? active, int? bytes}) => PackProgress(
    done: done ?? this.done,
    total: total,
    active: active ?? this.active,
    bytes: bytes ?? this.bytes,
  );

  @override
  bool operator ==(Object other) =>
      other is PackProgress &&
      other.done == done &&
      other.total == total &&
      other.active == active &&
      other.bytes == bytes;

  @override
  int get hashCode => Object.hash(done, total, active, bytes);
}

/// Provides the downloader of Mushaf packs. Tests override it.
final packDownloaderProvider = Provider<PackDownloader>(
  (ref) => BackgroundPackDownloader(),
);

/// The state of the printed Mushaf's offline pack.
final mushafPackProvider = AsyncNotifierProvider<MushafPack, PackProgress>(
  MushafPack.new,
);

/// Downloads the whole printed Mushaf so it works offline, keeps count of
/// what is on the device, and deletes it.
///
/// The files go where the page reader looks for them, so a downloaded page
/// opens at once. The system, not the app, keeps downloading when the app is
/// closed; the counts are read back from disk the next time the app opens.
class MushafPack extends AsyncNotifier<PackProgress> {
  SvgPageStore get _store => ref.read(svgPageStoreProvider);
  PackDownloader get _downloader => ref.read(packDownloaderProvider);

  /// Name of the download group.
  static const String group = 'mushaf-svg';

  /// How long finished files are gathered before the counts are read again.
  /// Hundreds of files end within seconds; reading the disk for each one
  /// would make the screen stutter.
  @visibleForTesting
  static Duration settleDelay = const Duration(milliseconds: 1200);

  Timer? _timer;
  bool _dirty = false;

  @override
  Future<PackProgress> build() async {
    final sub = _downloader.results.listen(_onResult);
    ref.onDispose(() {
      sub.cancel();
      _timer?.cancel();
    });
    return _read();
  }

  Future<PackProgress> _read() async {
    // Files the system downloader wrote are checked against their checksums
    // and compressed here; one that fails is deleted and counted as missing.
    await _store.ingest();
    final total = await _store.packFileCount();
    final missing = (await _store.missing()).length;
    return PackProgress(
      done: total - missing,
      total: total,
      active: await _downloader.pending(group) > 0,
      bytes: await _store.bytesOnDevice(),
    );
  }

  void _set(PackProgress progress) {
    if (state.value == null) return;
    state = AsyncData(progress);
  }

  /// A file ended: note it, and read the counts once things have settled.
  void _onResult(PackFileResult result) {
    if (result.group != group) return;
    _dirty = true;
    if (_timer?.isActive ?? false) return;
    _timer = Timer(settleDelay, _settle);
  }

  Future<void> _settle() async {
    _dirty = false;
    _set(await _read());
    // More may have ended while the disk was being read.
    if (_dirty) _timer = Timer(settleDelay, _settle);
  }

  /// Reads everything again and collects what finished while the app was
  /// away. Called when the app comes back to the front.
  Future<void> refresh() async {
    if (state.value == null) return;
    await _downloader.resume();
    _set(await _read());
  }

  /// Downloads what is still missing, with a notification described by
  /// [text]. Safe to call again for a partial download: it carries on.
  Future<void> start(PackNotificationText text) async {
    final current = state.value;
    if (current == null || current.active) return;
    _set(current.copyWith(active: true));
    try {
      await _downloader.requestNotifications();
      final missing = await _store.missing();
      if (missing.isEmpty) {
        _set(await _read());
        return;
      }
      await _downloader.enqueue(group, missing, text);
    } on Object {
      _set(await _read());
      rethrow;
    }
  }

  /// Stops the download, keeping the files already fetched.
  Future<void> cancel() async {
    await _downloader.cancel(group);
    _set(await _read());
  }

  /// Stops the download and deletes the pages.
  Future<void> delete() async {
    await _downloader.cancel(group);
    await _store.deleteAll();
    _set(await _read());
  }
}
