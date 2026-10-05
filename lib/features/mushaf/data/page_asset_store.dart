import 'dart:io';
import 'dart:typed_data';

import 'mushaf_image_source.dart';

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

/// Keeps printed-Mushaf page images and layouts on the device.
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

  /// The image file of [page], light or [dark].
  Future<File> image(int page, {required bool dark}) => _file(
    'images/${dark ? 'dark' : 'light'}/p$page.png',
    MushafImageSource.pageImage(page, dark: dark),
    _isPng,
  );

  /// The layout JSON of [page].
  Future<String> layout(int page) async => (await _file(
    'layouts/page-$page.json',
    MushafImageSource.pageLayout(page),
    _isJsonObject,
  )).readAsString();

  static bool _isPng(Uint8List bytes) =>
      bytes.length > 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;

  static bool _isJsonObject(Uint8List bytes) {
    for (final byte in bytes) {
      // Skip leading whitespace.
      if (byte == 0x20 || byte == 0x0A || byte == 0x0D || byte == 0x09) {
        continue;
      }
      return byte == 0x7B; // {
    }
    return false;
  }

  /// Joins concurrent requests for the same file; a failed one can be retried.
  Future<File> _file(
    String relative,
    Uri uri,
    bool Function(Uint8List) valid,
  ) => _inFlight[relative] ??= _load(relative, uri, valid).whenComplete(() {
    _inFlight.remove(relative);
  });

  Future<File> _load(
    String relative,
    Uri uri,
    bool Function(Uint8List) valid,
  ) async {
    final root = await _root();
    final file = File('${root.path}/mushaf/$relative');
    if (await file.exists() && await file.length() > 0) return file;
    final bytes = await _fetch(uri);
    // A CDN can answer 200 with an error page; never cache that.
    if (!valid(bytes)) throw PageDownloadException(uri, 'unexpected content');
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
