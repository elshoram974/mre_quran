import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/domain/app_settings.dart';
import 'svg_page_providers.dart';

/// Where a printed page that cannot be had here can still be read without
/// the internet.
@immutable
class PageElsewhere {
  /// Creates the answer.
  const PageElsewhere({this.readings = const [], this.nearest});

  /// The other readings that have this page on the device.
  final List<MushafEdition> readings;

  /// The nearest page of this reading that is on the device.
  final int? nearest;

  /// Whether there is anywhere to go.
  bool get isEmpty => readings.isEmpty && nearest == null;
}

/// Which page, of which reading, is asked about.
typedef PageInReading = ({MushafEdition edition, int page});

/// Where [PageInReading.page], which [PageInReading.edition] does not have on
/// the device, can be read offline: the readings that have that page, and
/// the nearest page this reading has.
final pageElsewhereProvider = FutureProvider.autoDispose
    .family<PageElsewhere, PageInReading>((ref, asked) async {
      // Every store is taken before the first wait: a provider no one
      // listens to any more may be gone by the time a wait ends.
      final own = ref.read(svgPageStoreProvider(asked.edition));
      final others = {
        for (final edition in MushafEditions.all)
          if (edition != asked.edition)
            edition: ref.read(svgPageStoreProvider(edition)),
      };
      final readings = <MushafEdition>[];
      for (final MapEntry(key: edition, value: store) in others.entries) {
        if (await store.isOnDevice(asked.page)) readings.add(edition);
      }
      final nearest = await own.nearestOnDevice(asked.page);
      return PageElsewhere(readings: readings, nearest: nearest);
    }, retry: (_, _) => null);
