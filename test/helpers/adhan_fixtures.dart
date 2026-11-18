import 'dart:async';
import 'dart:io';

import 'package:mre_quran/features/adhan/data/adhan_catalog.dart';
import 'package:mre_quran/features/adhan/data/adhan_platform.dart';
import 'package:mre_quran/features/adhan/data/adhan_repository.dart';
import 'package:mre_quran/features/adhan/data/voice_store.dart';
import 'package:mre_quran/features/adhan/domain/adhan_settings.dart';
import 'package:mre_quran/features/adhan/domain/adhan_voice.dart';

/// The bundled voice and two that can be downloaded.
const AdhanVoice kDefaultVoice = AdhanVoice(
  id: AdhanVoice.defaultId,
  titles: {'ar': 'الأذان الافتراضي', 'en': 'Default adhan'},
  places: {'ar': 'مسجد', 'en': 'A mosque'},
  bytes: 1200000,
  sha256: '35fe06b08fe80505c550c33fed8a783fa9901ddc81ac884958b4be048f5b2a79',
  sourceUrl: 'https://example.test/default',
  license: AdhanLicense(name: 'CC0 1.0', url: 'https://example.test/cc0'),
  credit: 'Someone',
  builtIn: true,
);

/// A voice that is downloaded, with the SHA-256 of [kVoiceBytes].
const AdhanVoice kMadinahVoice = AdhanVoice(
  id: 'madinah',
  titles: {'ar': 'أذان المسجد النبوي', 'en': 'Prophet\'s Mosque'},
  places: {'ar': 'المدينة المنورة', 'en': 'Madinah'},
  bytes: 3000000,
  sha256: kVoiceSha256,
  url: 'https://example.test/madinah.ogg',
  extension: 'ogg',
  sourceUrl: 'https://example.test/madinah',
  license: AdhanLicense(name: 'CC BY 3.0', url: 'https://example.test/by'),
  credit: 'ejaz215',
);

/// Another downloadable voice.
const AdhanVoice kMakkahVoice = AdhanVoice(
  id: 'makkah',
  titles: {'ar': 'أذان المسجد الحرام', 'en': 'Grand Mosque'},
  places: {'ar': 'مكة المكرمة', 'en': 'Makkah'},
  bytes: 9000000,
  sha256: kVoiceSha256,
  url: 'https://example.test/makkah.webm',
  extension: 'webm',
  sourceUrl: 'https://example.test/makkah',
  license: AdhanLicense(name: 'CC BY 3.0', url: 'https://example.test/by'),
  credit: 'Seyfula Islam',
);

/// The bundled Fajr adhan.
const AdhanVoice kDefaultFajrVoice = AdhanVoice(
  id: AdhanVoice.defaultFajrId,
  titles: {'ar': 'أذان الفجر', 'en': 'Fajr adhan'},
  places: {'ar': 'مسجد', 'en': 'A mosque'},
  bytes: 1800000,
  sha256: '12dc0334fc4d557db1a0f52592fdd0bec9ee4750349de2517a4dd9f3350ffea2',
  sourceUrl: 'https://example.test/default_fajr',
  license: AdhanLicense(name: 'CC0 1.0', url: 'https://example.test/cc0'),
  credit: 'Someone',
  builtIn: true,
  kind: AdhanKind.fajr,
);

/// A Fajr adhan that is downloaded.
const AdhanVoice kFajrVoice = AdhanVoice(
  id: 'fajr_voice',
  titles: {'ar': 'أذان فجر للتنزيل', 'en': 'A Fajr adhan to download'},
  places: {'ar': 'مكة المكرمة', 'en': 'Makkah'},
  bytes: 2000000,
  sha256: kVoiceSha256,
  url: 'https://example.test/fajr_voice.m4a',
  extension: 'm4a',
  sourceUrl: 'https://example.test/fajr_voice',
  license: AdhanLicense(name: 'CC BY 3.0', url: 'https://example.test/by'),
  credit: 'Someone',
  kind: AdhanKind.fajr,
);

/// A voice served first from the app's own copy, with its original as the
/// fallback; both are [kVoiceBytes].
const AdhanVoice kFallbackVoice = AdhanVoice(
  id: 'with_fallback',
  titles: {'ar': 'صوت له بديل', 'en': 'A voice with a fallback'},
  places: {'ar': 'مصر', 'en': 'Egypt'},
  bytes: 8,
  sha256: kVoiceSha256,
  url: 'https://example.test/global/with_fallback.m4a',
  extension: 'm4a',
  sourceUrl: 'https://example.test/with_fallback',
  license: AdhanLicense(name: 'CC0 1.0', url: 'https://example.test/cc0'),
  credit: 'Someone',
  fallback: AdhanFile(
    url: 'https://example.test/original/with_fallback.mp3',
    bytes: 8,
    sha256: kVoiceSha256,
    extension: 'mp3',
  ),
);

/// The bytes a fake download delivers, and their SHA-256.
const List<int> kVoiceBytes = [1, 2, 3, 4, 5, 6, 7, 8];
const String kVoiceSha256 =
    '66840dda154e8a113c31dd0ad32f7f3a366a80e8136979d8f5a101d3d29d6f72';

/// A fixed catalogue.
class FakeAdhanCatalog implements AdhanCatalogSource {
  FakeAdhanCatalog([
    this.voices = const [
      kDefaultVoice,
      kDefaultFajrVoice,
      kMadinahVoice,
      kMakkahVoice,
      kFajrVoice,
    ],
  ]);

  final List<AdhanVoice> voices;

  @override
  Future<List<AdhanVoice>> load() async => voices;
}

/// Keeps the adhan choices in memory.
class MemoryAdhanRepository implements AdhanRepository {
  AdhanSettings settings = const AdhanSettings();

  @override
  Future<AdhanSettings> load() async => settings;

  @override
  Future<void> save(AdhanSettings value) async => settings = value;
}

/// Records what the app asks of the platform.
class FakeAdhanPlatform implements AdhanPlatform {
  FakeAdhanPlatform({this.supported = true, this.launch});

  bool supported;
  final String? launch;
  List<AdhanAlarm> alarms = [];
  AdhanAlertConfig? config;
  int cancels = 0;
  final List<AdhanPreviewSource> previews = [];
  int stops = 0;
  final List<AdhanAlarm> tests = [];
  final StreamController<void> ended = StreamController<void>.broadcast();
  final StreamController<String> tapController =
      StreamController<String>.broadcast();

  @override
  Future<bool> isSupported() async => supported;

  /// The recordings the fake app carries.
  Set<String> recordings = {};

  @override
  Future<Set<String>> bundled(Iterable<String> names) async =>
      names.where(recordings.contains).toSet();

  @override
  Future<void> schedule(
    List<AdhanAlarm> alarms,
    AdhanAlertConfig config,
  ) async {
    this.alarms = alarms;
    this.config = config;
  }

  @override
  Future<void> cancelAll() async {
    cancels++;
    alarms = [];
  }

  @override
  Future<void> test(AdhanAlarm alarm, AdhanAlertConfig config) async {
    tests.add(alarm);
    this.config = config;
  }

  @override
  Future<void> preview(AdhanPreviewSource source) async => previews.add(source);

  @override
  Future<void> stopPreview() async => stops++;

  @override
  Stream<void> get previewEnded => ended.stream;

  /// What picking a file returns (null: the person backed out).
  AudioPick? pick;
  int picks = 0;

  @override
  Future<AudioPick?> pickAudioFile() async {
    picks++;
    return pick;
  }

  @override
  Future<String?> takeLaunchPayload() async => launch;

  @override
  Stream<String> get taps => tapController.stream;
}

/// Pretends to download: marks the voice saved, or fails.
class FakeVoiceStore implements VoiceStore {
  FakeVoiceStore({Set<String> saved = const {}}) : saved = {...saved};

  final Set<String> saved;
  VoiceDownloadFailure? failWith;
  Completer<void>? gate;
  final Directory _folder = Directory.systemTemp.createTempSync('adhan_fake');

  @override
  Future<Set<String>> downloaded(Iterable<AdhanVoice> voices) async => {
    for (final voice in voices)
      if (voice.builtIn || saved.contains(voice.id)) voice.id,
  };

  @override
  Future<File?> fileOf(AdhanVoice voice) async => saved.contains(voice.id)
      ? File('${_folder.path}/${voice.id}.audio')
      : null;

  @override
  Future<void> download(
    AdhanVoice voice, {
    void Function(double progress)? onProgress,
    VoiceDownloadToken? token,
  }) async {
    onProgress?.call(0.5);
    await gate?.future;
    if (token?.isCancelled ?? false) {
      throw const VoiceDownloadException(VoiceDownloadFailure.cancelled);
    }
    final failure = failWith;
    if (failure != null) throw VoiceDownloadException(failure);
    saved.add(voice.id);
  }

  @override
  Future<void> delete(AdhanVoice voice) async => saved.remove(voice.id);
}

/// Serves [bytes] for any address, or fails.
class FakeVoiceFetcher implements VoiceFetcher {
  FakeVoiceFetcher({
    this.bytes = kVoiceBytes,
    this.fail = false,
    this.missing = const {},
  });

  final List<int> bytes;
  final bool fail;

  /// Addresses that answer with nothing (not published yet, say).
  final Set<String> missing;
  final List<Uri> opened = [];

  @override
  Future<bool> reachable(Uri url) async =>
      !fail && !missing.contains(url.toString());

  @override
  Stream<List<int>> open(Uri url) async* {
    opened.add(url);
    if (fail || missing.contains(url.toString())) {
      throw const VoiceDownloadException(VoiceDownloadFailure.network);
    }
    // Two chunks, so progress moves.
    yield bytes.sublist(0, bytes.length ~/ 2);
    yield bytes.sublist(bytes.length ~/ 2);
  }
}
