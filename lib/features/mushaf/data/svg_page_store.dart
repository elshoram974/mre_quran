import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

import '../domain/svg_manifest.dart';
import '../domain/svg_page.dart';
import 'pack_downloader.dart';
import 'svg_page_compiler.dart';
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
/// The offline pack is two archives fetched by the system downloader, which
/// keeps going when the app is closed. [install] checks each archive against
/// its SHA-256, then takes every page file out of it, checks it, and
/// compresses it like any other page.
class SvgPageStore {
  /// Creates a store under [root] for the pages of [manifest], downloading
  /// with [fetch]. `ordered` says the edition draws its script line by
  /// line (the edition's `linesInDrawingOrder`).
  SvgPageStore({
    required this._root,
    required this._manifest,
    Fetch? fetch,
    this._ordered = true,
  }) : _fetch = fetch ?? _httpFetch;

  final Future<Directory> Function() _root;
  final bool _ordered;
  final Future<SvgManifest> Function() _manifest;
  final Fetch _fetch;
  final Map<int, Future<void>> _inFlight = {};

  /// Pages being prepared, and those waiting for a place.
  int _busy = 0;
  final List<Completer<void>> _waiting = [];

  /// How many pages are prepared at the same time.
  static const int _preparing = 2;

  static const List<String> _extensions = ['svg', 'json'];
  static const String _packed = '.gz';
  static const String _archives = 'pack';

  /// The folder everything Mushaf is kept in. Pack paths are relative to it.
  Future<Directory> directory() async =>
      Directory('${(await _root()).path}/mushaf');

  Future<String> _folder() async {
    final manifest = await _manifest();
    return '${(await directory()).path}/svg/${manifest.edition}';
  }

  /// Page [page], ready to paint with its lines spread for a page [stretch]
  /// times as tall: downloaded if the device does not have it, then read,
  /// checked and compiled off the main isolate.
  Future<SvgPagePicture> page(int page, {double stretch = 1}) async {
    await fetch(page);
    final manifest = await _manifest();
    final entry = manifest.entry(page);
    final folder = await _folder();
    // A local, so the isolate is sent the flag and not the store.
    final ordered = _ordered;
    final decoded = await _inTurn(
      () => Isolate.run(
        () => _decode(folder, page, entry, stretch, ordered: ordered),
      ),
    );
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
      final uri = manifest.url(page, extension);
      final bytes = await _fetch(uri);
      if (sha256.convert(bytes).toString() != expected) {
        throw PageDownloadException(uri, 'checksum mismatch');
      }
      await _writePacked(packed, bytes);
    }
  }

  /// Folder, under [directory], the pack's archives are downloaded into.
  Future<String> _archiveFolder() async => '${await _folder()}/$_archives';

  /// How many page files a complete pack holds.
  Future<int> packFileCount() async =>
      (await _manifest()).pageCount * _extensions.length;

  /// How many page files are on the device.
  Future<int> filesOnDevice() async {
    final names = await _names(await _folder());
    return names.where((name) => name.endsWith(_packed)).length;
  }

  /// The archives still to download for the offline pack, as the system
  /// downloader should fetch them. Empty when every page is on the device,
  /// or when the archives are downloaded and only wait to be installed.
  Future<List<PackFile>> missing() async {
    if (await filesOnDevice() >= await packFileCount()) return const [];
    final manifest = await _manifest();
    final have = await _names(await _archiveFolder());
    return [
      for (final archive in manifest.archives)
        if (!have.contains(archive.name))
          (
            url: archive.url,
            path: 'svg/${manifest.edition}/$_archives/${archive.name}',
          ),
    ];
  }

  /// Whether a downloaded archive waits to be installed.
  Future<bool> hasArchives() async =>
      (await _names(await _archiveFolder())).isNotEmpty;

  /// Installs every downloaded archive: checks it against its SHA-256, takes
  /// out each page file, checks that too, and keeps it compressed. The
  /// archive is deleted afterwards, sound or not; one that fails its
  /// checksum installs nothing and is fetched again.
  ///
  /// Safe to interrupt: pages already installed are skipped the next time.
  /// Calls made while one is running share it, so two never take the same
  /// archive apart at once.
  Future<void> install() =>
      _installing ??= _install().whenComplete(() => _installing = null);

  Future<void>? _installing;

  Future<void> _install() async {
    final manifest = await _manifest();
    final folder = await _folder();
    final archives = await _archiveFolder();
    final names = await _names(archives);
    if (names.isEmpty) return;
    await Isolate.run(() async {
      for (final name in names) {
        final file = File('$archives/$name');
        try {
          SvgArchive? known;
          for (final archive in manifest.archives) {
            if (archive.name == name) known = archive;
          }
          if (known != null &&
              (await sha256.bind(file.openRead()).first).toString() ==
                  known.sha256) {
            await _unpack(file, folder, manifest);
          }
        } on FileSystemException {
          // The archive went while it was read: the system downloader moved
          // or removed it, or another unpacking took it first. What was
          // unpacked stays; the rest is downloaded again.
        }
        if (await file.exists()) await file.delete();
      }
    });
  }

  static final RegExp _pageFile = RegExp(r'(?:^|/)(\d{3})\.(svg|json)$');

  /// Takes the page files out of [archive], one at a time so memory stays
  /// small, keeping those that match the manifest.
  static Future<void> _unpack(
    File archive,
    String folder,
    SvgManifest manifest,
  ) async {
    final input = InputFileStream(archive.path);
    final entries = ZipDecoder().decodeStream(input);
    try {
      for (final entry in entries.files) {
        final match = _pageFile.firstMatch(entry.name);
        if (!entry.isFile || match == null) continue;
        final page = int.parse(match.group(1)!);
        final extension = match.group(2)!;
        if (page < 1 || page > manifest.pageCount) continue;
        final packed = File(
          '$folder/${SvgManifest.fileName(page, extension)}$_packed',
        );
        if (await packed.exists()) continue;
        final bytes = entry.readBytes();
        final expected = extension == 'svg'
            ? manifest.entry(page).svgSha256
            : manifest.entry(page).jsonSha256;
        if (bytes != null && sha256.convert(bytes).toString() == expected) {
          await _writePacked(packed, bytes);
        }
        entry.closeSync();
      }
    } finally {
      await entries.clear();
      await input.close();
    }
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

  /// Written to a side file first, so a half-written file is never read.
  static Future<void> _writePacked(File packed, List<int> bytes) async {
    await packed.parent.create(recursive: true);
    final temp = File('${packed.path}.part');
    await temp.writeAsBytes(gzip.encode(bytes), flush: true);
    await temp.rename(packed.path);
  }

  /// Runs [work] when a place is free: at most [_preparing] pages are
  /// prepared at once, so they do not fight over the processor. The page
  /// asked for last goes first; it is the one the reader has just turned to.
  Future<T> _inTurn<T>(Future<T> Function() work) async {
    if (_busy >= _preparing) {
      final turn = Completer<void>();
      _waiting.add(turn);
      // Whoever finishes hands its place straight over.
      await turn.future;
    } else {
      _busy++;
    }
    try {
      return await work();
    } finally {
      if (_waiting.isEmpty) {
        _busy--;
      } else {
        _waiting.removeLast().complete();
      }
    }
  }

  /// Reads, re-checks, parses and compiles a page; null when a file is
  /// damaged.
  static Future<SvgPagePicture?> _decode(
    String folder,
    int page,
    SvgPageEntry entry,
    double stretch, {
    required bool ordered,
  }) async {
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
      return SvgPageCompiler.compile(
        SvgPageParser.page(page, svg: svg, json: json, ordered: ordered),
        stretch: stretch,
      );
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
