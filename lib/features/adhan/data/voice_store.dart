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

  /// Whether [url] answers with a file, asked briefly.
  Future<bool> reachable(Uri url);
}

/// Fetches with `dart:io`, naming the app so the host can tell who asks.
class HttpVoiceFetcher implements VoiceFetcher {
  /// Creates the fetcher.
  const HttpVoiceFetcher();

  /// Sent with every request and with previews, so the host can tell who
  /// asks. Keep it in step with the native preview.
  static const String userAgent =
      'MREQuran/1.0 (adhan voices; Flutter app; only after a tap)';

  @override
  Future<bool> reachable(Uri url) async {
    final client = HttpClient()
      ..userAgent = userAgent
      ..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client.headUrl(url);
      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      await response.drain<void>();
      return response.statusCode == HttpStatus.ok;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }

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

  Future<File> _file(AdhanVoice voice, AdhanFile from) async =>
      File('${(await _directory()).path}/${voice.id}.${from.extension}');

  /// The saved copy of [voice], from whichever of its files it came.
  @override
  Future<File?> fileOf(AdhanVoice voice) async {
    if (voice.builtIn) return null;
    for (final from in voice.files) {
      final file = await _file(voice, from);
      // A previously downloaded edition may still include a spoken outro.
      // Downloads are hash-checked before installation; a stat is enough to
      // distinguish the larger retired files without decoding them on launch.
      final stat = await file.stat();
      if (stat.type == FileSystemEntityType.file && stat.size == from.bytes)
        return file;
    }
    return null;
  }

  @override
  Future<Set<String>> downloaded(Iterable<AdhanVoice> voices) async => {
    for (final voice in voices)
      if (voice.builtIn || await fileOf(voice) != null) voice.id,
  };

  /// Downloads [voice] from its first file, and from the next when that
  /// cannot be had or is not the file it should be (the cleaned copy not
  /// published yet, say). Throws the last failure when none works.
  @override
  Future<void> download(
    AdhanVoice voice, {
    void Function(double progress)? onProgress,
    VoiceDownloadToken? token,
  }) async {
    final files = voice.files;
    if (files.isEmpty) return;
    for (final (index, from) in files.indexed) {
      try {
        await _download(voice, from, onProgress: onProgress, token: token);
        return;
      } on VoiceDownloadException catch (error) {
        final last = index == files.length - 1;
        if (last || error.failure == VoiceDownloadFailure.cancelled) rethrow;
      }
    }
  }

  Future<void> _download(
    AdhanVoice voice,
    AdhanFile from, {
    void Function(double progress)? onProgress,
    VoiceDownloadToken? token,
  }) async {
    final target = await _file(voice, from);
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    final sink = partial.openWrite();
    final digest = _DigestSink();
    final hash = sha256.startChunkedConversion(digest);
    var received = 0;
    try {
      await for (final chunk in fetcher.open(Uri.parse(from.url))) {
        if (token?.isCancelled ?? false) {
          throw const VoiceDownloadException(VoiceDownloadFailure.cancelled);
        }
        sink.add(chunk);
        hash.add(chunk);
        received += chunk.length;
        onProgress?.call((received / from.bytes).clamp(0, 1));
      }
      hash.close();
      await sink.close();
      if (digest.value.toString() != from.sha256) {
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
    for (final from in voice.files) {
      final file = await _file(voice, from);
      if (await file.exists()) await file.delete();
    }
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
