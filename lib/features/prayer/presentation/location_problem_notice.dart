import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/prayer_provider.dart';
import '../data/location_source.dart';

/// What to tell the person about [problem], in plain words, or null when
/// there is nothing to say.
String? locationProblemMessage(
  AppLocalizations l10n,
  LocationProblem problem,
) => switch (problem) {
  LocationProblem.none => null,
  LocationProblem.serviceOff => l10n.locationOffMessage,
  LocationProblem.denied => l10n.locationDeniedMessage,
  LocationProblem.blocked => l10n.locationBlockedMessage,
};

/// The button that goes with [problem], or null when pressing the same
/// button again is the answer.
String? locationProblemAction(AppLocalizations l10n, LocationProblem problem) =>
    switch (problem) {
      LocationProblem.serviceOff => l10n.locationOffAction,
      LocationProblem.blocked => l10n.locationBlockedAction,
      _ => null,
    };

/// Says why the location could not be read, and, when the phone's settings
/// are where it is put right, gives a button that opens them. Shows
/// [fallback] when the cause is not known.
class LocationProblemNotice extends ConsumerWidget {
  /// Creates the notice.
  const LocationProblemNotice({super.key, required this.fallback});

  /// What to say when the cause is not known.
  final String fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final problem = ref.watch(locationProblemProvider);
    final action = locationProblemAction(l10n, problem);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNotice(
          locationProblemMessage(l10n, problem) ?? fallback,
          error: true,
        ),
        if (action != null) ...[
          const SizedBox(height: AppTokens.spaceSmall),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(locationSourceProvider).openSettings(problem),
            icon: const Icon(Icons.settings_outlined),
            label: Text(action),
          ),
        ],
      ],
    );
  }
}
