import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';

/// Serves asset bytes from disk, with optional replacements.
class _DiskBundle extends CachingAssetBundle {
  _DiskBundle([this.overrides = const {}]);

  final Map<String, Uint8List> overrides;

  @override
  Future<ByteData> load(String key) async {
    final bytes = overrides[key] ?? File(key).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final counts = [
    for (final s in QuranMetadataParser.parse(
      File(QuranMetadataSource.assetPath).readAsStringSync(),
    ).surahs)
      s.ayahCount,
  ];

  test('loads, verifies, and parses both files off the main isolate', () async {
    final data = await QuranTextSource(bundle: _DiskBundle()).load(counts);
    expect(data.uthmani, hasLength(6236));
    expect(data.clean, hasLength(6236));
    expect(data.keys, hasLength(6236));
    expect(data.uthmaniKeys, hasLength(6236));
  });

  test('refuses a text file that was changed by even one character', () async {
    final original = File(QuranTextSource.cleanAsset).readAsStringSync();
    final tampered = Uint8List.fromList(
      utf8.encode(original.replaceFirst('بسم', 'بسن')),
    );
    expect(
      QuranTextSource(
        bundle: _DiskBundle({QuranTextSource.cleanAsset: tampered}),
      ).load(counts),
      throwsA(isA<QuranTextIntegrityException>()),
    );
  });
}
