import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_directional_icon.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../adhkar/application/reminders_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../application/custom_reminders_provider.dart';
import '../domain/custom_reminder.dart';
import 'reminder_labels.dart';

/// The reminders the person made: each with when it comes and a switch, an
/// empty state that says what to do, and the way to add one.
class MyRemindersSection extends ConsumerWidget {
  /// Creates the section. [onAdd] opens the form for a new reminder; [onEdit]
  /// opens it for [reminder]; [onPermissionDenied] is told when a switch
  /// stayed off because the phone does not let the app notify.
  const MyRemindersSection({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onPermissionDenied,
  });

  /// Opens the form for a new reminder.
  final VoidCallback onAdd;

  /// Opens the form for an existing reminder.
  final ValueChanged<CustomReminder> onEdit;

  /// Called when turning a reminder on was refused.
  final VoidCallback onPermissionDenied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reminders = ref.watch(customRemindersProvider).value;
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    final digits = ref.watch(digitsFormatterProvider);
    final list = reminders ?? const <CustomReminder>[];
    final full = list.length >= CustomReminder.maxReminders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.myRemindersTitle,
          subtitle: l10n.myRemindersHint,
        ),
        if (reminders != null && list.isEmpty)
          AppCard(
            child: Column(
              children: [
                Icon(
                  Icons.edit_notifications_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myRemindersEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else if (list.isNotEmpty)
          AppGroupCard(
            children: [
              for (final reminder in list)
                _ReminderRow(
                  reminder: reminder,
                  summary: reminderSummaryLine(
                    context,
                    reminder,
                    displayDigits,
                  ),
                  onTap: () => onEdit(reminder),
                  onChanged: (on) async {
                    final result = await ref
                        .read(customRemindersProvider.notifier)
                        .setEnabled(reminder.id, on);
                    if (result == ReminderToggleResult.permissionDenied) {
                      onPermissionDenied();
                    }
                  },
                ),
            ],
          ),
        const SizedBox(height: 8),
        if (full)
          AppNotice(
            l10n.reminderLimit(digits(CustomReminder.maxReminders)),
            icon: Icons.info_outline,
          )
        else
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n.reminderAdd),
          ),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.summary,
    required this.onTap,
    required this.onChanged,
  });

  final CustomReminder reminder;
  final String summary;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // The row opens the form; only the switch turns it on and off.
    return ListTile(
      onTap: onTap,
      minVerticalPadding: 12,
      title: Text(reminder.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        reminder.enabled ? summary : '${l10n.reminderOff} · $summary',
      ),
      textColor: reminder.enabled ? null : theme.colorScheme.onSurfaceVariant,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch.adaptive(value: reminder.enabled, onChanged: onChanged),
          const AppForwardChevron(),
        ],
      ),
    );
  }
}
