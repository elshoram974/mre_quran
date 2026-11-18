import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhan/data/adhan_catalog.dart';
import 'package:mre_quran/features/adhan/domain/adhan_settings.dart';
import 'package:mre_quran/features/adhan/domain/adhan_voice.dart';

Map<String, Object?> _voice(
  String id, {
  bool builtIn = false,
  bool fajr = false,
}) => {
  'id': id,
  if (builtIn) 'builtIn': true,
  if (fajr) 'kind': 'fajr',
  'title': {'ar': 'صوت', 'en': 'Voice'},
  'place': {'ar': 'مكان', 'en': 'Place'},
  'bytes': 10,
  'sha256': 'a' * 64,
  if (!builtIn) 'url': 'https://example.test/$id.ogg',
  'source': 'https://example.test/$id',
  'license': {'name': 'CC0', 'url': 'https://example.test/cc0'},
  'credit': 'Someone',
};

String _catalog(List<Map<String, Object?>> voices, {int schema = 2}) =>
    jsonEncode({'schema': schema, 'voices': voices});

/// The two voices every catalogue bundles: the adhan and the Fajr adhan.
List<Map<String, Object?>> get _bundled => [
  _voice('default', builtIn: true),
  _voice('default_fajr', builtIn: true, fajr: true),
];

void main() {
  final real = File('assets/adhan/voices.json').readAsStringSync();

  group('the catalogue that ships', () {
    final voices = parseAdhanCatalog(real);

    test('bundles an adhan and a Fajr adhan first, and has more of each to '
        'download', () {
      expect(voices.take(2).map((voice) => voice.id), [
        AdhanVoice.defaultId,
        AdhanVoice.defaultFajrId,
      ]);
      expect(voices.take(2).every((voice) => voice.builtIn), isTrue);
      expect(voices[1].isFajr, isTrue);
      for (final fajr in [false, true]) {
        expect(
          voices.where((voice) => !voice.builtIn && voice.isFajr == fajr),
          isNotEmpty,
        );
      }
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
          // Each download is a file at a fixed address: a media repository
          // tag, a GitHub commit, or an archive.org item.
          expect(voice.url, startsWith('https://'), reason: voice.id);
          expect(['m4a', 'mp3', 'ogg'], contains(voice.extension));
        }
      }
    });

    test('the bundled recordings are the files the catalogue describes', () {
      for (final (id, name) in [
        (AdhanVoice.defaultId, 'adhan_default'),
        (AdhanVoice.defaultFajrId, 'adhan_fajr'),
      ]) {
        final file = File('android/app/src/main/res/raw/$name.m4a');
        final bytes = file.readAsBytesSync();
        final voice = voices.firstWhere((voice) => voice.id == id);
        expect(bytes.length, voice.bytes, reason: id);
        expect(sha256.convert(bytes).toString(), voice.sha256, reason: id);
      }
    });

    test('every dua after the adhan the settings offer ships beside them', () {
      for (final dua in AdhanDua.values) {
        expect(
          File('android/app/src/main/res/raw/${dua.recording}.m4a')
              .existsSync(),
          isTrue,
          reason: dua.name,
        );
      }
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
        () => parseAdhanCatalog(_catalog([..._bundled, voice])),
        throwsFormatException,
      );
    });

    test('refuses a download that is not https', () {
      final voice = _voice('x')..['url'] = 'http://example.test/x.ogg';
      expect(
        () => parseAdhanCatalog(_catalog([..._bundled, voice])),
        throwsFormatException,
      );
    });

    test(
      'refuses a bad checksum, a repeated id, no default, an old schema',
      () {
        final bad = _voice('x')..['sha256'] = 'abc';
        expect(
          () => parseAdhanCatalog(_catalog([..._bundled, bad])),
          throwsFormatException,
        );
        expect(
          () => parseAdhanCatalog(_catalog([..._bundled, _voice('default')])),
          throwsFormatException,
        );
        expect(
          () => parseAdhanCatalog(_catalog([_voice('x')])),
          throwsFormatException,
        );
        expect(
          () => parseAdhanCatalog(_catalog(_bundled, schema: 1)),
          throwsFormatException,
        );
        // No bundled Fajr adhan, or one that is not for Fajr.
        expect(
          () => parseAdhanCatalog(_catalog([_voice('default', builtIn: true)])),
          throwsFormatException,
        );
        expect(
          () => parseAdhanCatalog(
            _catalog([
              _voice('default', builtIn: true),
              _voice('default_fajr', builtIn: true),
            ]),
          ),
          throwsFormatException,
        );
      },
    );

    test('puts the bundled voice first whatever the order', () {
      final voices = parseAdhanCatalog(_catalog([_voice('x'), ..._bundled]));
      expect(voices.map((voice) => voice.id), ['default', 'default_fajr', 'x']);
    });

    test('names fall back to Arabic', () {
      final voice = parseAdhanCatalog(_catalog(_bundled)).first;
      expect(voice.title('en'), 'Voice');
      expect(voice.title('fr'), 'صوت');
      expect(voice.place('fr'), 'مكان');
    });
  });
}
