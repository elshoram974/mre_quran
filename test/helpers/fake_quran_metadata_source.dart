import 'dart:io';

import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';

/// Reads the real asset file synchronously so widget tests finish loading.
class FakeQuranMetadataSource extends QuranMetadataSource {
  @override
  Future<QuranMetadata> load() async => QuranMetadataParser.parse(
    File(QuranMetadataSource.assetPath).readAsStringSync(),
  );
}
