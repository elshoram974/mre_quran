import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/widgets/app_directional_icon.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_time_picker.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/application/reminders_provider.dart';
import '../../adhkar/application/weekly_reminders_provider.dart';
import '../../adhkar/domain/adhkar_collection.dart';
import '../../adhkar/domain/reminder_setting.dart';
import '../../adhkar/domain/weekly_reminder.dart';
import '../../fasting/application/fasting_reminders_provider.dart';
import '../../fasting/presentation/fasting_reminders_section.dart';
import '../../prayer/application/prayer_provider.dart';
import '../../prayer/domain/prayer_alerts.dart';
import '../../settings/application/digits_provider.dart';
import '../application/custom_reminders_provider.dart';
import 'my_reminders_section.dart';
import 'reminder_labels.dart';

/// Why a switch stayed off.
enum _Notice { notifications, location }

/// Every reminder in one place: the ones the person made, the adhkar's, the
/// weekly ones, the sunnah fasts', and the one after each prayer.
class RemindersPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
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
  /// person's own: they opened this page.
  Future<void> _checkNotifications() async {
    final bool anyOn;
    try {
      final weekly = await ref.read(weeklyRemindersProvider.future);
      final daily = await ref.read(remindersProvider.future);
      final fasting = await ref.read(fastingRemindersProvider.future);
      final mine = await ref.read(customRemindersProvider.future);
      anyOn =
          weekly.values.any((setting) => setting.enabled) ||
          daily.values.any((setting) => setting.enabled) ||
          fasting.fasts.isNotEmpty ||
          mine.any((reminder) => reminder.enabled);
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

  void _denied() => setState(() => _notice = _Notice.notifications);

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

  Future<void> _pickTime(int current, Future<void> Function(int) save) async {
    final picked = await AppTimePicker.show(
      context: context,
      initialMinutes: current,
    );
    if (picked != null) await save(picked);
  }

  /// Opens the form for [id] (a new reminder when null) and hears how saving
  /// went.
  Future<void> _edit(String? id) async {
    final result = await context.push<ReminderSaveResult>(
      AppRoute.reminderEditPath(id),
    );
    if (!mounted) return;
    if (result == ReminderSaveResult.permissionDenied) _denied();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toString();
    final catalog = ref.watch(adhkarCatalogProvider).value;
    final settings =
        ref.watch(remindersProvider).value ?? const <String, ReminderSetting>{};
    final digits = ref.watch(digitsFormatterProvider);
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    final prayer =
        ref.watch(prayerProvider).value ??
        const PrayerState(settings: PrayerSettings());
    final weeklySettings =
        ref.watch(weeklyRemindersProvider).value ??
        const <String, ReminderSetting>{};
    final weekly =
        ref.watch(weeklyReminderCatalogProvider).value ??
        const <WeeklyReminder>[];
    final collections = [
      for (final collection
          in catalog?.collections ?? const <AdhkarCollection>[])
        if (settings.containsKey(collection.id)) collection,
    ];
    final theme = Theme.of(context);

    Widget timeRow(int minutes, Future<void> Function(int) save) => ListTile(
      title: Text(l10n.adhkarReminderTime),
      trailing: Text(
        formatReminderTime(context, minutes, displayDigits),
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      onTap: () => _pickTime(minutes, save),
    );

    return AppPageScaffold(
      title: l10n.adhkarReminders,
      body: ContentContainer(
        child: ListView(
          padding: pagePadding(context),
          children: [
            // Red and boxed, first: reminders that are on cannot reach the
            // person without it.
            if (_notice == _Notice.notifications) ...[
              AppNotice(l10n.adhkarPermissionDenied, important: true),
              const SizedBox(height: 12),
            ],
            MyRemindersSection(
              onAdd: () => _edit(null),
              onEdit: (reminder) => _edit(reminder.id),
              onPermissionDenied: _denied,
            ),
            if (collections.isNotEmpty) ...[
              const SizedBox(height: 24),
              AppSectionHeader(title: l10n.remindersAdhkarSection),
              AppGroupCard(
                children: [
                  for (final collection in collections) ...[
                    AppSwitchTile(
                      value: settings[collection.id]!.enabled,
                      onChanged: (value) => _toggle(collection, value),
                      title: collection.title(language),
                      subtitle: formatReminderTime(
                        context,
                        settings[collection.id]!.minutes,
                        displayDigits,
                      ),
                      icon: Icons.notifications_outlined,
                    ),
                    if (settings[collection.id]!.enabled)
                      timeRow(
                        settings[collection.id]!.minutes,
                        (picked) => ref
                            .read(remindersProvider.notifier)
                            .setTime(collection, picked),
                      ),
                  ],
                ],
              ),
            ],
            if (weekly.isNotEmpty) ...[
              const SizedBox(height: 24),
              AppSectionHeader(title: l10n.weeklyReminders),
              AppGroupCard(
                children: [
                  for (final reminder in weekly)
                    if (weeklySettings[reminder.id] case final setting?) ...[
                      AppSwitchTile(
                        value: setting.enabled,
                        onChanged: (value) => _toggleWeekly(reminder, value),
                        title: reminder.title(language),
                        subtitle: l10n.weeklyReminderWhen(
                          DateFormat.EEEE(locale)
                              .format(DateTime(2024, 1, reminder.weekday)),
                          formatReminderTime(
                            context,
                            setting.minutes,
                            displayDigits,
                          ),
                        ),
                        icon: Icons.event_repeat_outlined,
                      ),
                      if (setting.enabled)
                        timeRow(
                          setting.minutes,
                          (picked) => ref
                              .read(weeklyRemindersProvider.notifier)
                              .setTime(reminder, picked),
                        ),
                    ],
                ],
              ),
            ],
            const SizedBox(height: 24),
            FastingRemindersSection(
              formatTime: (minutes) =>
                  formatReminderTime(context, minutes, displayDigits),
              onPermissionDenied: _denied,
            ),
            const SizedBox(height: 24),
            AppSectionHeader(title: l10n.adhkarPrayerSection),
            AppGroupCard(
              children: [
                AppSwitchTile(
                  value: prayer.settings.adhkarReminder,
                  onChanged: _togglePrayer,
                  title: l10n.adhkarPrayerSwitch,
                  subtitle: l10n.adhkarPrayerSwitchHint,
                  icon: Icons.mosque_outlined,
                ),
                if (prayer.settings.adhkarReminder)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      8,
                      16,
                      12,
                    ),
                    child: AppSelectField<int>(
                      label: l10n.adhkarPrayerAfter,
                      value: prayer.settings.afterMinutes,
                      options: [
                        for (final minutes in PrayerSettings.choices)
                          AppSelectOption(
                            value: minutes,
                            label: l10n.adhkarPrayerMinutes(digits(minutes)),
                          ),
                      ],
                      onChanged: (value) => ref
                          .read(prayerProvider.notifier)
                          .setAfterMinutes(value),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: Text(l10n.prayerTimesTitle),
                  trailing: const AppForwardChevron(),
                  onTap: () => context.go(AppRoute.prayerTimes.path),
                ),
              ],
            ),
            if (_notice == _Notice.location)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AppNotice(l10n.adhkarLocationDenied, error: true),
              ),
          ],
        ),
      ),
    );
  }
}
