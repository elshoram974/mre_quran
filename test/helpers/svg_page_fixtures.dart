import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_compiler.dart';
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

/// Path data of a 4×4 square whose corner is [dx], [dy] from where the
/// last square began. A page's script moves from contour to contour like
/// this, each start measured from the one before.
String square(num dx, num dy) => 'm$dx ${dy}h4v4h-4z';

/// A row of nine squares across the page, the first one [dx], [dy] from
/// where the pen was. Stands for one printed line.
String lineOfSquares(num dx, num dy) =>
    [square(dx, dy), for (var i = 1; i < 9; i++) square(40, 0)].join();

/// A page shaped like the real ones, with two printed lines that can be
/// told apart. The page group flips the page, so a path at height `y`
/// shows at `550 - y`.
///
/// The script is drawn the way the real pages draw it: first a pause sign
/// (three small contours above the upper line), then the lower line, then
/// the upper one. The upper line's contours are centred at page height 98,
/// the lower line's at 135. One ornament sits on the upper line.
///
/// [script] replaces the script's path data.
String spreadSvg({String? script}) {
  final d =
      script ??
      [
        // The sign, drawn first.
        'm150 447h4v4h-4z', square(2, 0), square(2, 0),
        // The lower line, from the left edge; the pen comes back for it.
        lineOfSquares(-144, -34),
        // The upper line.
        lineOfSquares(-320, 37),
      ].join();
  return '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" '
      'viewBox="0 0 345 550"><g transform="matrix(1 0 0 -1 0 550)">'
      '<g id="ayah_markers" class="ayah_markers"><g class="ayah-mark">'
      '<g class="ayah-mark-ornament" '
      'transform="translate(300 448) scale(0.009 -0.009)">'
      '<path d="M0 0L9 9Z" fill="#231f20" /></g></g></g>'
      '<g id="content"><g transform="translate(0 0)">'
      '<path d="$d" fill="#231f20" fill-rule="evenodd" /></g></g></g>'
      '<path class="ayahPolygon" fill-opacity="0" d="M 0 0 L 9 9 Z" /></svg>';
}

/// The ayah regions of [spreadSvg]: ayah 2:6 on the upper line and 2:7 on
/// the lower, each a full-width band, with the rest of the page given to
/// 2:8 so the page counts as a full one.
const String spreadJson =
    '[{"surahNumber": 2, "ayahNumber": 6, '
    '"polygon": "M 0 80 L 345 80 L 345 117 L 0 117 Z"}, '
    '{"surahNumber": 2, "ayahNumber": 7, '
    '"polygon": "M 0 117 L 345 117 L 345 154 L 0 154 Z"}, '
    '{"surahNumber": 2, "ayahNumber": 8, '
    '"polygon": "M 0 154 L 345 154 L 345 550 L 0 550 Z"}]';

/// Page [page] built from [spreadSvg]: one whose lines can be spread.
SvgPage spreadPage(int page) =>
    SvgPageParser.page(page, svg: spreadSvg(), json: spreadJson);

/// The fixture page compiled for drawing, as the store hands it out.
SvgPagePicture fixturePicture(SvgPageRequest request) =>
    SvgPageCompiler.compile(
      fixturePage(request.page),
      stretch: request.stretch / 1000,
    );

/// The spreadable page compiled for the spread [request] asks for.
SvgPagePicture spreadPicture(SvgPageRequest request) => SvgPageCompiler.compile(
  spreadPage(request.page),
  stretch: request.stretch / 1000,
);
