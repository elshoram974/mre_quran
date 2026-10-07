import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/domain/app_settings.dart';
import '../data/pack_downloader.dart';
import '../data/page_asset_store.dart';
import '../domain/mushaf_edition.dart';
import 'page_image_providers.dart';

/// How much of an edition is on the device for reading without a connection.
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

  /// Files the edition needs.
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

/// The state of every edition's offline pack.
final mushafPacksProvider =
    AsyncNotifierProvider<MushafPacks, Map<MushafStyle, PackProgress>>(
      MushafPacks.new,
    );

/// Downloads whole Mushaf editions so they work offline, keeps count of what
/// is on the device, and deletes them.
///
/// The files go where the page reader looks for them, so a downloaded page
/// opens at once. The system, not the app, keeps downloading when the app is
/// closed; the counts are read back from disk the next time the app opens.
class MushafPacks extends AsyncNotifier<Map<MushafStyle, PackProgress>> {
  PageAssetStore get _store => ref.read(pageAssetStoreProvider);
  PackDownloader get _downloader => ref.read(packDownloaderProvider);

  static String _group(MushafEdition edition) => 'mushaf-${edition.style.name}';

  MushafEdition? _edition(String group) {
    for (final edition in MushafEdition.all) {
      if (_group(edition) == group) return edition;
    }
    return null;
  }

  /// How long finished files are gathered before the counts are read again.
  /// Hundreds of files end within seconds; reading the disk for each one
  /// would make the screen stutter.
  @visibleForTesting
  static Duration settleDelay = const Duration(milliseconds: 1200);

  final Set<MushafEdition> _dirty = {};
  Timer? _timer;

  @override
  Future<Map<MushafStyle, PackProgress>> build() async {
    final sub = _downloader.results.listen(_onResult);
    ref.onDispose(() {
      sub.cancel();
      _timer?.cancel();
    });
    return {
      for (final edition in MushafEdition.all)
        edition.style: await _read(edition),
    };
  }

  Future<PackProgress> _read(MushafEdition edition) async {
    final total = edition.packFiles.length;
    final missing = (await _store.missingImages(edition)).length;
    return PackProgress(
      done: total - missing,
      total: total,
      active: await _downloader.pending(_group(edition)) > 0,
      bytes: await _store.bytesOnDevice(edition),
    );
  }

  void _set(MushafStyle style, PackProgress progress) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData({...current, style: progress});
  }

  /// A file ended: note it, and read the counts once things have settled.
  void _onResult(PackFileResult result) {
    final edition = _edition(result.group);
    if (edition == null) return;
    _dirty.add(edition);
    if (_timer?.isActive ?? false) return;
    _timer = Timer(settleDelay, _settle);
  }

  Future<void> _settle() async {
    final editions = _dirty.toList();
    _dirty.clear();
    for (final edition in editions) {
      var progress = await _read(edition);
      if (!progress.active) {
        // The download is over: clear out what came back broken, so the next
        // attempt fetches it again, and count again.
        await _dropBrokenFiles(edition);
        progress = await _read(edition);
      }
      _set(edition.style, progress);
    }
    // More may have ended while the disk was being read.
    if (_dirty.isNotEmpty) _timer = Timer(settleDelay, _settle);
  }

  /// A CDN can answer 200 with an error page; drop such files so they are
  /// fetched again, and never count them.
  Future<void> _dropBrokenFiles(MushafEdition edition) async {
    final base = (await _store.directory()).path;
    for (final file in edition.packFiles) {
      final f = File('$base/${file.path}');
      if (await f.exists() && !await _store.isImageFile(f)) await f.delete();
    }
  }

  /// Reads everything again and collects what finished while the app was
  /// away. Called when the app comes back to the front.
  Future<void> refresh() async {
    if (state.value == null) return;
    await _downloader.resume();
    for (final edition in MushafEdition.all) {
      _set(edition.style, await _read(edition));
    }
  }

  /// Downloads what [edition] still lacks, with a notification described by
  /// [text]. Safe to call again for a partial download: it carries on.
  Future<void> start(MushafEdition edition, PackNotificationText text) async {
    final current = state.value?[edition.style];
    if (current == null || current.active) return;
    _set(edition.style, current.copyWith(active: true));
    try {
      await _downloader.requestNotifications();
      if (edition.geometry == PageGeometrySource.glyphDatabase) {
        await _store.ayahInfoDatabase();
      }
      final missing = await _store.missingImages(edition);
      if (missing.isEmpty) {
        _set(edition.style, await _read(edition));
        return;
      }
      await _downloader.enqueue(_group(edition), missing, text);
    } on Object {
      _set(edition.style, await _read(edition));
      rethrow;
    }
  }

  /// Stops the download of [edition], keeping the files already fetched.
  Future<void> cancel(MushafEdition edition) async {
    await _downloader.cancel(_group(edition));
    _set(edition.style, await _read(edition));
  }

  /// Stops the download of [edition] and deletes its images.
  Future<void> delete(MushafEdition edition) async {
    await _downloader.cancel(_group(edition));
    await _store.deleteImages(edition);
    _set(edition.style, await _read(edition));
  }
}
