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
  });

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

  PackProgress copyWith({int? done, bool? active}) => PackProgress(
    done: done ?? this.done,
    total: total,
    active: active ?? this.active,
  );

  @override
  bool operator ==(Object other) =>
      other is PackProgress &&
      other.done == done &&
      other.total == total &&
      other.active == active;

  @override
  int get hashCode => Object.hash(done, total, active);
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

  @override
  Future<Map<MushafStyle, PackProgress>> build() async {
    final sub = _downloader.results.listen(_onResult);
    ref.onDispose(sub.cancel);
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
    );
  }

  void _set(MushafStyle style, PackProgress progress) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData({...current, style: progress});
  }

  Future<void> _onResult(PackFileResult result) async {
    final edition = _edition(result.group);
    final current = state.value?[edition?.style];
    if (edition == null || current == null) return;
    var done = current.done;
    if (result.ok) {
      final file = File('${(await _store.directory()).path}/${result.path}');
      // A CDN can answer 200 with an error page; drop it so it is fetched
      // again, and do not count it.
      if (await _store.isImageFile(file)) {
        done++;
      } else if (await file.exists()) {
        await file.delete();
      }
    }
    final stillRunning = await _downloader.pending(_group(edition)) > 0;
    _set(
      edition.style,
      current.copyWith(
        done: done.clamp(0, current.total),
        active: stillRunning,
      ),
    );
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
