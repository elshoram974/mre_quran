import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhan/data/adhan_catalog.dart';
import 'package:mre_quran/features/adhan/domain/adhan_voice.dart';

Map<String, Object?> _voice(String id, {bool builtIn = false}) => {
  'id': id,
  if (builtIn) 'builtIn': true,
  'title': {'ar': 'صوت', 'en': 'Voice'},
  'place': {'ar': 'مكان', 'en': 'Place'},
  'bytes': 10,
  'sha256': 'a' * 64,
  if (!builtIn) 'url': 'https://example.test/$id.ogg',
  'source': 'https://example.test/$id',
  'license': {'name': 'CC0', 'url': 'https://example.test/cc0'},
  'credit': 'Someone',
};

String _catalog(List<Map<String, Object?>> voices, {int schema = 1}) =>
    jsonEncode({'schema': schema, 'voices': voices});

void main() {
  final real = File('assets/adhan/voices.json').readAsStringSync();

  group('the catalogue that ships', () {
    final voices = parseAdhanCatalog(real);

    test('has the bundled voice first, and some to download', () {
      expect(voices.first.id, AdhanVoice.defaultId);
      expect(voices.first.builtIn, isTrue);
      expect(voices.where((voice) => !voice.builtIn), isNotEmpty);
    });

    test('every voice carries its licence, credit, source and checksum', () {
      for (final voice in voices) {
        expect(voice.license.name, isNotEmpty, reason: voice.id);
        expect(voice.license.url, startsWith('https://'), reason: voice.id);
        expect(voice.credit, isNotEmpty, reason: voice.id);
        expect(voice.sourceUrl, startsWith('https://'), reason: voice.id);
        expect(voice.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(voice.titles['ar'], isNotEmpty, reason: voice.id);
        expect(voice.titles['en'], isNotEmpty, reason: voice.id);
        if (!voice.builtIn) {
          expect(voice.url, startsWith('https://upload.wikimedia.org/'));
        }
      }
    });

    test('the bundled recording is the file the catalogue describes', () {
      final file = File('android/app/src/main/res/raw/adhan_default.ogg');
      final bytes = file.readAsBytesSync();
      final voice = voices.first;
      expect(bytes.length, voice.bytes);
      expect(sha256.convert(bytes).toString(), voice.sha256);
    });

    test('every voice is written up in docs/AUDIO_SOURCES.md', () {
      final doc = File('docs/AUDIO_SOURCES.md').readAsStringSync();
      for (final voice in voices) {
        expect(doc, contains('`${voice.id}`'), reason: voice.id);
        expect(doc, contains(voice.sha256.substring(0, 8)), reason: voice.id);
      }
    });
  });

  group('parsing', () {
    test('refuses a voice with no licence', () {
      final voice = _voice('x')..remove('license');
      expect(
        () => parseAdhanCatalog(
          _catalog([_voice('default', builtIn: true), voice]),
        ),
        throwsFormatException,
      );
    });

    test('refuses a download that is not https', () {
      final voice = _voice('x')..['url'] = 'http://example.test/x.ogg';
      expect(
        () => parseAdhanCatalog(
          _catalog([_voice('default', builtIn: true), voice]),
        ),
        throwsFormatException,
      );
    });

    test('refuses a bad checksum, a repeated id, no default, a new schema', () {
      final bad = _voice('x')..['sha256'] = 'abc';
      expect(
        () => parseAdhanCatalog(
          _catalog([_voice('default', builtIn: true), bad]),
        ),
        throwsFormatException,
      );
      expect(
        () => parseAdhanCatalog(
          _catalog([_voice('default', builtIn: true), _voice('default')]),
        ),
        throwsFormatException,
      );
      expect(
        () => parseAdhanCatalog(_catalog([_voice('x')])),
        throwsFormatException,
      );
      expect(
        () => parseAdhanCatalog(
          _catalog([_voice('default', builtIn: true)], schema: 2),
        ),
        throwsFormatException,
      );
    });

    test('puts the bundled voice first whatever the order', () {
      final voices = parseAdhanCatalog(
        _catalog([_voice('x'), _voice('default', builtIn: true)]),
      );
      expect(voices.map((voice) => voice.id), ['default', 'x']);
    });

    test('names fall back to Arabic', () {
      final voice = parseAdhanCatalog(
        _catalog([_voice('default', builtIn: true)]),
      ).single;
      expect(voice.title('en'), 'Voice');
      expect(voice.title('fr'), 'صوت');
      expect(voice.place('fr'), 'مكان');
    });
  });
}
