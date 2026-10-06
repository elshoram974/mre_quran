import 'dart:io';
import 'dart:math' as math;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../domain/mushaf_edition.dart';
import 'mushaf_sources.dart';

/// Downloads a URL. Injected so tests run offline.
typedef Fetch = Future<Uint8List> Function(Uri uri);

/// Raised when a page file could not be downloaded.
class PageDownloadException implements Exception {
  /// Creates the exception for [uri].
  const PageDownloadException(this.uri, this.reason);

  /// What was requested.
  final Uri uri;

  /// Why it failed.
  final String reason;

  @override
  String toString() => 'PageDownloadException($uri): $reason';
}

/// Keeps printed-Mushaf page images and the glyph database on the device.
///
/// A file is downloaded the first time it is needed, written atomically, and
/// read from disk after that, so pages work offline once seen.
class PageAssetStore {
  /// Creates a store under [root], downloading with [fetch].
  PageAssetStore({required this._root, Fetch? fetch})
    : _fetch = fetch ?? _httpFetch;

  final Future<Directory> Function() _root;
  final Fetch _fetch;
  final Map<String, Future<File>> _inFlight = {};

  /// The image file of [page] in [edition], light or [dark], downloaded if
  /// the device does not have it yet.
  Future<File> image(MushafEdition edition, int page, {required bool dark}) =>
      _file(
        edition.imagePath(page, dark: dark),
        edition.image(page, dark: dark),
      );

  /// The folder everything is kept in.
  Future<Directory> directory() async =>
      Directory('${(await _root()).path}/mushaf');

  /// The pack images of [edition] the device does not have yet, or has only
  /// as a broken file.
  Future<List<({Uri url, String path})>> missingImages(
    MushafEdition edition,
  ) async {
    final base = (await directory()).path;
    final files = edition.packFiles;
    final missing = <({Uri url, String path})>[];
    // Checked in batches: one file at a time is slow, all at once opens too
    // many files together.
    const batch = 64;
    for (var i = 0; i < files.length; i += batch) {
      final part = files.sublist(i, math.min(i + batch, files.length));
      final found = await Future.wait([
        for (final file in part) isImageFile(File('$base/${file.path}')),
      ]);
      for (var j = 0; j < part.length; j++) {
        if (!found[j]) missing.add(part[j]);
      }
    }
    return missing;
  }

  /// Whether [file] exists and starts like a PNG or a WebP.
  Future<bool> isImageFile(File file) async {
    if (!await file.exists()) return false;
    final handle = await file.open();
    try {
      return _isImage(await handle.read(12));
    } finally {
      await handle.close();
    }
  }

  /// Deletes every image of [edition].
  Future<void> deleteImages(MushafEdition edition) async {
    final folder = Directory(
      '${(await directory()).path}/images/${edition.style.name}',
    );
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  /// The glyph database of the Quran.com pages, checked against its
  /// recorded SHA-256 values.
  Future<File> ayahInfoDatabase() =>
      _inFlight['ayahinfo'] ??= _loadAyahInfo().whenComplete(() {
        _inFlight.remove('ayahinfo');
      });

  Future<File> _loadAyahInfo() async {
    final root = await _root();
    final file = File('${root.path}/mushaf/${MushafSources.ayahInfoEntry}');
    if (await file.exists()) return file;
    final zip = await _fetch(MushafSources.ayahInfo);
    final database = await Isolate.run(() => _extractAyahInfo(zip));
    if (database == null) {
      throw PageDownloadException(MushafSources.ayahInfo, 'checksum mismatch');
    }
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.part');
    await temp.writeAsBytes(database, flush: true);
    return temp.rename(file.path);
  }

  /// The database inside [zip], or null when either checksum is wrong.
  static Uint8List? _extractAyahInfo(Uint8List zip) {
    if (sha256.convert(zip).toString() != MushafSources.ayahInfoSha256) {
      return null;
    }
    final entry = ZipDecoder()
        .decodeBytes(zip)
        .findFile(MushafSources.ayahInfoEntry);
    final bytes = entry?.readBytes();
    if (bytes == null ||
        sha256.convert(bytes).toString() != MushafSources.ayahInfoDbSha256) {
      return null;
    }
    return bytes;
  }

  /// A PNG (`\x89PNG`) or a WebP (`RIFF....WEBP`) header.
  static bool _isImage(Uint8List bytes) =>
      bytes.length >= 12 &&
      ((bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47) ||
          (bytes[0] == 0x52 &&
              bytes[1] == 0x49 &&
              bytes[2] == 0x46 &&
              bytes[3] == 0x46 &&
              bytes[8] == 0x57 &&
              bytes[9] == 0x45 &&
              bytes[10] == 0x42 &&
              bytes[11] == 0x50));

  /// Joins concurrent requests for the same file; a failed one can be retried.
  Future<File> _file(String relative, Uri uri) =>
      _inFlight[relative] ??= _load(relative, uri).whenComplete(() {
        _inFlight.remove(relative);
      });

  Future<File> _load(String relative, Uri uri) async {
    final file = File('${(await directory()).path}/$relative');
    if (await isImageFile(file)) return file;
    final bytes = await _fetch(uri);
    // A CDN can answer 200 with an error page; never cache that.
    if (!_isImage(bytes)) {
      throw PageDownloadException(uri, 'unexpected content');
    }
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.part');
    await temp.writeAsBytes(bytes, flush: true);
    return temp.rename(file.path);
  }

  static Future<Uint8List> _httpFetch(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw PageDownloadException(uri, 'HTTP ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } on SocketException catch (error) {
      throw PageDownloadException(uri, error.message);
    } finally {
      client.close();
    }
  }
}
