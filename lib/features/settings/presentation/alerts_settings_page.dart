import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/haptics/haptics_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../adhkar/presentation/reminders_sheet.dart';
import '../application/settings_provider.dart';
import 'settings_body.dart';

/// Where the alerts and reminders are set: the prayer times and their alerts,
/// the adhan, the reminders of the adhkar and of Friday, and vibration.
class AlertsSettingsPage extends ConsumerWidget {
  /// Creates the page.
  const AlertsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(settingsProvider.notifier);
    final hapticsSupported = ref.watch(hapticsSupportedProvider).value ?? true;
    return AppPageScaffold(
      title: l10n.settingsAlerts,
      body: SettingsBody(
        builder: (context, settings) => ListView(
          padding: pagePadding(context),
          children: [
            AppTileCard(
              icon: Icons.access_time_rounded,
              title: l10n.prayerTimesTitle,
              subtitle: l10n.prayerAlertsHint,
              // The prayer times are a tab of their own.
              onTap: () => context.go(AppRoute.prayerTimes.path),
            ),
            const SizedBox(height: settingsGap),
            AppTileCard(
              icon: Icons.volume_up_outlined,
              title: l10n.adhanTitle,
              subtitle: l10n.adhanTileSubtitle,
              onTap: () => context.push(AppRoute.adhan.path),
            ),
            const SizedBox(height: settingsGap),
            AppTileCard(
              icon: Icons.notifications_none_outlined,
              title: l10n.adhkarReminders,
              subtitle: l10n.settingsRemindersHint,
              onTap: () => RemindersSheet.show(context),
            ),
            const SizedBox(height: settingsGap),
            AppGroupCard(
              children: [
                AppSwitchTile(
                  value: hapticsSupported && settings.hapticsEnabled,
                  // A device with no vibration motor gets a switch that says
                  // so.
                  onChanged: hapticsSupported
                      ? (value) {
                          notifier.save(
                            settings.copyWith(hapticsEnabled: value),
                          );
                          // Let the person feel what they just turned on.
                          Haptics.enabled = value;
                          if (value) Haptics.step();
                        }
                      : null,
                  icon: Icons.vibration,
                  title: l10n.settingsHaptics,
                  subtitle: hapticsSupported
                      ? l10n.settingsHapticsHint
                      : l10n.settingsHapticsUnsupported,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
