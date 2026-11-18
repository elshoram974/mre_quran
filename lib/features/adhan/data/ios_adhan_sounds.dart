import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// The opening of the adhan as an iOS notification sound. iOS lets no app
/// start a long sound by itself; a notification may play up to 30 seconds
/// of a sound in the app's `Library/Sounds`. So the first 29.5 seconds of
/// the bundled adhan, and of the Fajr adhan, ring with the prayer's alert
/// (built by `tool/audio/build_adhan_audio.py`, bundled for iOS only).
abstract interface class IosAdhanSounds {
  /// Puts the sounds where iOS finds them. Returns false when it could not.
  Future<bool> install();
}

/// Copies the bundled sounds into `Library/Sounds`, once per version.
class LibraryIosAdhanSounds implements IosAdhanSounds {
  /// Creates the installer.
  const LibraryIosAdhanSounds();

  /// The sound of the alert at [fajr] or another prayer's time.
  static String of({required bool fajr}) =>
      fajr ? 'adhan_fajr.caf' : 'adhan_regular.caf';

  static const List<String> _names = ['adhan_regular.caf', 'adhan_fajr.caf'];

  @override
  Future<bool> install() async {
    try {
      final library = await getLibraryDirectory();
      final folder = Directory('${library.path}/Sounds');
      await folder.create(recursive: true);
      for (final name in _names) {
        final data = await rootBundle.load('assets/adhan/ios/$name');
        final file = File('${folder.path}/$name');
        if (await file.exists() && await file.length() == data.lengthInBytes) {
          continue;
        }
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
      return true;
    } on Object {
      return false;
    }
  }
}
