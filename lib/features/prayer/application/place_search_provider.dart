import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/place_name_source.dart';
import '../data/place_search_source.dart';

/// Searches place names without depending on a Google Places API key.
final placeSearchSourceProvider = Provider<PlaceSearchSource>(
  (ref) => const PlatformPlaceSearchSource(),
);

/// Finds what a place is called, to show in place of its coordinates.
final placeNameSourceProvider = Provider<PlaceNameSource>(
  (ref) => const PlatformPlaceNameSource(),
);
