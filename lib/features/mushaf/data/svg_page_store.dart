import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../domain/svg_manifest.dart';
import '../domain/svg_page.dart';
import 'pack_downloader.dart';
import 'svg_page_parser.dart';

/// Downloads a URL. Injected so tests run offline.
typedef Fetch = Future<Uint8List> Function(Uri uri);

/// Raised when a page file could not be downloaded or failed its checksum.
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

/// Keeps the printed Mushaf's page files on the device.
///
/// A page's two files (SVG artwork, ayah-polygon JSON) are downloaded the
/// first time the page is needed, checked against the SHA-256 in the
/// manifest, and kept gzip-compressed, so pages work offline once seen and
/// the whole Mushaf takes about a quarter of its download size. A file that
/// fails its checksum is never kept or shown.
///
/// The offline pack is fetched by the system downloader, which can only write
/// files as they come; [ingest] checks and compresses those afterwards.
class SvgPageStore {
  /// Creates a store under [root] for the pages of [manifest], downloading
  /// with [fetch].
  SvgPageStore({required this._root, required this._manifest, Fetch? fetch})
    : _fetch = fetch ?? _httpFetch;

  final Future<Directory> Function() _root;
  final Future<SvgManifest> Function() _manifest;
  final Fetch _fetch;
  final Map<int, Future<void>> _inFlight = {};

  static const List<String> _extensions = ['svg', 'json'];
  static const String _packed = '.gz';

  /// The folder everything Mushaf is kept in. Pack paths are relative to it.
  Future<Directory> directory() async =>
      Directory('${(await _root()).path}/mushaf');

  Future<String> _folder() async {
    final manifest = await _manifest();
    return '${(await directory()).path}/svg/${manifest.edition}';
  }

  /// Page [page], ready to draw: downloaded if the device does not have it,
  /// then decoded off the main isolate.
  Future<SvgPage> page(int page) async {
    await fetch(page);
    final manifest = await _manifest();
    final entry = manifest.entry(page);
    final folder = await _folder();
    final decoded = await Isolate.run(() => _decode(folder, page, entry));
    if (decoded == null) {
      // The files on the device no longer match: drop them, so the next try
      // downloads them again.
      await _delete(folder, page);
      throw PageDownloadException(manifest.url(page, 'svg'), 'damaged file');
    }
    return decoded;
  }

  /// Makes sure the two files of [page] are on the device, without decoding
  /// them. Concurrent calls for one page share one download.
  Future<void> fetch(int page) =>
      _inFlight[page] ??= _ensure(page).whenComplete(() {
        _inFlight.remove(page);
      });

  Future<void> _ensure(int page) async {
    final manifest = await _manifest();
    final entry = manifest.entry(page);
    final folder = await _folder();
    for (final extension in _extensions) {
      final name = SvgManifest.fileName(page, extension);
      final packed = File('$folder/$name$_packed');
      if (await packed.exists()) continue;
      final expected = extension == 'svg' ? entry.svgSha256 : entry.jsonSha256;
      final raw = File('$folder/$name');
      // A file the pack downloader left: take it if it is sound.
      if (await raw.exists() && await _pack(raw, packed, expected)) continue;
      final uri = manifest.url(page, extension);
      final bytes = await _fetch(uri);
      if (sha256.convert(bytes).toString() != expected) {
        throw PageDownloadException(uri, 'checksum mismatch');
      }
      await _writePacked(packed, bytes);
    }
  }

  /// The pack files the device does not have yet, as the system downloader
  /// should fetch them.
  Future<List<PackFile>> missing() async {
    final manifest = await _manifest();
    final folder = await _folder();
    final have = await _names(folder);
    final relative = 'svg/${manifest.edition}';
    return [
      for (var page = 1; page <= manifest.pageCount; page++)
        for (final extension in _extensions)
          if (!have.contains(
            '${SvgManifest.fileName(page, extension)}$_packed',
          ))
            (
              url: manifest.url(page, extension),
              path: '$relative/${SvgManifest.fileName(page, extension)}',
            ),
    ];
  }

  /// Number of files a complete pack holds.
  Future<int> packFileCount() async =>
      (await _manifest()).pageCount * _extensions.length;

  /// Checks and compresses every file the pack downloader has written, and
  /// deletes any that fail their checksum, so they are fetched again.
  Future<void> ingest() async {
    final manifest = await _manifest();
    final folder = await _folder();
    final raw = [
      for (final name in await _names(folder))
        if (!name.endsWith(_packed) && !name.endsWith('.part')) name,
    ];
    if (raw.isEmpty) return;
    await Isolate.run(() async {
      for (final name in raw) {
        final page = int.tryParse(name.split('.').first);
        final file = File('$folder/$name');
        if (page == null || page < 1 || page > manifest.pageCount) {
          await file.delete();
          continue;
        }
        final entry = manifest.entry(page);
        await _pack(
          file,
          File('$folder/$name$_packed'),
          name.endsWith('.svg') ? entry.svgSha256 : entry.jsonSha256,
        );
      }
    });
  }

  /// How many bytes the pages take on the device.
  Future<int> bytesOnDevice() async {
    final folder = Directory(await _folder());
    if (!await folder.exists()) return 0;
    var total = 0;
    await for (final entity in folder.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Deletes every page on the device.
  Future<void> deleteAll() async {
    final folder = Directory(await _folder());
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  static Future<Set<String>> _names(String folder) async {
    final directory = Directory(folder);
    if (!await directory.exists()) return const {};
    return {
      await for (final entity in directory.list())
        if (entity is File) entity.uri.pathSegments.last,
    };
  }

  static Future<void> _delete(String folder, int page) async {
    for (final extension in _extensions) {
      final file = File(
        '$folder/${SvgManifest.fileName(page, extension)}$_packed',
      );
      if (await file.exists()) await file.delete();
    }
  }

  /// Compresses [raw] into [packed] when it matches [expected], and removes
  /// [raw] either way. Returns whether it was sound.
  static Future<bool> _pack(File raw, File packed, String expected) async {
    final bytes = await raw.readAsBytes();
    final sound = sha256.convert(bytes).toString() == expected;
    if (sound) await _writePacked(packed, bytes);
    await raw.delete();
    return sound;
  }

  /// Written to a side file first, so a half-written file is never read.
  static Future<void> _writePacked(File packed, List<int> bytes) async {
    await packed.parent.create(recursive: true);
    final temp = File('${packed.path}.part');
    await temp.writeAsBytes(gzip.encode(bytes), flush: true);
    await temp.rename(packed.path);
  }

  /// Reads, re-checks, and parses a page; null when a file is damaged.
  static Future<SvgPage?> _decode(
    String folder,
    int page,
    SvgPageEntry entry,
  ) async {
    Future<String?> read(String extension, String expected) async {
      final file = File(
        '$folder/${SvgManifest.fileName(page, extension)}$_packed',
      );
      try {
        final bytes = gzip.decode(await file.readAsBytes());
        if (sha256.convert(bytes).toString() != expected) return null;
        return utf8.decode(bytes);
      } on Exception {
        return null;
      }
    }

    final svg = await read('svg', entry.svgSha256);
    final json = await read('json', entry.jsonSha256);
    if (svg == null || json == null) return null;
    try {
      return SvgPageParser.page(page, svg: svg, json: json);
    } on FormatException {
      return null;
    }
  }

  static Future<Uint8List> _httpFetch(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
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
