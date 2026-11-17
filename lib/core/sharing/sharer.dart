import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands text and pictures to the system's share sheet. Tests replace it.
abstract interface class Sharer {
  /// Offers [text] to the apps that take text.
  Future<void> shareText(String text);

  /// Offers the PNG [png], named [name], to the apps that take pictures,
  /// with [text] beside it where the app takes both.
  Future<void> shareImage(Uint8List png, {required String name, String? text});
}

/// The platform's share sheet.
class PlatformSharer implements Sharer {
  /// Creates the sharer.
  const PlatformSharer();

  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    // A file in the cache: the receiving app reads it from there, and the
    // system clears it in time.
    final folder = await getTemporaryDirectory();
    final file = File('${folder.path}/$name');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
      ),
    );
  }
}

/// Provides the sharer. Tests override it.
final sharerProvider = Provider<Sharer>((ref) => const PlatformSharer());
