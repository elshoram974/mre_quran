import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhan/data/voice_store.dart';

import '../../helpers/adhan_fixtures.dart';

void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('voice_store'));
  tearDown(() => folder.deleteSync(recursive: true));

  FileVoiceStore store(VoiceFetcher fetcher) =>
      FileVoiceStore(fetcher: fetcher, directory: () async => folder);

  test('keeps a file whose SHA-256 matches, and says how far it got', () async {
    final progress = <double>[];
    final target = store(FakeVoiceFetcher());
    await target.download(kMadinahVoice, onProgress: progress.add);

    final file = await target.fileOf(kMadinahVoice);
    expect(file, isNotNull);
    expect(await file!.readAsBytes(), kVoiceBytes);
    expect(progress.last, greaterThan(0));
    expect(
      await target.downloaded([kDefaultVoice, kMadinahVoice, kMakkahVoice]),
      {'default', 'madinah'},
    );
    expect(folder.listSync().whereType<File>().map((f) => f.path), [
      '${folder.path}/madinah.ogg',
    ]);
  });

  test(
    'refuses a file that is not the one described, and keeps nothing',
    () async {
      final target = store(FakeVoiceFetcher(bytes: [9, 9, 9, 9]));
      await expectLater(
        target.download(kMadinahVoice),
        throwsA(
          isA<VoiceDownloadException>().having(
            (e) => e.failure,
            'failure',
            VoiceDownloadFailure.integrity,
          ),
        ),
      );
      expect(await target.fileOf(kMadinahVoice), isNull);
      expect(folder.listSync(), isEmpty);
    },
  );

  test('a failed connection leaves nothing behind', () async {
    final target = store(FakeVoiceFetcher(fail: true));
    await expectLater(
      target.download(kMadinahVoice),
      throwsA(isA<VoiceDownloadException>()),
    );
    expect(folder.listSync(), isEmpty);
  });

  test('cancelling stops the download and keeps nothing', () async {
    final token = VoiceDownloadToken()..cancel();
    final target = store(FakeVoiceFetcher());
    await expectLater(
      target.download(kMadinahVoice, token: token),
      throwsA(
        isA<VoiceDownloadException>().having(
          (e) => e.failure,
          'failure',
          VoiceDownloadFailure.cancelled,
        ),
      ),
    );
    expect(folder.listSync(), isEmpty);
  });

  test('deleting removes the file; the bundled voice has none', () async {
    final target = store(FakeVoiceFetcher());
    await target.download(kMadinahVoice);
    await target.delete(kMadinahVoice);
    expect(await target.fileOf(kMadinahVoice), isNull);
    expect(await target.fileOf(kDefaultVoice), isNull);
    await target.delete(kDefaultVoice); // nothing to remove, and no error
  });

  test('the bundled voice is never fetched', () async {
    final fetcher = FakeVoiceFetcher();
    await store(fetcher).download(kDefaultVoice);
    expect(fetcher.opened, isEmpty);
  });
}
