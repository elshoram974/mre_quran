import 'package:xml/xml.dart';

import '../domain/quran_metadata.dart';

/// Thrown when the metadata file is not what the app expects.
class QuranMetadataFormatException implements Exception {
  /// Creates the exception with a short [message].
  const QuranMetadataFormatException(this.message);

  /// What was wrong.
  final String message;

  @override
  String toString() => 'QuranMetadataFormatException: $message';
}

/// Parses the Tanzil `quran-data.xml` metadata file. Pure Dart.
abstract final class QuranMetadataParser {
  static const int _surahCount = 114;
  static const int _juzCount = 30;
  static const int _pageCount = 604;

  /// Parses [source] and checks the structural counts of the Madinah Mushaf.
  static QuranMetadata parse(String source) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(source);
    } on XmlException catch (error) {
      throw QuranMetadataFormatException('Invalid XML: ${error.message}');
    }
    final root = document.rootElement;
    final suraNodes = root.findAllElements('sura').toList();
    final juzNodes = root.findAllElements('juz').toList();
    final pageNodes = root.findAllElements('page').toList();
    if (suraNodes.length != _surahCount ||
        juzNodes.length != _juzCount ||
        pageNodes.length != _pageCount) {
      throw QuranMetadataFormatException(
        'Expected $_surahCount surahs, $_juzCount juz, $_pageCount pages; '
        'found ${suraNodes.length}, ${juzNodes.length}, ${pageNodes.length}.',
      );
    }

    final pageStarts = [
      for (final node in pageNodes)
        PageStart(surah: _int(node, 'sura'), ayah: _int(node, 'aya')),
    ];

    int pageOf(int surah, int ayah) => pageOfAyah(pageStarts, surah, ayah);

    final surahs = [
      for (final node in suraNodes)
        Surah(
          number: _int(node, 'index'),
          ayahCount: _int(node, 'ayas'),
          arabicName: _text(node, 'name'),
          transliteration: _text(node, 'tname'),
          englishName: _text(node, 'ename'),
          revelation: _text(node, 'type') == 'Medinan'
              ? Revelation.medinan
              : Revelation.meccan,
          startPage: pageOf(_int(node, 'index'), 1),
        ),
    ];
    final juzs = [
      for (final node in juzNodes)
        Juz(
          number: _int(node, 'index'),
          surah: _int(node, 'sura'),
          ayah: _int(node, 'aya'),
          startPage: pageOf(_int(node, 'sura'), _int(node, 'aya')),
        ),
    ];
    return QuranMetadata(
      surahs: List.unmodifiable(surahs),
      juzs: List.unmodifiable(juzs),
      pageStarts: List.unmodifiable(pageStarts),
    );
  }

  static String _text(XmlElement node, String name) {
    final value = node.getAttribute(name);
    if (value == null) {
      throw QuranMetadataFormatException('Missing "$name" on <${node.name}>');
    }
    return value;
  }

  static int _int(XmlElement node, String name) {
    final value = int.tryParse(_text(node, name));
    if (value == null) {
      throw QuranMetadataFormatException('"$name" is not a number');
    }
    return value;
  }
}
