import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_time_picker.dart';
import '../../adhkar/application/reminders_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../application/fasting_reminders_provider.dart';
import '../domain/sunnah_fasts.dart';

/// The sunnah fasts' reminders, for the reminders sheet: a switch for each
/// fast, saying when it comes next, and the time of the evening reminder.
class FastingRemindersSection extends ConsumerWidget {
  /// Creates the section. [formatTime] writes a time of day as the sheet
  /// does; [onPermissionDenied] is told when a switch stayed off because
  /// the phone does not let the app notify.
  const FastingRemindersSection({
    super.key,
    required this.formatTime,
    required this.onPermissionDenied,
  });

  /// Writes minutes after midnight as a time of day.
  final String Function(int minutes) formatTime;

  /// Called when turning a reminder on was refused.
  final VoidCallback onPermissionDenied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(fastingRemindersProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final next = ref.watch(fastingNextDaysProvider);
    final digits = ref.watch(digitsFormatterProvider);
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final notifier = ref.read(fastingRemindersProvider.notifier);

    String? when(SunnahFast fast) => switch (next[fast]) {
      final day? => l10n.fastingNext(
        displayDigits(DateFormat.MMMEd(locale).format(day)),
      ),
      null => null,
    };

    Future<void> toggle(SunnahFast fast, bool on) async {
      final result = await notifier.setFast(fast, on);
      if (result == ReminderToggleResult.permissionDenied) {
        onPermissionDenied();
      }
    }

    Widget tile(SunnahFast fast, String title, IconData icon, {String? hint}) =>
        AppSwitchTile(
          value: settings.fasts.contains(fast),
          onChanged: (on) => toggle(fast, on),
          title: title,
          subtitle: [?hint, ?when(fast)].join('\n'),
          icon: icon,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.fastingSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        AppNotice(l10n.fastingSectionHint),
        const SizedBox(height: 4),
        tile(
          SunnahFast.mondayThursday,
          l10n.fastingMondayThursday,
          Icons.calendar_view_week_outlined,
        ),
        tile(
          SunnahFast.whiteDays,
          l10n.fastingWhiteDays,
          Icons.brightness_3_outlined,
          hint: l10n.fastingWhiteDaysHint(digits(13), digits(14), digits(15)),
        ),
        tile(
          SunnahFast.arafah,
          l10n.fastingArafahSwitch,
          Icons.terrain_outlined,
        ),
        tile(
          SunnahFast.ashura,
          l10n.fastingAshuraSwitch,
          Icons.event_note_outlined,
        ),
        tile(
          SunnahFast.shawwal,
          l10n.fastingShawwalSwitch,
          Icons.date_range_outlined,
        ),
        if (settings.fasts.isNotEmpty)
          ListTile(
            title: Text(l10n.adhkarReminderTime),
            trailing: Text(
              formatTime(settings.minutes),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            onTap: () async {
              final picked = await AppTimePicker.show(
                context: context,
                initialMinutes: settings.minutes,
              );
              if (picked != null) await notifier.setTime(picked);
            },
          ),
      ],
    );
  }
}
