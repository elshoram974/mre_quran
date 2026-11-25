import 'package:flutter/foundation.dart';

/// The terms a recording is shared under, and who to credit.
@immutable
class AdhanLicense {
  /// Creates the licence.
  const AdhanLicense({required this.name, required this.url});

  /// A short name such as "CC BY 3.0".
  final String name;

  /// The licence text.
  final String url;
}

/// A file a voice may be downloaded from, with what it must be.
@immutable
class AdhanFile {
  /// Creates the file.
  const AdhanFile({
    required this.url,
    required this.bytes,
    required this.sha256,
    required this.extension,
  });

  /// Where it is.
  final String url;

  /// Its size, in bytes.
  final int bytes;

  /// Its SHA-256, as 64 lowercase hex characters.
  final String sha256;

  /// Its extension, without a dot.
  final String extension;
}

/// Which prayers a recording is for.
enum AdhanKind {
  /// The adhan of Dhuhr, Asr, Maghrib and Isha.
  regular,

  /// The Fajr adhan, which says "الصلاة خير من النوم" twice.
  fajr,

  /// The dua after the adhan, not an adhan: chosen among the duas.
  dua,
}

/// One adhan recording the person can choose.
///
/// The data comes from `assets/adhan/voices.json`; see `docs/AUDIO_SOURCES.md`
/// for where each file is from and what its licence asks for.
@immutable
class AdhanVoice {
  /// Creates a voice.
  const AdhanVoice({
    required this.id,
    required this.titles,
    required this.places,
    required this.bytes,
    required this.sha256,
    required this.sourceUrl,
    required this.license,
    required this.credit,
    this.url,
    this.extension = 'audio',
    this.builtIn = false,
    this.kind = AdhanKind.regular,
    this.fallback,
  });

  /// The id of the voice that ships with the app.
  static const String defaultId = 'default';

  /// The id of the Fajr voice that ships with the app.
  static const String defaultFajrId = 'default_fajr';

  /// The id of the file the person chose from their own phone.
  static const String customId = 'custom';

  /// A stable id, used in storage and file names.
  final String id;

  /// The name by language code.
  final Map<String, String> titles;

  /// Where the recording was made, by language code.
  final Map<String, String> places;

  /// The size of the file, in bytes.
  final int bytes;

  /// The SHA-256 of the file, as 64 lowercase hex characters.
  final String sha256;

  /// Where the file is downloaded from; null for the bundled voice.
  final String? url;

  /// The file's extension, without a dot.
  final String extension;

  /// The page the recording and its licence are published on.
  final String sourceUrl;

  /// The terms it is shared under.
  final AdhanLicense license;

  /// Who to credit.
  final String credit;

  /// Whether the file ships inside the app.
  final bool builtIn;

  /// Which prayers it is for.
  final AdhanKind kind;

  /// Where else it can be had when [url] cannot: the recording's own file
  /// where it was found, uncleaned.
  final AdhanFile? fallback;

  /// The files it may be downloaded from, in order of preference.
  List<AdhanFile> get files => [
    if (url case final url?)
      AdhanFile(url: url, bytes: bytes, sha256: sha256, extension: extension),
    ?fallback,
  ];

  /// Whether it is a Fajr adhan.
  bool get isFajr => kind == AdhanKind.fajr;

  /// Whether it is the dua after the adhan rather than an adhan.
  bool get isDua => kind == AdhanKind.dua;

  /// The title in [language], else Arabic, else the id.
  String title(String language) => titles[language] ?? titles['ar'] ?? id;

  /// The place in [language], else Arabic, else empty.
  String place(String language) => places[language] ?? places['ar'] ?? '';
}
