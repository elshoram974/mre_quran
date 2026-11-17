import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_links.dart';

/// Opens an address outside the app, in the browser.
abstract interface class LinkOpener {
  /// Opens [uri]; false when nothing on the device could.
  Future<bool> open(Uri uri);
}

/// Opens addresses with the platform's browser.
class PlatformLinkOpener implements LinkOpener {
  /// Creates the opener.
  const PlatformLinkOpener();

  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Provides the link opener. Tests override it.
final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const PlatformLinkOpener(),
);

/// The privacy policy's address, or null while none is set
/// ([AppLinks.privacyPolicy]). Tests override it.
final privacyPolicyProvider = Provider<Uri?>((ref) {
  const address = AppLinks.privacyPolicy;
  return address.isEmpty ? null : Uri.parse(address);
});
