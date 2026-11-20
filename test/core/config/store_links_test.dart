import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/config/app_config.dart';
import 'package:mre_quran/core/config/store_links.dart';

void main() {
  test('only a store that has the app is a link', () {
    final links = StoreLink.available(const [
      (store: 'Google Play', url: 'https://play.google.com/store/apps/x'),
      (store: 'App Store', url: ''),
      (store: 'AppGallery', url: '  https://appgallery.huawei.com/app/x  '),
    ]);
    expect(links, const [
      StoreLink('Google Play', 'https://play.google.com/store/apps/x'),
      StoreLink('AppGallery', 'https://appgallery.huawei.com/app/x'),
    ]);
  });

  test('an address that is not a web address is left out too', () {
    final links = StoreLink.available(const [
      (store: 'A', url: 'play.google.com/x'),
      (store: 'B', url: 'ftp://example.test/x'),
      (store: 'C', url: 'not a link'),
      (store: 'D', url: 'https://'),
      (store: 'E', url: 'http://example.test/x'),
    ]);
    expect(links.map((link) => link.store), ['E']);
  });

  test('the order of the stores is the order they are written in', () {
    final links = StoreLink.available(const [
      (store: 'Second', url: 'https://b.test/'),
      (store: 'First', url: 'https://a.test/'),
    ]);
    expect(links.map((link) => link.store), ['Second', 'First']);
  });

  test('the config names the three stores, whatever their addresses', () {
    expect(AppConfig.stores.map((entry) => entry.store), [
      'Google Play',
      'App Store',
      'AppGallery',
    ]);
  });
}
