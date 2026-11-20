/// The app's fixed facts in one place: its names, its version, and every
/// address outside the app it uses. Change them here only.
///
/// The names shown in the app's own language stay in the ARB files
/// (`appTitle`); these are the ones that never change with the language.
abstract final class AppConfig {
  /// The app's name in Latin letters, as the stores list it.
  static const String name = 'Mushafi';

  /// The maker's name, written under "made by" on the launch screen.
  static const String brand = 'MRECode';

  /// The version people see. Keep it equal to `version` in pubspec.yaml
  /// (a test checks it).
  static const String version = '1.0.0';

  /// The build number, after the `+` of `version` in pubspec.yaml.
  static const int build = 1;

  /// Where everything the app downloads is served from: the `global` branch
  /// of `mre_quran_global` (the folder beside this repository), published
  /// with GitHub Pages. Every new media file goes there.
  static const String mediaBase =
      'https://elshoram974.github.io/mre_quran_global/';

  /// The privacy policy, in the same place. Both stores ask for it too.
  static const String privacyPolicy = '${mediaBase}privacy/';

  /// The WhatsApp number people can write to, in international form
  /// without the `+`.
  static const String whatsAppNumber = '201553668845';

  /// The email address people can write to.
  static const String email = 'riyadm2001@gmail.com';

  /// The app's page in Google Play. Leave it empty until the app is there:
  /// an empty address is left out of everything that shares the app.
  static const String googlePlayUrl = '';

  /// The app's page in the App Store. Empty until it is there.
  static const String appStoreUrl = '';

  /// The app's page in Huawei AppGallery. Empty until it is there.
  static const String appGalleryUrl = '';

  /// The stores, each with the name people know it by (which never changes
  /// with the language) and its address; the ones with no address are
  /// dropped by [StoreLink.available].
  static const List<({String store, String url})> stores = [
    (store: 'Google Play', url: googlePlayUrl),
    (store: 'App Store', url: appStoreUrl),
    (store: 'AppGallery', url: appGalleryUrl),
  ];

  /// Opens a WhatsApp chat with [whatsAppNumber].
  static final Uri whatsApp = Uri.https('wa.me', '/$whatsAppNumber');

  /// Starts an email to [email] about the app.
  static final Uri mail = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {'subject': name},
  );
}
