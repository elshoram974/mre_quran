import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/config/store_links.dart';
import 'package:mre_quran/core/sharing/app_share_text.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

const _play = StoreLink('Google Play', 'https://play.google.com/store/apps/x');
const _apple = StoreLink('App Store', 'https://apps.apple.com/app/x');

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('the footer names the app and gives one line for each store', () {
    expect(
      appShareFooter(ar, const [_play, _apple]),
      'حمّل تطبيق مصحفي:\n'
      'Google Play: https://play.google.com/store/apps/x\n'
      'App Store: https://apps.apple.com/app/x',
    );
    expect(
      appShareFooter(en, const [_apple]),
      'Get Mushafi:\nApp Store: https://apps.apple.com/app/x',
    );
  });

  test('with no store there is no footer, not even a name', () {
    expect(appShareFooter(ar, const []), isNull);
    expect(appShareText(ar, const []), isNull);
  });

  test('sharing the app says what it is, then where to get it', () {
    final text = appShareText(ar, const [_play])!;
    expect(text, startsWith('أنصحك بتطبيق مصحفي'));
    expect(text, endsWith('Google Play: https://play.google.com/store/apps/x'));
    expect(text, contains('\n\nحمّل تطبيق مصحفي:'));
  });
}
