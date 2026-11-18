import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../settings/application/settings_provider.dart';
import '../application/home_widgets_providers.dart';
import '../domain/prayer_schedule_options.dart';

/// Controls shared by every prayer schedule widget on the home screen.
class PrayerScheduleOptionsSection extends ConsumerWidget {
  /// Creates the schedule settings.
  const PrayerScheduleOptionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(prayerScheduleOptionsProvider).value;
    if (options == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value;

    Future<void> save(PrayerScheduleOptions value) async {
      final saved = await ref
          .read(prayerScheduleOptionsProvider.notifier)
          .save(value);
      if (!context.mounted || saved) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n.widgetScheduleSaveFailed)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.widgetScheduleSettings,
          subtitle: l10n.widgetScheduleSettingsHint,
        ),
        AppSelectField<bool>(
          label: l10n.widgetScheduleLayout,
          value: options.upcomingOnly,
          options: [
            AppSelectOption(value: false, label: l10n.widgetScheduleAll),
            AppSelectOption(value: true, label: l10n.widgetScheduleUpcoming),
          ],
          onChanged: (value) => save(options.copyWith(upcomingOnly: value)),
        ),
        const SizedBox(height: AppTokens.spaceSmall),
        AppGroupCard(
          children: [
            AppSwitchTile(
              title: l10n.widgetScheduleSunrise,
              subtitle: l10n.widgetScheduleSunriseHint,
              value: options.showSunrise,
              onChanged: options.upcomingOnly
                  ? null
                  : (value) => save(options.copyWith(showSunrise: value)),
            ),
            AppSwitchTile(
              title: l10n.widgetScheduleDate,
              value: options.showDate,
              onChanged: (value) => save(options.copyWith(showDate: value)),
            ),
            AppSwitchTile(
              title: l10n.widgetScheduleCountdown,
              value: options.showCountdown,
              onChanged: (value) =>
                  save(options.copyWith(showCountdown: value)),
            ),
            if (options.showCountdown && settings != null)
              AppSwitchTile(
                title: l10n.settingsWidgetSeconds,
                subtitle: l10n.settingsWidgetSecondsHint,
                value: settings.widgetSeconds,
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .save(settings.copyWith(widgetSeconds: value)),
              ),
            AppSwitchTile(
              title: l10n.widgetScheduleLargeText,
              subtitle: l10n.widgetScheduleLargeTextHint,
              value: options.largeText,
              onChanged: (value) => save(options.copyWith(largeText: value)),
            ),
          ],
        ),
      ],
    );
  }
}
