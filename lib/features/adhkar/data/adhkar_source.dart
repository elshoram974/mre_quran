import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../domain/adhkar_collection.dart';
import '../domain/dhikr.dart';
import 'adhkar_parser.dart';

/// Raised when a bundled adhkar file does not match its recorded checksum.
class AdhkarIntegrityException implements Exception {
  /// Creates the exception.
  const AdhkarIntegrityException(this.asset, this.actual);

  /// Asset that failed.
  final String asset;

  /// SHA-256 that was computed.
  final String actual;

  @override
  String toString() =>
      'AdhkarIntegrityException: unexpected checksum $actual for $asset';
}

/// Loads the bundled adhkar after verifying every file against the manifest.
///
/// Add or change content by editing `assets/adhkar/` only; see
/// `docs/ADHKAR_SOURCES.md`. The morning and evening file is the unmodified
/// `ar.json` of Seen-Arabic/Morning-And-Evening-Adhkar-DB (MIT).
class AdhkarSource {
  /// Creates a source reading from [bundle], the root bundle by default.
  AdhkarSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Folder holding the manifest and the entry files.
  static const String folder = 'assets/adhkar';

  /// Asset path of the manifest.
  static const String manifestAsset = '$folder/manifest.json';

  final AssetBundle _bundle;

  /// Reads, verifies, and parses every collection.
  ///
  /// The files are small (under 1 MB), so parsing stays on the main isolate.
  Future<AdhkarCatalog> load() async {
    final main = AdhkarParser.parseManifest(
      await _bundle.loadString(manifestAsset),
    );
    final specs = [...main.specs];
    for (final include in main.includes) {
      final extra = AdhkarParser.parseManifest(
        await _bundle.loadString('$folder/$include'),
      );
      specs.addAll(extra.specs);
    }
    final ids = specs.map((spec) => spec.id).toSet();
    if (ids.length != specs.length) {
      throw const AdhkarDataException('Duplicate collection id');
    }
    final groups = main.groups.isEmpty
        ? const [
            AdhkarGroup(id: 'all', titles: {'ar': 'الأذكار'}),
          ]
        : main.groups;
    final parsed = <String, List<Dhikr>>{};
    for (final spec in specs) {
      if (parsed.containsKey(spec.file)) continue;
      final asset = '$folder/${spec.file}';
      final data = await _bundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final actual = sha256.convert(bytes).toString();
      if (actual != spec.sha256) throw AdhkarIntegrityException(asset, actual);
      parsed[spec.file] = AdhkarParser.parseEntries(utf8.decode(bytes));
    }
    final collections = [
      for (final spec in specs)
        spec.build(parsed[spec.file]!, _groupOf(spec, groups)),
    ];
    final used = {for (final collection in collections) collection.group};
    return AdhkarCatalog(
      collections,
      groups: [
        for (final group in groups)
          if (used.contains(group)) group,
      ],
    );
  }

  static AdhkarGroup _groupOf(
    AdhkarCollectionSpec spec,
    List<AdhkarGroup> groups,
  ) {
    final id = spec.groupId;
    if (id == null) return groups.first;
    for (final group in groups) {
      if (group.id == id) return group;
    }
    throw AdhkarDataException('Collection ${spec.id} is in unknown group $id');
  }
}
