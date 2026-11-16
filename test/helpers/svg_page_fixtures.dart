import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/domain/svg_manifest.dart';
import 'package:mre_quran/features/mushaf/domain/svg_page.dart';

/// A small page shaped like the real ones: ink, one ayah-number ornament,
/// and an invisible polygon.
const String fixtureSvg = '''
<?xml version='1.0' encoding='UTF-8'?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 345 550"><g transform="matrix(1.3333 0 0 -1.3333 -115 640)"><g id="ayah_markers" class="ayah_markers"><g class="ayah-mark"><g class="ayah-mark-ornament"><path d="M100 100L110 100L110 110Z" fill="#231f20" /></g></g></g><g><path d="M120 120L200 120L200 140L120 140Z" fill="#231f20" /></g></g><path class="ayahPolygon" fill-opacity="0" d="M 0 0 L 345 0 L 345 40 L 0 40 Z" /></svg>''';

/// The real polygon file of page 3.
final String fixtureJson = File('test/fixtures/svg/003.json')
    .readAsStringSync();

/// Bytes of [text].
Uint8List bytesOf(String text) => Uint8List.fromList(utf8.encode(text));

final Map<(String, int), Uint8List> _archives = {};

/// A zip of [pages] pages' files with [extension], laid out like the
/// release archives: SVG files under `svg/`, JSON files at the top.
///
/// Built once per shape and kept: a zip records when it was made, so two
/// builds differ in their bytes and would not share a checksum.
Uint8List fixtureArchive(String extension, {int pages = 3}) =>
    Uint8List.fromList(
      _archives.putIfAbsent((extension, pages), () {
        final content = utf8.encode(
          extension == 'svg' ? fixtureSvg : fixtureJson,
        );
        final archive = Archive();
        for (var page = 1; page <= pages; page++) {
          final name = SvgManifest.fileName(page, extension);
          archive.add(
            ArchiveFile.bytes(extension == 'svg' ? 'svg/$name' : name, content),
          );
        }
        // A file the app must ignore, as the real archives hold per-surah
        // files.
        archive.add(ArchiveFile.bytes('001-surah1.$extension', content));
        return ZipEncoder().encodeBytes(archive);
      }),
    );

/// A manifest of [pages] pages that all hold the fixture files, with the
/// two archives [fixtureArchive] builds.
SvgManifest fixtureManifest({int pages = 3}) => SvgManifest(
  edition: 'hafs-kfqc',
  base: Uri.parse('https://example.test/pages'),
  packedBytes: 3 * 1024 * 1024,
  archives: [
    for (final extension in ['svg', 'json'])
      (
        name: 'hafs-kfqc-$extension.zip',
        url: Uri.parse('https://example.test/hafs-kfqc-$extension.zip'),
        sha256: sha256
            .convert(fixtureArchive(extension, pages: pages))
            .toString(),
        bytes: extension == 'svg' ? 5 * 1024 * 1024 : 1024,
      ),
  ],
  pages: [
    for (var i = 0; i < pages; i++)
      (
        svgSha256: sha256.convert(utf8.encode(fixtureSvg)).toString(),
        jsonSha256: sha256.convert(utf8.encode(fixtureJson)).toString(),
        bytes: fixtureSvg.length + fixtureJson.length,
      ),
  ],
);

/// Page [page] built from the fixture files.
SvgPage fixturePage(int page) =>
    SvgPageParser.page(page, svg: fixtureSvg, json: fixtureJson);

/// Answers page requests with the fixture files and counts them.
class FakePageServer {
  /// Addresses requested, in order.
  final List<Uri> requests = [];

  /// When set, every request fails as if offline.
  bool offline = false;

  /// When set, SVG files come back altered.
  bool tamper = false;

  /// The fetch function to hand to the store.
  Future<Uint8List> fetch(Uri uri) async {
    requests.add(uri);
    if (offline) throw const SocketException('offline');
    final svg = uri.path.endsWith('.svg');
    return bytesOf(svg ? (tamper ? '$fixtureSvg ' : fixtureSvg) : fixtureJson);
  }
}
