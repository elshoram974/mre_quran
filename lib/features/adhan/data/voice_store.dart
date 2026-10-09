import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/adhan_voice.dart';

/// Why a download did not finish.
enum VoiceDownloadFailure {
  /// The connection failed or the server refused.
  network,

  /// The file is not the one the catalogue describes (wrong SHA-256).
  integrity,

  /// The server asked us to slow down (HTTP 429 or 503). Try again later.
  busy,

  /// The person cancelled.
  cancelled,
}

/// A download that did not finish.
class VoiceDownloadException implements Exception {
  /// Creates the exception.
  const VoiceDownloadException(this.failure);

  /// Why.
  final VoiceDownloadFailure failure;

  @override
  String toString() => 'VoiceDownloadException($failure)';
}

/// Lets a download be stopped.
class VoiceDownloadToken {
  bool _cancelled = false;

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled;

  /// Stops the download at the next chunk.
  void cancel() => _cancelled = true;
}

/// Opens the bytes of a file on the network. Tests replace it.
abstract interface class VoiceFetcher {
  /// Streams the body of [url].
  Stream<List<int>> open(Uri url);
}

/// Fetches with `dart:io`, naming the app as Wikimedia asks of clients.
class HttpVoiceFetcher implements VoiceFetcher {
  /// Creates the fetcher.
  const HttpVoiceFetcher();

  /// Sent with every request and with previews, so the host can tell who
  /// asks. Keep it in step with the native preview.
  static const String userAgent =
      'MREQuran/1.0 (adhan voices; Flutter app; only after a tap)';

  @override
  Stream<List<int>> open(Uri url) async* {
    final client = HttpClient()
      ..userAgent = userAgent
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        final busy =
            response.statusCode == HttpStatus.tooManyRequests ||
            response.statusCode == HttpStatus.serviceUnavailable;
        throw VoiceDownloadException(
          busy ? VoiceDownloadFailure.busy : VoiceDownloadFailure.network,
        );
      }
      yield* response;
    } on SocketException {
      throw const VoiceDownloadException(VoiceDownloadFailure.network);
    } on HttpException {
      throw const VoiceDownloadException(VoiceDownloadFailure.network);
    } finally {
      client.close(force: true);
    }
  }
}

/// The recordings kept on the phone.
abstract interface class VoiceStore {
  /// The ids among [voices] that are on the phone (and the bundled one).
  Future<Set<String>> downloaded(Iterable<AdhanVoice> voices);

  /// The saved file of [voice], or null when it is not downloaded.
  Future<File?> fileOf(AdhanVoice voice);

  /// Downloads [voice], checks its SHA-256, and keeps it. [onProgress] gets
  /// 0 to 1. Throws a [VoiceDownloadException] when it cannot.
  Future<void> download(
    AdhanVoice voice, {
    void Function(double progress)? onProgress,
    VoiceDownloadToken? token,
  });

  /// Removes the saved file of [voice].
  Future<void> delete(AdhanVoice voice);
}

/// Keeps voices as files under the app's support folder, away from the
/// backup. A file is written beside its place and moved in only once it has
/// passed the check, so a broken download never counts as downloaded.
class FileVoiceStore implements VoiceStore {
  /// Creates the store. Tests pass [directory] and a fake [fetcher].
  FileVoiceStore({
    this.fetcher = const HttpVoiceFetcher(),
    Future<Directory> Function()? directory,
  }) : _directory = directory ?? _supportFolder;

  /// Where files come from.
  final VoiceFetcher fetcher;
  final Future<Directory> Function() _directory;

  static Future<Directory> _supportFolder() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/adhan');
  }

  Future<File> _file(AdhanVoice voice) async =>
      File('${(await _directory()).path}/${voice.id}.${voice.extension}');

  @override
  Future<File?> fileOf(AdhanVoice voice) async {
    if (voice.builtIn) return null;
    final file = await _file(voice);
    return await file.exists() ? file : null;
  }

  @override
  Future<Set<String>> downloaded(Iterable<AdhanVoice> voices) async => {
    for (final voice in voices)
      if (voice.builtIn || await fileOf(voice) != null) voice.id,
  };

  @override
  Future<void> download(
    AdhanVoice voice, {
    void Function(double progress)? onProgress,
    VoiceDownloadToken? token,
  }) async {
    final url = voice.url;
    if (url == null) return;
    final target = await _file(voice);
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    final sink = partial.openWrite();
    final digest = _DigestSink();
    final hash = sha256.startChunkedConversion(digest);
    var received = 0;
    try {
      await for (final chunk in fetcher.open(Uri.parse(url))) {
        if (token?.isCancelled ?? false) {
          throw const VoiceDownloadException(VoiceDownloadFailure.cancelled);
        }
        sink.add(chunk);
        hash.add(chunk);
        received += chunk.length;
        onProgress?.call((received / voice.bytes).clamp(0, 1));
      }
      hash.close();
      await sink.close();
      if (digest.value.toString() != voice.sha256) {
        throw const VoiceDownloadException(VoiceDownloadFailure.integrity);
      }
      await partial.rename(target.path);
    } on Object {
      await sink.close().catchError((Object _) {});
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  @override
  Future<void> delete(AdhanVoice voice) async {
    final file = await fileOf(voice);
    if (file != null) await file.delete();
  }
}

/// Receives the one digest a chunked hash produces.
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
