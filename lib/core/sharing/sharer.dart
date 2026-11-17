import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands text and pictures to the system's share sheet. Tests replace it.
abstract interface class Sharer {
  /// Offers [text] to the apps that take text.
  Future<void> shareText(String text);

  /// Offers the PNG [images], each with its file name, to the apps that take
  /// pictures, with [text] beside them where the app takes both.
  Future<void> shareImages(List<SharedImage> images, {String? text});
}

/// A PNG picture to share and the file name it is sent under.
typedef SharedImage = ({Uint8List png, String name});

/// The platform's share sheet.
class PlatformSharer implements Sharer {
  /// Creates the sharer.
  const PlatformSharer();

  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  @override
  Future<void> shareImages(List<SharedImage> images, {String? text}) async {
    // Files in the cache: the receiving app reads them from there, and the
    // system clears them in time.
    final folder = await getTemporaryDirectory();
    final files = <XFile>[];
    for (final image in images) {
      final file = File('${folder.path}/${image.name}');
      await file.writeAsBytes(image.png, flush: true);
      files.add(XFile(file.path, mimeType: 'image/png'));
    }
    await SharePlus.instance.share(ShareParams(files: files, text: text));
  }
}

/// Provides the sharer. Tests override it.
final sharerProvider = Provider<Sharer>((ref) => const PlatformSharer());
