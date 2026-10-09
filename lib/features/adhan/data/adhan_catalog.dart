import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/adhan_voice.dart';

/// The adhan recordings the app knows about.
abstract interface class AdhanCatalogSource {
  /// Reads the voices, the bundled one first.
  Future<List<AdhanVoice>> load();
}

/// Reads `assets/adhan/voices.json`.
class AssetAdhanCatalog implements AdhanCatalogSource {
  /// Creates the source.
  const AssetAdhanCatalog({this.bundle, this.path = _asset});

  static const String _asset = 'assets/adhan/voices.json';

  /// Where to read from; the root bundle when null.
  final AssetBundle? bundle;

  /// The asset path.
  final String path;

  @override
  Future<List<AdhanVoice>> load() async =>
      parseAdhanCatalog(await (bundle ?? rootBundle).loadString(path));
}

/// Parses the catalogue and refuses one with a gap in its evidence: a voice
/// needs a licence, a credit, a source page, a SHA-256, and (unless bundled)
/// an https address.
List<AdhanVoice> parseAdhanCatalog(String json) {
  final root = jsonDecode(json) as Map<String, Object?>;
  if (root['schema'] != 1) {
    throw FormatException('Unsupported adhan catalogue: ${root['schema']}');
  }
  final voices = <AdhanVoice>[
    for (final item in root['voices']! as List<Object?>)
      _voice(item! as Map<String, Object?>),
  ];
  final ids = voices.map((voice) => voice.id).toSet();
  if (ids.length != voices.length) {
    throw const FormatException('Two adhan voices share an id');
  }
  if (!ids.contains(AdhanVoice.defaultId)) {
    throw const FormatException('The catalogue has no default voice');
  }
  // The bundled voice leads the list.
  voices.sort((a, b) => a.builtIn == b.builtIn ? 0 : (a.builtIn ? -1 : 1));
  return voices;
}

AdhanVoice _voice(Map<String, Object?> map) {
  final id = _text(map, 'id');
  final builtIn = map['builtIn'] == true;
  final sha = _text(map, 'sha256');
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
    throw FormatException('Voice $id has no valid SHA-256');
  }
  final url = map['url'] as String?;
  if (!builtIn && (url == null || !url.startsWith('https://'))) {
    throw FormatException('Voice $id needs an https url');
  }
  final license = map['license'] as Map<String, Object?>?;
  if (license == null) throw FormatException('Voice $id has no licence');
  return AdhanVoice(
    id: id,
    titles: _texts(map, 'title'),
    places: _texts(map, 'place'),
    bytes: map['bytes']! as int,
    sha256: sha,
    url: url,
    extension: (map['extension'] as String?) ?? 'audio',
    sourceUrl: _text(map, 'source'),
    license: AdhanLicense(
      name: _text(license, 'name'),
      url: _text(license, 'url'),
    ),
    credit: _text(map, 'credit'),
    builtIn: builtIn,
  );
}

String _text(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing "$key" in ${map['id'] ?? map}');
  }
  return value;
}

Map<String, String> _texts(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! Map<String, Object?> || value.isEmpty) {
    throw FormatException('Missing "$key" in ${map['id']}');
  }
  return value.map((language, text) => MapEntry(language, text! as String));
}
