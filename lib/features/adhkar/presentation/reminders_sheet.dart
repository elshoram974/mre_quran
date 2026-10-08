import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_time_picker.dart';
import '../application/adhkar_providers.dart';
import '../../prayer/application/prayer_provider.dart';
import '../application/reminders_provider.dart';
import '../../prayer/domain/prayer_alerts.dart';
import '../../settings/application/digits_provider.dart';
import '../domain/adhkar_collection.dart';
import '../domain/reminder_setting.dart';

/// Shows the reminder switch and time of every collection that offers one.
abstract final class RemindersSheet {
  /// Opens the sheet.
  static Future<void> show(BuildContext context) => AppSheet.show<void>(
    context: context,
    builder: (context) => const _RemindersBody(),
  );
}

/// The time of day as the device formats it.
String formatReminderTime(
  BuildContext context,
  int minutes,
  String Function(String) formatDigits,
) => formatDigits(
  MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60)),
);

/// Why a switch stayed off.
enum _Notice { notifications, location }

class _RemindersBody extends ConsumerStatefulWidget {
  const _RemindersBody();

  @override
  ConsumerState<_RemindersBody> createState() => _RemindersBodyState();
}

class _RemindersBodyState extends ConsumerState<_RemindersBody> {
  _Notice? _notice;

  Future<void> _toggle(AdhkarCollection collection, bool enabled) async {
    final result = await ref
        .read(remindersProvider.notifier)
        .setEnabled(collection, enabled);
    if (!mounted) return;
    setState(
      () => _notice = result == ReminderToggleResult.permissionDenied
          ? _Notice.notifications
          : null,
    );
  }

  Future<void> _togglePrayer(bool enabled) async {
    final result = await ref
        .read(prayerProvider.notifier)
        .setAdhkarReminder(enabled);
    if (!mounted) return;
    setState(
      () => _notice = switch (result) {
        PrayerResult.notificationsDenied => _Notice.notifications,
        PrayerResult.locationDenied => _Notice.location,
        PrayerResult.ok => null,
      },
    );
  }

  Future<void> _pickTime(AdhkarCollection collection, int current) async {
    final picked = await AppTimePicker.show(
      context: context,
      initialMinutes: current,
    );
    if (picked != null) {
      await ref.read(remindersProvider.notifier).setTime(collection, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(adhkarCatalogProvider).value;
    final settings =
        ref.watch(remindersProvider).value ?? const <String, ReminderSetting>{};
    final digits = ref.watch(digitsFormatterProvider);
    final formatDisplayDigits = ref.watch(displayDigitsFormatterProvider);
    final prayer =
        ref.watch(prayerProvider).value ??
        const PrayerState(settings: PrayerSettings());
    final collections = [
      for (final collection
          in catalog?.collections ?? const <AdhkarCollection>[])
        if (settings.containsKey(collection.id)) collection,
    ];
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutterCompact,
        4,
        AppTokens.gutterCompact,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adhkarReminders, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final collection in collections) ...[
            AppSwitchTile(
              value: settings[collection.id]!.enabled,
              onChanged: (value) => _toggle(collection, value),
              title: collection.title(language),
              subtitle: formatReminderTime(
                context,
                settings[collection.id]!.minutes,
                formatDisplayDigits,
              ),
              icon: Icons.notifications_outlined,
            ),
            if (settings[collection.id]!.enabled)
              ListTile(
                title: Text(l10n.adhkarReminderTime),
                trailing: Text(
                  formatReminderTime(
                    context,
                    settings[collection.id]!.minutes,
                    formatDisplayDigits,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                onTap: () =>
                    _pickTime(collection, settings[collection.id]!.minutes),
              ),
          ],
          const Divider(height: 32),
          Text(l10n.adhkarPrayerSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          AppSwitchTile(
            value: prayer.settings.adhkarReminder,
            onChanged: _togglePrayer,
            title: l10n.adhkarPrayerSwitch,
            subtitle: l10n.adhkarPrayerSwitchHint,
            icon: Icons.mosque_outlined,
          ),
          if (prayer.settings.adhkarReminder) ...[
            const SizedBox(height: 8),
            AppSelectField<int>(
              label: l10n.adhkarPrayerAfter,
              value: prayer.settings.afterMinutes,
              options: [
                for (final minutes in PrayerSettings.choices)
                  AppSelectOption(
                    value: minutes,
                    label: l10n.adhkarPrayerMinutes(digits(minutes)),
                  ),
              ],
              onChanged: (value) =>
                  ref.read(prayerProvider.notifier).setAfterMinutes(value),
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_rounded),
            title: Text(l10n.prayerTimesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoute.prayerTimes.path);
            },
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppNotice(
                _notice == _Notice.location
                    ? l10n.adhkarLocationDenied
                    : l10n.adhkarPermissionDenied,
                error: true,
              ),
            ),
        ],
      ),
    );
  }
}
