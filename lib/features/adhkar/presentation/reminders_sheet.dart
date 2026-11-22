import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../app/router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_directional_icon.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_time_picker.dart';
import '../application/adhkar_providers.dart';
import '../../fasting/application/fasting_reminders_provider.dart';
import '../../fasting/presentation/fasting_reminders_section.dart';
import '../../prayer/application/prayer_provider.dart';
import '../application/reminders_provider.dart';
import '../application/weekly_reminders_provider.dart';
import '../domain/weekly_reminder.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_checkNotifications()),
    );
  }

  /// Some reminders are on from the start. If any is, and the phone does not
  /// let the app notify, say so here, where the person came for them, rather
  /// than let a switch that is on promise what cannot happen. Asking is the
  /// person's own: they opened this sheet.
  Future<void> _checkNotifications() async {
    final bool anyOn;
    try {
      final weekly = await ref.read(weeklyRemindersProvider.future);
      final daily = await ref.read(remindersProvider.future);
      final fasting = await ref.read(fastingRemindersProvider.future);
      anyOn =
          weekly.values.any((setting) => setting.enabled) ||
          daily.values.any((setting) => setting.enabled) ||
          fasting.fasts.isNotEmpty;
    } on Object {
      // Reminders that cannot be read are not on.
      return;
    }
    if (!mounted || !anyOn) return;
    final allowed = await ref
        .read(reminderSchedulerProvider)
        .requestPermission();
    if (!mounted || allowed) return;
    setState(() => _notice = _Notice.notifications);
  }

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

  Future<void> _toggleWeekly(WeeklyReminder reminder, bool enabled) async {
    final result = await ref
        .read(weeklyRemindersProvider.notifier)
        .setEnabled(reminder, enabled);
    if (!mounted) return;
    setState(
      () => _notice = result == ReminderToggleResult.permissionDenied
          ? _Notice.notifications
          : null,
    );
  }

  Future<void> _pickWeeklyTime(WeeklyReminder reminder, int current) async {
    final picked = await AppTimePicker.show(
      context: context,
      initialMinutes: current,
    );
    if (picked != null) {
      await ref
          .read(weeklyRemindersProvider.notifier)
          .setTime(reminder, picked);
    }
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
    final weeklySettings =
        ref.watch(weeklyRemindersProvider).value ??
        const <String, ReminderSetting>{};
    final weekly =
        ref.watch(weeklyReminderCatalogProvider).value ??
        const <WeeklyReminder>[];
    final locale = Localizations.localeOf(context).toString();
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
          // Red and boxed, first: reminders that are on cannot reach the
          // person without it.
          if (_notice == _Notice.notifications) ...[
            AppNotice(l10n.adhkarPermissionDenied, important: true),
            const SizedBox(height: 8),
          ],
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
          if (weekly.isNotEmpty) ...[
            const Divider(height: 32),
            Text(l10n.weeklyReminders, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final reminder in weekly)
              if (weeklySettings[reminder.id] case final setting?) ...[
                AppSwitchTile(
                  value: setting.enabled,
                  onChanged: (value) => _toggleWeekly(reminder, value),
                  title: reminder.title(language),
                  subtitle: l10n.weeklyReminderWhen(
                    // 1 January 2024 was a Monday.
                    DateFormat.EEEE(locale)
                        .format(DateTime(2024, 1, reminder.weekday)),
                    formatReminderTime(
                      context,
                      setting.minutes,
                      formatDisplayDigits,
                    ),
                  ),
                  icon: Icons.event_repeat_outlined,
                ),
                if (setting.enabled)
                  ListTile(
                    title: Text(l10n.adhkarReminderTime),
                    trailing: Text(
                      formatReminderTime(
                        context,
                        setting.minutes,
                        formatDisplayDigits,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    onTap: () => _pickWeeklyTime(reminder, setting.minutes),
                  ),
              ],
          ],
          const Divider(height: 32),
          FastingRemindersSection(
            formatTime: (minutes) =>
                formatReminderTime(context, minutes, formatDisplayDigits),
            onPermissionDenied: () =>
                setState(() => _notice = _Notice.notifications),
          ),
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
            trailing: const AppForwardChevron(),
            onTap: () {
              Navigator.of(context).pop();
              context.go(AppRoute.prayerTimes.path);
            },
          ),
          if (_notice == _Notice.location)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppNotice(l10n.adhkarLocationDenied, error: true),
            ),
        ],
      ),
    );
  }
}
