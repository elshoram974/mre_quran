import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../core/widgets/app_card.dart';
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
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final next = ref.watch(nextPrayerProvider);
    final now = ref.watch(tickingNowProvider);
    final subtitle = next == null
        ? l10n.prayerNoPlaceTitle
        : '${prayerName(l10n, next.prayer)} · '
              '${formatPrayerTime(context, next.at)} · '
              '${l10n.prayerIn(formatUntil(l10n, next.at.difference(now), digits))}';
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            Icons.access_time_rounded,
            color: theme.colorScheme.primary,
          ),
          title: Text(l10n.prayerTimesTitle),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoute.prayerTimes.path),
        ),
      ),
    );
  }
}
