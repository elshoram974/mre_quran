import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../settings/application/digits_provider.dart';
import '../application/prayer_provider.dart';
import 'prayer_labels.dart';

/// A card that shows the next prayer and opens the prayer times.
class PrayerTimesCard extends ConsumerWidget {
  /// Creates the card.
  const PrayerTimesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final formatDisplayDigits = ref.watch(displayDigitsFormatterProvider);
    final next = ref.watch(nextPrayerProvider);
    final now = ref.watch(tickingNowProvider);
    final subtitle = next == null
        ? l10n.prayerNoPlaceTitle
        : '${prayerName(l10n, next.prayer)} · '
              '${formatPrayerTime(context, next.at, formatDisplayDigits)} · '
              '${l10n.prayerIn(formatUntil(l10n, next.at.difference(now), digits))}';
    return AppTileCard(
      icon: Icons.access_time_rounded,
      title: l10n.prayerTimesTitle,
      subtitle: subtitle,
      onTap: () => context.push(AppRoute.prayerTimes.path),
    );
  }
}
