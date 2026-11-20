import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/prayer_provider.dart';
import 'location_problem_notice.dart';

/// Asks to use the location once, for the pages that need a place.
class PrayerNoPlace extends ConsumerWidget {
  /// Creates the view. [denied] says the system refused the last request.
  const PrayerNoPlace({
    super.key,
    required this.denied,
    required this.onLocate,
    required this.onChooseMap,
  });

  /// Whether the last request was refused.
  final bool denied;

  /// Called to ask for the location.
  final VoidCallback onLocate;

  /// Opens a map for choosing a location without device-location permission.
  final VoidCallback onChooseMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final problem = ref.watch(locationProblemProvider);
    final reason = locationProblemMessage(l10n, problem);
    final action = locationProblemAction(l10n, problem);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(
          icon: Icons.location_searching,
          title: l10n.prayerNoPlaceTitle,
          message: denied
              ? (reason ?? l10n.adhkarLocationDenied)
              : l10n.prayerNoPlaceBody,
          actionLabel: l10n.prayerLocate,
          onAction: onLocate,
        ),
        if (denied && action != null)
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(locationSourceProvider).openSettings(problem),
            icon: const Icon(Icons.settings_outlined),
            label: Text(action),
          ),
        TextButton.icon(
          onPressed: onChooseMap,
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.prayerChooseMap),
        ),
      ],
    );
  }
}
