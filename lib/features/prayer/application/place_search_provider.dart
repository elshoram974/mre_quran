import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/place_search_source.dart';

/// Searches place names without depending on a Google Places API key.
final placeSearchSourceProvider = Provider<PlaceSearchSource>(
  (ref) => const PlatformPlaceSearchSource(),
);
