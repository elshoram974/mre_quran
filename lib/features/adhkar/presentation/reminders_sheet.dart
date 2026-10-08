import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_time_picker.dart';
import '../application/adhkar_providers.dart';
import '../application/reminders_provider.dart';
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
String formatReminderTime(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

class _RemindersBody extends ConsumerStatefulWidget {
  const _RemindersBody();

  @override
  ConsumerState<_RemindersBody> createState() => _RemindersBodyState();
}

class _RemindersBodyState extends ConsumerState<_RemindersBody> {
  bool _denied = false;

  Future<void> _toggle(AdhkarCollection collection, bool enabled) async {
    final result = await ref
        .read(remindersProvider.notifier)
        .setEnabled(collection, enabled);
    if (!mounted) return;
    setState(() => _denied = result == ReminderToggleResult.permissionDenied);
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
          if (_denied)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.adhkarPermissionDenied,
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
