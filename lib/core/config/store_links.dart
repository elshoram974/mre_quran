import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// The app's page in one store, to put in what is shared.
@immutable
class StoreLink {
  /// Creates the link of [store] at [url].
  const StoreLink(this.store, this.url);

  /// The store's name: "Google Play".
  final String store;

  /// The address of the app's page there.
  final String url;

  /// The links worth sharing among [stores], in their order: those with an
  /// address that is a real web address. An empty or malformed one is left
  /// out, as if the app were not in that store yet.
  static List<StoreLink> available(
    Iterable<({String store, String url})> stores,
  ) => [
    for (final (:store, :url) in stores)
      if (_isWebAddress(url.trim())) StoreLink(store, url.trim()),
  ];

  static bool _isWebAddress(String address) {
    final uri = Uri.tryParse(address);
    return uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  @override
  bool operator ==(Object other) =>
      other is StoreLink && other.store == store && other.url == url;

  @override
  int get hashCode => Object.hash(store, url);
}

/// The stores the app can be shared with, from [AppConfig]. Tests override it.
final storeLinksProvider = Provider<List<StoreLink>>(
  (ref) => StoreLink.available(AppConfig.stores),
);
