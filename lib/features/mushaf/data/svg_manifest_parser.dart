import 'dart:convert';

import '../domain/svg_manifest.dart';

/// Reads the bundled page manifest.
abstract final class SvgManifestParser {
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

  /// Parses [source]. Throws [FormatException] when it is not a manifest.
  static SvgManifest parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded
        case {
          'edition': final String edition,
          'base': final String base,
          'packedBytes': final int packedBytes,
          'pages': final List<dynamic> pages,
        }
        when pages.isNotEmpty && packedBytes > 0) {
      return SvgManifest(
        edition: edition,
        base: Uri.parse(base),
        packedBytes: packedBytes,
        pages: [for (final page in pages) _entry(page)],
      );
    }
    throw const FormatException('Not a page manifest');
  }

  static SvgPageEntry _entry(Object? page) {
    if (page case [final String svg, final String json, final int bytes]
        when _sha256.hasMatch(svg) && _sha256.hasMatch(json) && bytes > 0) {
      return (svgSha256: svg, jsonSha256: json, bytes: bytes);
    }
    throw const FormatException('Broken page entry in the manifest');
  }
}
