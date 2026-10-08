import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_time_picker.dart';
import '../application/adhkar_providers.dart';
import '../application/prayer_reminders_provider.dart';
import '../application/reminders_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../domain/adhkar_collection.dart';
import '../domain/prayer_reminders.dart';
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
String formatReminderTime(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

/// Why a switch stayed off.
enum _Notice { notifications, location }

/// The name of a calculation method.
String prayerMethodLabel(AppLocalizations l10n, PrayerMethod method) =>
    switch (method) {
      PrayerMethod.egyptian => l10n.methodEgyptian,
      PrayerMethod.muslimWorldLeague => l10n.methodMuslimWorldLeague,
      PrayerMethod.ummAlQura => l10n.methodUmmAlQura,
      PrayerMethod.karachi => l10n.methodKarachi,
      PrayerMethod.northAmerica => l10n.methodNorthAmerica,
      PrayerMethod.dubai => l10n.methodDubai,
      PrayerMethod.kuwait => l10n.methodKuwait,
      PrayerMethod.qatar => l10n.methodQatar,
      PrayerMethod.turkey => l10n.methodTurkey,
      PrayerMethod.singapore => l10n.methodSingapore,
    };

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
        .read(prayerRemindersProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    setState(
      () => _notice = switch (result) {
        PrayerToggleResult.notificationsDenied => _Notice.notifications,
        PrayerToggleResult.locationDenied => _Notice.location,
        _ => null,
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
    final prayer =
        ref.watch(prayerRemindersProvider).value ??
        const PrayerRemindersState(settings: PrayerReminderSettings());
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
              ),
              icon: Icons.notifications_outlined,
            ),
            if (settings[collection.id]!.enabled)
              ListTile(
                title: Text(l10n.adhkarReminderTime),
                trailing: Text(
                  formatReminderTime(context, settings[collection.id]!.minutes),
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
            value: prayer.settings.enabled,
            onChanged: _togglePrayer,
            title: l10n.adhkarPrayerSwitch,
            subtitle: l10n.adhkarPrayerSwitchHint,
            icon: Icons.mosque_outlined,
          ),
          if (prayer.settings.enabled) ...[
            const SizedBox(height: 8),
            AppSelectField<PrayerMethod>(
              label: l10n.adhkarPrayerMethod,
              value: prayer.settings.method,
              options: [
                for (final method in PrayerMethod.values)
                  AppSelectOption(
                    value: method,
                    label: prayerMethodLabel(l10n, method),
                  ),
              ],
              onChanged: (value) =>
                  ref.read(prayerRemindersProvider.notifier).setMethod(value),
            ),
            const SizedBox(height: 12),
            AppSelectField<int>(
              label: l10n.adhkarPrayerAfter,
              value: prayer.settings.afterMinutes,
              options: [
                for (final minutes in PrayerReminderSettings.choices)
                  AppSelectOption(
                    value: minutes,
                    label: l10n.adhkarPrayerMinutes(digits(minutes)),
                  ),
              ],
              onChanged: (value) => ref
                  .read(prayerRemindersProvider.notifier)
                  .setAfterMinutes(value),
            ),
          ],
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _notice == _Notice.location
                    ? l10n.adhkarLocationDenied
                    : l10n.adhkarPermissionDenied,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
