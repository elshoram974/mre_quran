import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/data/adhkar_parser.dart';
import 'package:mre_quran/features/adhkar/data/adhkar_source.dart';

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

Map<String, Object?> _entry({
  int order = 1,
  int count = 1,
  Object? source = 'مصدر',
}) => {
  'order': order,
  'content': 'ذكر',
  'count': count,
  'count_description': 'مرة',
  'fadl': '',
  'source': source,
  'type': 0,
  'audio': '',
  'hadith_text': '',
  'explanation_of_hadith_vocabulary': '',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled data', () {
    test(
      'loads, verifies, and splits the shared file into collections',
      () async {
        final catalog = await AdhkarSource(bundle: _DiskBundle()).load();
        expect(catalog.collections.map((c) => c.id), ['morning', 'evening']);
        final morning = catalog.byId('morning')!;
        final evening = catalog.byId('evening')!;
        expect(morning.entries, isNotEmpty);
        expect(evening.entries, isNotEmpty);
        // Variant 1 is morning only, 2 is evening only, 0 is both.
        expect(morning.entries.every((e) => e.variant != 2), isTrue);
        expect(evening.entries.every((e) => e.variant != 1), isTrue);
        expect(
          morning.entries.where((e) => e.variant == 0).map((e) => e.order),
          evening.entries.where((e) => e.variant == 0).map((e) => e.order),
        );
      },
    );

    test('every dhikr has words, a repeat count, and its evidence', () async {
      final catalog = await AdhkarSource(bundle: _DiskBundle()).load();
      for (final collection in catalog.collections) {
        expect(collection.titles['ar'], isNotEmpty);
        for (final entry in collection.entries) {
          expect(entry.text.trim(), isNotEmpty, reason: '${entry.order}');
          expect(entry.repeat, greaterThanOrEqualTo(1));
          expect(entry.source.trim(), isNotEmpty, reason: '${entry.order}');
        }
      }
    });

    test('refuses a file changed by even one character', () async {
      final bytes = File('assets/adhkar/morning_evening.ar.json')
          .readAsBytesSync();
      final changed = Uint8List.fromList([...bytes, 0x20]);
      expect(
        AdhkarSource(
          bundle: _DiskBundle({
            'assets/adhkar/morning_evening.ar.json': changed,
          }),
        ).load(),
        throwsA(isA<AdhkarIntegrityException>()),
      );
    });
  });

  group('AdhkarParser', () {
    test('rejects an entry without evidence', () {
      expect(
        () => AdhkarParser.parseEntries(jsonEncode([_entry(source: '')])),
        throwsA(isA<AdhkarDataException>()),
      );
    });

    test('rejects a repeat count below one and duplicate orders', () {
      expect(
        () => AdhkarParser.parseEntries(jsonEncode([_entry(count: 0)])),
        throwsA(isA<AdhkarDataException>()),
      );
      expect(
        () => AdhkarParser.parseEntries(jsonEncode([_entry(), _entry()])),
        throwsA(isA<AdhkarDataException>()),
      );
    });

    test('rejects a manifest with a bad schema, time, or title', () {
      Map<String, Object?> collection({
        Object? time = '05:30',
        Object? ar = 'س',
      }) => {
        'id': 'a',
        'title': {'ar': ar},
        'file': 'a.json',
        'sha256': 'x',
        'variants': [0],
        'reminderTime': time,
      };
      String manifest(Map<String, Object?> c, {int schema = 1}) => jsonEncode({
        'schema': schema,
        'collections': [c],
      });

      expect(AdhkarParser.parseManifest(manifest(collection())), hasLength(1));
      for (final bad in [
        manifest(collection(), schema: 2),
        manifest(collection(time: '5:30')),
        manifest(collection(time: '24:00')),
        manifest(collection(ar: null)),
      ]) {
        expect(
          () => AdhkarParser.parseManifest(bad),
          throwsA(isA<AdhkarDataException>()),
        );
      }
    });

    test('an unknown icon name falls back to the generic icon', () {
      final specs = AdhkarParser.parseManifest(
        jsonEncode({
          'schema': 1,
          'collections': [
            {
              'id': 'a',
              'title': {'ar': 'س'},
              'icon': 'rocket',
              'file': 'a.json',
              'sha256': 'x',
              'variants': [0],
            },
          ],
        }),
      );
      expect(specs.single.icon.name, 'generic');
      expect(specs.single.reminderMinutes, isNull);
    });
  });
}
