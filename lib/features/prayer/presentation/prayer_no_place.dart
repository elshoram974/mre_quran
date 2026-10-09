import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';

/// Asks to use the location once, for the pages that need a place.
class PrayerNoPlace extends StatelessWidget {
  /// Creates the view. [denied] says the system refused the last request.
  const PrayerNoPlace({
    super.key,
    required this.denied,
    required this.onLocate,
  });

  /// Whether the last request was refused.
  final bool denied;

  /// Called to ask for the location.
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.location_searching,
      title: l10n.prayerNoPlaceTitle,
      message: denied ? l10n.adhkarLocationDenied : l10n.prayerNoPlaceBody,
      actionLabel: l10n.prayerLocate,
      onAction: onLocate,
    );
  }
}
