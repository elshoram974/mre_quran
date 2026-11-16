import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../data/pack_downloader.dart';
import '../data/svg_page_store.dart';
import 'svg_page_providers.dart';

/// How much of the printed Mushaf is on the device for reading without a
/// connection, and what the download is doing now.
@immutable
class PackProgress {
  /// Creates the progress: [done] of [total] page files on the device.
  const PackProgress({
    required this.done,
    required this.total,
    required this.active,
    this.bytes = 0,
    this.transfer = 0,
    this.installing = false,
  });

  /// Bytes the files take on the device.
  final int bytes;

  /// Page files on the device.
  final int done;

  /// Page files the whole Mushaf needs.
  final int total;

  /// Whether the download is running.
  final bool active;

  /// How far the running download has come, 0–1.
  final double transfer;

  /// Whether downloaded archives are being checked and unpacked.
  final bool installing;

  /// Share of the pages on the device, 0–1.
  double get fraction => total == 0 ? 0 : done / total;

  /// Whether every page is there.
  bool get complete => done >= total;

  /// Whether nothing is running and only some pages are there.
  bool get partial => !active && !installing && done > 0 && !complete;

  /// A copy with the given fields replaced.
  PackProgress copyWith({
    int? done,
    bool? active,
    int? bytes,
    double? transfer,
    bool? installing,
  }) => PackProgress(
    done: done ?? this.done,
    total: total,
    active: active ?? this.active,
    bytes: bytes ?? this.bytes,
    transfer: transfer ?? this.transfer,
    installing: installing ?? this.installing,
  );

  @override
  bool operator ==(Object other) =>
      other is PackProgress &&
      other.done == done &&
      other.total == total &&
      other.active == active &&
      other.bytes == bytes &&
      other.transfer == transfer &&
      other.installing == installing;

  @override
  int get hashCode =>
      Object.hash(done, total, active, bytes, transfer, installing);
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
/// The Mushaf comes as two archives. The system, not the app, downloads
/// them, so the download carries on when the app is closed, and its
/// notification can pause or cancel it. When an archive has arrived it is
/// checked and unpacked into the pages the reader uses; if the app was
/// closed meanwhile, that happens the next time it opens.
class MushafPack extends AsyncNotifier<PackProgress> {
  SvgPageStore get _store => ref.read(svgPageStoreProvider);
  PackDownloader get _downloader => ref.read(packDownloaderProvider);

  /// Name of the download group.
  static const String group = 'mushaf-svg';

  /// How long finished files are gathered before the disk is read again.
  @visibleForTesting
  static Duration settleDelay = const Duration(milliseconds: 1200);

  Timer? _timer;
  bool _dirty = false;

  /// How far each archive of the running download has come, by its path.
  final Map<String, double> _transfers = {};

  @override
  Future<PackProgress> build() async {
    final results = _downloader.results.listen(_onResult);
    final transfers = _downloader.transfers.listen(_onTransfer);
    ref.onDispose(() {
      results.cancel();
      transfers.cancel();
      _timer?.cancel();
    });
    final progress = await _read();
    // Archives that arrived while the app was closed are unpacked now.
    if (await _store.hasArchives()) unawaited(_install());
    return progress;
  }

  Future<PackProgress> _read() async {
    final active = await _isDownloading();
    if (!active) _transfers.clear();
    return PackProgress(
      done: await _store.filesOnDevice(),
      total: await _store.packFileCount(),
      active: active,
      bytes: await _store.bytesOnDevice(),
      transfer: _transfer,
    );
  }

  /// Whether the system still holds a download of the pack. A downloader
  /// that cannot say counts as idle: the reader must still be able to see
  /// what is on the device and start a download.
  Future<bool> _isDownloading() async {
    try {
      return await _downloader.pending(group) > 0;
    } on Object catch (error) {
      AppLogger.debug('Pack downloader state failed: ${error.runtimeType}');
      return false;
    }
  }

  /// The download as a whole is as far as its slowest archive.
  double get _transfer => _transfers.isEmpty
      ? 0
      : _transfers.values.reduce((a, b) => a < b ? a : b);

  void _set(PackProgress progress) {
    if (state.value == null) return;
    state = AsyncData(progress);
  }

  void _onTransfer(PackTransfer transfer) {
    if (transfer.group != group) return;
    _transfers[transfer.path] = transfer.fraction;
    final current = state.value;
    if (current != null && current.active) {
      _set(current.copyWith(transfer: _transfer));
    }
  }

  /// A file ended: note it, and read the disk once things have settled.
  void _onResult(PackFileResult result) {
    if (result.group != group) return;
    if (result.ok) _transfers[result.path] = 1;
    _dirty = true;
    if (_timer?.isActive ?? false) return;
    _timer = Timer(settleDelay, _settle);
  }

  Future<void> _settle() async {
    _dirty = false;
    await _install();
    // More may have ended while the disk was being read.
    if (_dirty) _timer = Timer(settleDelay, _settle);
  }

  /// Unpacks any archive that has arrived, then counts again.
  Future<void> _install() async {
    if (await _store.hasArchives()) {
      final current = state.value;
      if (current != null) _set(current.copyWith(installing: true));
      await _store.install();
    }
    _set(await _read());
  }

  /// Reads everything again and collects what finished while the app was
  /// away. Called when the app comes back to the front.
  Future<void> refresh() async {
    if (state.value == null) return;
    await _downloader.resume();
    await _install();
  }

  /// Downloads what is still missing, with notifications described by
  /// [text]. Safe to call again for a partial download: it carries on.
  Future<void> start(PackNotificationText text) async {
    final current = state.value;
    if (current == null || current.active || current.installing) return;
    _set(current.copyWith(active: true, transfer: 0));
    try {
      await _downloader.requestNotifications();
      final missing = await _store.missing();
      if (missing.isEmpty) {
        await _install();
        return;
      }
      _transfers
        ..clear()
        ..addAll({for (final file in missing) file.path: 0});
      await _downloader.enqueue(group, missing, text);
    } on Object {
      _set(await _read());
      rethrow;
    }
  }

  /// Stops the download, keeping the pages already on the device.
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
